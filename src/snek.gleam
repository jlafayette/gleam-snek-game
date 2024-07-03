import color
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/set.{type Set}
import lustre
import lustre/attribute.{type Attribute as Attr}
import lustre/effect
import lustre/element.{text}
import lustre/element/html
import lustre/element/svg

import level as level_gen
import player.{type Snek, Snek}
import position.{type Pos, Down, Left, Pos, Right, Up}

// --- Main 

pub fn main() {
  io.println("Hello from snek!")
  let app = lustre.application(init, update, view)
  let assert Ok(send_to_runtime) = lustre.start(app, "#app", Nil)
  document_add_event_listener("keydown", fn(event) {
    event_code(event)
    |> io.debug
    |> Keydown
    |> lustre.dispatch
    |> send_to_runtime
  })
  Nil
}

// --- Keyboard Input

pub type Event

@external(javascript, "./snek_ffi.mjs", "eventCode")
fn event_code(event: Event) -> String

@external(javascript, "./snek_ffi.mjs", "documentAddEventListener")
fn document_add_event_listener(type_: String, listener: fn(Event) -> Nil) -> Nil

// --- Tick for game update

fn every(interval: Int, tick: msg) -> effect.Effect(msg) {
  effect.from(fn(dispatch) {
    window_set_interval(interval, fn() { dispatch(tick) })
  })
}

@external(javascript, "./snek_ffi.mjs", "windowSetInterval")
fn window_set_interval(interval: Int, cb: fn() -> Nil) -> Nil

@external(javascript, "./snek_ffi.mjs", "windowClearInterval")
fn window_clear_interval() -> Nil

// --- Model

type Board {
  Board(
    level: level_gen.Level,
    food: Set(Pos),
    snek: Snek,
    w: Int,
    h: Int,
    size: Int,
  )
}

type GameState {
  Menu
  Play
  Pause
  Died
  GameOver
}

const max_lives = 3

type Run {
  Run(score: Int, lives: Int)
}

type Model {
  Model(
    board: Board,
    run: Run,
    tick_speed: Int,
    state: GameState,
    keydown: String,
  )
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(
      board: init_board(1),
      run: Run(score: 0, lives: max_lives),
      tick_speed: 250,
      state: Menu,
      keydown: "N/A",
    ),
    effect.none(),
  )
}

fn init_board(level_number: Int) -> Board {
  let width = 20
  let height = 15
  let tile_size = 40
  let level = level_gen.get(level_number, width, height)
  Board(
    level,
    init_food([level.snek_pos, ..level.walls], width, height),
    player.init(level.snek_pos, level.snek_dir),
    width,
    height,
    tile_size,
  )
}

fn init_food(exclude: List(Pos), w: Int, h: Int) -> Set(Pos) {
  let f = Pos(int.random(w), int.random(h))
  case list.contains(exclude, f) {
    True -> init_food(exclude, w, h)
    False -> set.from_list([f])
  }
}

// --- Update

type Msg {
  Keydown(String)
  Tick
  TickStart(Int)
  TickStop
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case model.state {
    Menu -> {
      update_menu(model, msg)
    }
    Play -> {
      update_play(model, msg)
    }
    Pause -> {
      update_pause(model, msg)
    }
    Died -> {
      update_died(model, msg)
    }
    GameOver -> {
      update_game_over(model, msg)
    }
  }
}

fn update_menu(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Keydown(str) if str == "Space" -> #(
      Model(..model, state: Play, keydown: str),
      every(model.tick_speed, Tick),
    )
    Keydown(str) -> #(Model(..model, keydown: str), effect.none())
    _ -> #(model, effect.none())
  }
}

fn update_play(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Keydown(str) -> {
      let level_num = model.board.level.number
      let new_level = case str {
        "Comma" -> level_gen.clamp(level_num - 1)
        "Period" -> level_gen.clamp(level_num + 1)
        _ -> level_num
      }
      let #(new_state, new_snek) = case str {
        "KeyW" | "ArrowUp" -> #(Play, player.keypress(model.board.snek, Up))
        "KeyA" | "ArrowLeft" -> #(Play, player.keypress(model.board.snek, Left))
        "KeyS" | "ArrowDown" -> #(Play, player.keypress(model.board.snek, Down))
        "KeyD" | "ArrowRight" -> #(
          Play,
          player.keypress(model.board.snek, Right),
        )
        "Escape" | "Space" -> {
          let _ = window_clear_interval()
          #(Pause, model.board.snek)
        }
        _ -> #(Play, model.board.snek)
      }
      case new_level == level_num {
        False -> {
          #(
            Model(..model, board: init_board(new_level), keydown: str),
            effect.none(),
          )
        }
        True -> #(
          Model(
            ..model,
            board: Board(..model.board, snek: new_snek),
            keydown: str,
            state: new_state,
          ),
          effect.none(),
        )
      }
    }
    Tick -> {
      io.debug("tick")
      #(move(model), effect.none())
    }
    TickStart(ms) -> {
      io.debug("tick-start")
      #(model, every(ms, Tick))
    }
    TickStop -> {
      io.debug("tick-stop")
      let _ = window_clear_interval()
      #(model, effect.none())
    }
  }
}

fn update_pause(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Keydown(str) -> {
      case str {
        "Escape" | "Space" -> {
          #(
            Model(..model, keydown: str, state: Play),
            every(model.tick_speed, Tick),
          )
        }
        _ -> #(Model(..model, keydown: str), effect.none())
      }
    }
    _ -> #(model, effect.none())
  }
}

fn update_died(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Keydown(str) -> {
      case str {
        "Space" -> {
          #(
            Model(
              ..model,
              board: init_board(model.board.level.number),
              keydown: str,
              state: Play,
            ),
            every(model.tick_speed, Tick),
          )
        }
        _ -> #(Model(..model, keydown: str), effect.none())
      }
    }
    _ -> #(model, effect.none())
  }
}

fn update_game_over(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Keydown(str) -> {
      case str {
        "Space" -> {
          #(
            Model(
              ..model,
              run: Run(score: 0, lives: max_lives),
              board: init_board(1),
              keydown: str,
              state: Play,
            ),
            every(model.tick_speed, Tick),
          )
        }
        _ -> #(Model(..model, keydown: str), effect.none())
      }
    }
    _ -> #(model, effect.none())
  }
}

fn move(model: Model) -> Model {
  let board = model.board
  let exit = case board.level.exit_revealed {
    True -> Some(board.level.exit)
    False -> None
  }
  let result =
    player.move(
      model.board.snek,
      board.food,
      board.level.walls,
      exit,
      board.w,
      board.h,
    )
  let new_food = update_food(board)
  let score_increase = case result.died, result.ate {
    False, True -> 1
    _, _ -> 0
  }
  let new_board =
    Board(
      ..board,
      snek: result.snek,
      food: new_food,
      level: level_gen.score(board.level, score_increase),
    )
  case result.died {
    True -> {
      let lives = model.run.lives - 1
      case lives == 0 {
        True ->
          Model(
            ..model,
            run: Run(..model.run, lives: lives),
            board: new_board,
            state: GameOver,
          )
        False ->
          Model(
            ..model,
            run: Run(..model.run, lives: lives),
            board: new_board,
            state: Died,
          )
      }
    }
    False -> {
      case result.exit {
        True -> {
          // score points
          // move to next level
          let score = model.run.score + model.board.level.score
          let new_level = model.board.level.number + 1
          Model(
            ..model,
            run: Run(..model.run, score: score),
            board: init_board(new_level),
          )
        }
        False -> Model(..model, board: new_board, state: Play)
      }
    }
  }
}

fn update_food(board: Board) -> Set(Pos) {
  let head = player.head(board.snek)
  let food = set.delete(board.food, head)
  add_random_food(head, board, food)
}

fn add_random_food(head: Pos, board: Board, food: Set(Pos)) -> Set(Pos) {
  let w = board.w
  let h = board.h
  let snek = board.snek
  let walls = board.level.walls
  case int.random(5) {
    0 -> {
      let p = random_pos(w, h)
      case
        head == p
        || player.body_contains(snek, p)
        || list.contains(walls, p)
      {
        True -> food
        False -> set.insert(food, p)
      }
    }
    _ -> food
  }
}

fn random_pos(w: Int, h: Int) -> Pos {
  Pos(int.random(w), int.random(h))
}

// --- View
const class = attribute.class

fn menu_font_class() {
  class("share-tech-mono-regular")
}

fn view(model: Model) {
  html.div([class("fullscreen")], case model.state {
    Menu -> {
      // menu is disabled for faster testing so we can jump straight in

      // [
      //   html.div([class("mask")], [
      //     html.h1([class("game-header")], [text("Snek Game")]),
      //     html.p([class("sub-header"), menu_font_class()], [
      //       text("Press 'SPACE' to start"),
      //     ]),
      //     html.h3([class("controls-header"), menu_font_class()], [
      //       text("Controls"),
      //     ]),
      //     html.p([class("controls-text"), menu_font_class()], [
      //       text("Use WASD or arrow keys to move"),
      //     ]),
      //   ]),
      // ]
      [grid(model.board, model.run)]
    }
    Play -> [grid(model.board, model.run)]
    Pause -> {
      [
        grid(model.board, model.run),
        html.div([class("pause-mask")], [
          html.div([class("pause-box")], [
            html.h3([class("pause-header"), menu_font_class()], [text("PAUSED")]),
            html.p([class("pause-text"), menu_font_class()], [
              text("Press 'SPACE' or 'ESC' to continue"),
            ]),
          ]),
        ]),
      ]
    }
    Died -> {
      [
        grid(model.board, model.run),
        html.div([class("pause-mask")], [
          html.div([class("pause-box")], [
            html.h3([class("pause-header"), menu_font_class()], [
              text("Remaining Lives: " <> int.to_string(model.run.lives)),
            ]),
            html.p([class("pause-text"), menu_font_class()], [
              text("Press 'SPACE' to restart level"),
            ]),
          ]),
        ]),
      ]
    }
    GameOver -> {
      [
        grid(model.board, model.run),
        html.div([class("pause-mask")], [
          html.div([class("pause-box")], [
            html.h3([class("pause-header"), menu_font_class()], [
              text("GAME OVER"),
            ]),
            html.p([class("pause-text"), menu_font_class()], [
              text("Press 'SPACE' to play again"),
            ]),
          ]),
        ]),
      ]
    }
  })
}

const attr_str = attribute.attribute

fn attr(name: String, value: Int) -> Attr(a) {
  attr_str(name, int.to_string(value))
}

fn line(x1, y1, x2, y2, width) {
  svg.line([
    attr("x1", x1),
    attr("y1", y1),
    attr("x2", x2),
    attr("y2", y2),
    attr("stroke-width", width),
  ])
}

fn int_fraction(n: Int, mult: Float) -> Int {
  int.to_float(n) *. mult |> float.round
}

fn bbox_to_attrs(bbox: position.Bbox, offset: Pos) -> List(Attr(a)) {
  [
    attr("x", bbox.x + offset.x),
    attr("y", bbox.y + offset.y),
    attr("width", bbox.w),
    attr("height", bbox.h),
  ]
}

fn bbox_lines(
  bbox: position.Bbox,
  offset: Pos,
  dir: position.Move,
) -> List(Attr(a)) {
  case dir {
    Left -> [
      attr("x1", bbox.x + offset.x),
      attr("y1", bbox.y + offset.y),
      attr("x2", bbox.x + offset.x),
      attr("y2", bbox.y + offset.y + bbox.h),
    ]
    Right -> [
      attr("x1", bbox.x + offset.x + bbox.w),
      attr("y1", bbox.y + offset.y),
      attr("x2", bbox.x + offset.x + bbox.w),
      attr("y2", bbox.y + offset.y + bbox.h),
    ]
    Up -> [
      attr("x1", bbox.x + offset.x),
      attr("y1", bbox.y + offset.y),
      attr("x2", bbox.x + offset.x + bbox.w),
      attr("y2", bbox.y + offset.y),
    ]
    Down -> [
      attr("x1", bbox.x + offset.x),
      attr("y1", bbox.y + offset.y + bbox.h),
      attr("x2", bbox.x + offset.x + bbox.w),
      attr("y2", bbox.y + offset.y + bbox.h),
    ]
  }
}

fn grid(board: Board, run: Run) {
  let size = board.size
  let to_bbox = fn(p: Pos) -> position.Bbox {
    position.to_bbox(p, board.w, board.h, size)
  }

  let offset = Pos(size / 2, size + size / 2)
  let board_w = board.w * size
  let board_h = board.h * size
  let w = board_w + { offset.x * 2 }
  let h = board_h + { offset.y + size / 2 }

  let half_size = size / 2
  let snek_width = int_fraction(size, 0.5)
  let food_radius = int_fraction(half_size, 0.5)
  let grid_line_width = 1
  svg.svg(
    [
      attr("width", w),
      attr("height", h),
      attr_str("xmlns", "http://www.w3.org/2000/svg"),
      attr_str("version", "1.1"),
    ],
    [
      svg.defs([], [
        svg.pattern(
          [
            attr_str("id", "pattern"),
            attr("width", 8),
            attr("height", 9),
            attr_str("patternUnits", "userSpaceOnUse"),
            attr_str("patternTransform", "rotate(45)"),
          ],
          [
            svg.line([
              attr_str("stroke", color.game_outline()),
              attr_str("stroke-width", "5px"),
              attr_str("y2", "4"),
            ]),
          ],
        ),
      ]),
      svg.rect([
        attr_str("fill", "url(#pattern)"),
        attr("x", 0),
        attr("y", 0),
        attr("width", w),
        attr("height", h),
        attr_str("stroke", "#a6a6a6"),
      ]),
      svg.rect([
        attr("x", offset.x),
        attr("y", offset.y),
        attr("width", board_w),
        attr("height", board_h),
        attr("stroke-width", 0),
        attr_str("fill", color.grid_background()),
      ]),
      // vertical grid lines
      svg.g(
        [attr_str("stroke", color.grid_lines())],
        list.range(0, { w / size } - 1)
          |> list.map(fn(a) {
            let x = a * size + offset.x
            let y1 = offset.y
            let y2 = offset.y + board_h
            line(x, y1, x, y2, grid_line_width)
          }),
      ),
      // horizontal grid lines
      svg.g(
        [attr_str("stroke", color.grid_lines())],
        list.range(0, { h / size } - 1)
          |> list.map(fn(a) {
            let x1 = offset.x
            let y = a * size + offset.y
            let x2 = offset.x + board_w
            line(x1, y, x2, y, grid_line_width)
          }),
      ),
      // food
      svg.g(
        [attr_str("fill", color.food()), attr("stroke-width", 0)],
        board.food
          |> set.to_list
          |> list.map(fn(pos) {
            svg.circle([
              attr("cx", { pos.x * size } + half_size + offset.x),
              attr("cy", { pos.y * size } + half_size + offset.y),
              attr("r", food_radius),
            ])
          }),
      ),
      // snek
      svg.g(
        [
          attr_str("stroke", color.snek()),
          attr("stroke-width", snek_width),
          attr_str("fill-opacity", "0"),
        ],
        [
          svg.polyline([
            attr_str("stroke-linecap", "square"),
            // attr_str("stroke-linejoin", "round"),
            // attr_str("points", "20,20 20,60 60,60"),
            attr_str("points", snek_to_points(board.snek.body, size, offset)),
          ]),
        ],
      ),
      // walls
      {
        let wall_size = int_fraction(size, 0.8)
        let center_offset = int_fraction(size, 0.1)
        svg.g([attr_str("fill", color.grid_lines())], {
          {
            board.level.walls
            |> list.map(fn(pos) {
              svg.rect([
                attr("x", pos.x * size + { offset.x + center_offset }),
                attr("y", pos.y * size + { offset.y + center_offset }),
                attr("width", wall_size),
                attr("height", wall_size),
              ])
            })
          }
        })
      },
      // exit
      svg.g(
        [
          // attr_str("fill", "green"), 
        ],
        {
          let exit = level_gen.exit(board.level.exit, board.w, board.h)
          let exit_bbox = to_bbox(exit.pos)
          let wall_bbox = to_bbox(exit.wall)
          let wall_x = wall_bbox.x + offset.x
          let wall_y = wall_bbox.y + offset.y
          let wall_h = wall_bbox.h
          let countdown = level_gen.exit_countdown(board.level)
          // centering.. fiddly because 10 is wider than single digits
          let #(countdown_x, countdown_y) = case exit.orientation {
            level_gen.Vertical -> {
              let x = case countdown {
                10 -> wall_x + 1
                _ -> wall_x + 6
              }
              let y = wall_y + wall_h - 13
              #(x, y)
            }
            level_gen.Horizontal -> {
              let x = case countdown {
                10 -> wall_x + 11
                _ -> wall_x + 15
              }
              let y = wall_y + wall_h - 5
              #(x, y)
            }
          }

          case board.level.exit_revealed {
            True -> {
              let hilite = color.hsl(126, 90, 61)
              [
                svg.rect([
                  attr_str("fill", hilite),
                  attr_str("opacity", "0.6"),
                  ..bbox_to_attrs(exit_bbox, offset)
                ]),
                svg.rect([
                  attr_str("fill", hilite),
                  attr_str("opacity", "1.0"),
                  ..bbox_to_attrs(wall_bbox, offset)
                ]),
                svg.line([
                  attr_str("stroke", color.grid_lines()),
                  attr("stroke-width", 5),
                  ..bbox_lines(wall_bbox, offset, Down)
                ]),
                svg.line([
                  attr_str("stroke", color.grid_lines()),
                  attr("stroke-width", 5),
                  ..bbox_lines(wall_bbox, offset, Up)
                ]),
              ]
            }
            False -> {
              [
                svg.rect([
                  attr_str("fill", color.grid_border()),
                  attr_str("opacity", "0.2"),
                  ..bbox_to_attrs(exit_bbox, offset)
                ]),
                svg.rect([
                  attr_str("fill", color.background()),
                  attr_str("stroke", color.grid_border()),
                  attr("stroke-width", 2),
                  ..bbox_to_attrs(wall_bbox, offset)
                ]),
                {
                  svg.text(
                    [
                      attr("x", countdown_x),
                      attr("y", countdown_y),
                      attr_str("class", "share-tech-mono-regular"),
                      attr_str("class", "pause-text"),
                      attr_str("fill", "white"),
                    ],
                    int.to_string(countdown),
                  )
                },
              ]
            }
          }
        },
      ),
      // menu bar
      svg.g([attr("stroke-width", 0), attr_str("fill", color.background())], [
        svg.rect([
          attr("x", 0),
          attr("y", 0),
          attr("width", w),
          attr("height", size),
        ]),
      ]),
      svg.g([attr_str("fill", "white")], [
        svg.text(
          [
            attr("x", 8),
            attr("y", size - 12),
            attr_str("class", "share-tech-mono-regular"),
            attr_str("class", "pause-text"),
          ],
          "score:"
            <> int.to_string(run.score + board.level.score)
            <> "("
            <> int.to_string(board.level.score)
            <> ")",
        ),
        svg.text(
          [
            attr("x", 120),
            attr("y", size - 12),
            attr_str("class", "share-tech-mono-regular"),
            attr_str("class", "pause-text"),
          ],
          "lives:" <> int.to_string(run.lives),
        ),
      ]),
      // borders
      svg.g([attr_str("stroke", color.game_outline())], [
        line(0, 0, w, 0, grid_line_width * 2),
        line(0, size, w, size, grid_line_width),
        line(0, 0, 0, h, grid_line_width * 2),
        line(0, h, w, h, grid_line_width * 2),
        line(w, 0, w, h, grid_line_width * 2),
      ]),
    ],
  )
}

fn snek_to_points(snek: List(Pos), size: Int, offset: Pos) -> String {
  let half_size = size / 2
  snek
  |> list.map(fn(pos) {
    Pos(
      { pos.x * size } + half_size + offset.x,
      { pos.y * size } + half_size + offset.y,
    )
  })
  |> list.map(fn(pos) { int.to_string(pos.x) <> "," <> int.to_string(pos.y) })
  |> list.fold("", fn(pos, acc) { acc <> " " <> pos })
}
