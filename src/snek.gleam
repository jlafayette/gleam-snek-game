import gleam/float
import gleam/int
import gleam/io
import gleam/list
import lustre
import lustre/attribute.{type Attribute as Attr}
import lustre/effect
import lustre/element.{text}
import lustre/element/html
import lustre/element/svg

import board.{type Board, Board}
import color
import level as level_gen
import player
import position.{type Pos, Down, Left, Pos, Right, Up}
import sound
import time

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
}

// --- Keyboard Input

pub type Event

@external(javascript, "./snek_ffi.mjs", "eventCode")
fn event_code(event: Event) -> String

@external(javascript, "./snek_ffi.mjs", "documentAddEventListener")
fn document_add_event_listener(type_: String, listener: fn(Event) -> Nil) -> Nil

// --- Tick for game update

const tick_speed = time.tick_speed

const exiting_tick_speed = 50

fn f_every(interval: Int, tick: msg) -> effect.Effect(msg) {
  [
    effect.from(fn(dispatch) { dispatch(tick) }),
    effect.from(fn(dispatch) {
      window_set_interval(interval, fn() { dispatch(tick) })
    }),
  ]
  |> effect.batch
}

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

type GameState {
  Menu
  Play(Int)
  Pause
  Exiting
  Died
  GameOver
}

const max_lives = 3

type Run {
  Run(score: Int, level_score: Int, lives: Int)
}

type Model {
  Model(board: Board, run: Run, state: GameState, keydown: String)
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(
      board: board.init(1),
      run: Run(score: 0, level_score: 0, lives: max_lives),
      state: Menu,
      keydown: "N/A",
    ),
    effect.none(),
  )
}

// --- Update

type Msg {
  Keydown(String)
  Tick
  TickSkip
  TickStart(Int)
  TickStop
}

fn tick_skip() -> effect.Effect(Msg) {
  effect.from(fn(dispatch) { dispatch(TickSkip) })
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case model.state {
    Menu -> {
      update_menu(model, msg)
    }
    Play(ms) -> {
      update_play(model, msg, ms)
    }
    Exiting -> {
      update_exiting(model, msg)
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
    Keydown(str) if str == "Space" -> {
      #(
        Model(..model, state: Play(time.get()), keydown: str),
        every(tick_speed, Tick),
      )
    }
    Keydown(str) -> #(Model(..model, keydown: str), effect.none())
    _ -> #(model, effect.none())
  }
}

fn update_play(
  model: Model,
  msg: Msg,
  last_tick_ms: Int,
) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Keydown(str) -> {
      let level_num = model.board.level.number
      let new_level = case str {
        "Comma" -> level_gen.clamp(level_num - 1)
        "Period" -> level_gen.clamp(level_num + 1)
        _ -> level_num
      }
      let late = time.late(last_tick_ms)
      let #(new_state, #(new_snek, new_turn)) = case str {
        "KeyW" | "ArrowUp" -> #(
          Play(last_tick_ms),
          player.keypress(Up, late, board.move_args(model.board)),
        )
        "KeyA" | "ArrowLeft" -> #(
          Play(last_tick_ms),
          player.keypress(Left, late, board.move_args(model.board)),
        )
        "KeyS" | "ArrowDown" -> #(
          Play(last_tick_ms),
          player.keypress(Down, late, board.move_args(model.board)),
        )
        "KeyD" | "ArrowRight" -> #(
          Play(last_tick_ms),
          player.keypress(Right, late, board.move_args(model.board)),
        )
        "Escape" | "Space" -> {
          let _ = window_clear_interval()
          sound.play(sound.Pause)
          #(Pause, #(model.board.snek, False))
        }
        _ -> #(Play(last_tick_ms), #(model.board.snek, False))
      }
      case new_level == level_num {
        False -> {
          #(
            Model(..model, board: board.init(new_level), keydown: str),
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
          case new_turn {
            True -> tick_skip()
            False -> effect.none()
          },
        )
      }
    }
    Tick -> {
      io.debug("tick")
      sound.play(sound.Move)
      update_tick(model)
    }
    TickSkip -> {
      io.debug("tick-skip")
      let _ = window_clear_interval()
      #(model, f_every(time.tick_speed, Tick))
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

fn update_exiting(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Keydown(str) -> {
      #(Model(..model, keydown: str), effect.none())
    }
    Tick -> {
      io.debug("tick")
      sound.play(sound.Move)
      update_tick_exiting(model)
    }
    TickSkip -> {
      #(model, effect.none())
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
          sound.play(sound.Unpause)
          #(
            Model(..model, keydown: str, state: Play(time.get())),
            every(tick_speed, Tick),
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
              board: board.init(model.board.level.number),
              keydown: str,
              state: Play(time.get()),
            ),
            every(tick_speed, Tick),
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
              run: Run(score: 0, level_score: 0, lives: max_lives),
              board: board.init(1),
              keydown: str,
              state: Play(time.get()),
            ),
            every(tick_speed, Tick),
          )
        }
        _ -> #(Model(..model, keydown: str), effect.none())
      }
    }
    _ -> #(model, effect.none())
  }
}

fn update_tick(model: Model) -> #(Model, effect.Effect(Msg)) {
  let #(new_board, result) = board.update(model.board)
  case result.died {
    True -> {
      sound.play(sound.HitWall)
      let lives = model.run.lives - 1
      case lives == 0 {
        True -> #(
          Model(
            ..model,
            run: Run(..model.run, lives: lives),
            board: new_board,
            state: GameOver,
          ),
          effect.none(),
        )
        False -> #(
          Model(
            ..model,
            run: Run(..model.run, lives: lives),
            board: new_board,
            state: Died,
          ),
          effect.none(),
        )
      }
    }
    False -> {
      case result.exit {
        True -> {
          sound.play(sound.LevelFinished)
          #(
            Model(..model, board: new_board, state: Exiting),
            every(exiting_tick_speed, Tick),
          )
        }
        False -> {
          // increase level score if ate this turn
          let lvl_score = case result.ate {
            True -> model.run.level_score + 1
            False -> model.run.level_score
          }
          #(
            Model(
              ..model,
              run: Run(..model.run, level_score: lvl_score),
              board: new_board,
              state: Play(time.get()),
            ),
            effect.none(),
          )
        }
      }
    }
  }
}

fn update_tick_exiting(model: Model) -> #(Model, effect.Effect(Msg)) {
  let #(new_board, done) = board.update_exiting(model.board)
  case done {
    True -> {
      let score = model.run.score + model.run.level_score
      #(
        Model(
          ..model,
          run: Run(..model.run, score: score, level_score: 0),
          state: Play(time.get()),
          board: board.next_level(model.board),
        ),
        every(tick_speed, Tick),
      )
    }
    False -> {
      #(Model(..model, board: new_board), effect.none())
    }
  }
}

// --- View
const class = attribute.class

type ZElem(a) {
  ZElem(index: Int, elem: element.Element(a))
}

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
      [draw_board(model.board, model.run, model.state)]
    }
    Play(_last_tick_ms) -> [draw_board(model.board, model.run, model.state)]
    Exiting -> [draw_board(model.board, model.run, model.state)]
    Pause -> {
      [
        draw_board(model.board, model.run, model.state),
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
        draw_board(model.board, model.run, model.state),
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
        draw_board(model.board, model.run, model.state),
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

fn draw_board(b: Board, run: Run, state: GameState) -> element.Element(a) {
  let last_tick_ms = case state {
    Play(ms) -> ms
    _ -> 0
  }
  let size = b.size
  let to_bbox = fn(p: Pos) -> position.Bbox {
    position.to_bbox(p, b.level.w, b.level.h, size)
  }

  let offset = Pos(size / 2, size + size / 2)
  let board_w = b.level.w * size
  let board_h = b.level.h * size
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
      ])
        |> ZElem(0, _)
        |> list_of_one,
      // svg.rect([
      //   attr_str("fill", "url(#pattern)"),
      //   attr("x", 0),
      //   attr("y", 0),
      //   attr("width", half_size),
      //   attr("height", h),
      //   attr_str("stroke", "#a6a6a6"),
      //   attr("stroke-width", 0),
      // ])
      //   |> ZElem(4, _)
      //   |> list_of_one,
      draw_edge_walls("pattern", w, h, size, offset)
        |> ZElem(
          case state == Exiting {
            True -> 2
            False -> 4
          },
          _,
        )
        |> list_of_one,
      svg.rect([
        attr("x", offset.x),
        attr("y", offset.y),
        attr("width", board_w),
        attr("height", board_h),
        attr("stroke-width", 0),
        attr_str("fill", color.grid_background()),
      ])
        |> ZElem(0, _)
        |> list_of_one,
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
      )
        |> ZElem(1, _)
        |> list_of_one,
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
      )
        |> ZElem(1, _)
        |> list_of_one,
      // food
      draw_food(board.food(b), food_radius, size, offset)
        |> ZElem(2, _)
        |> list_of_one,
      // wall spawns
      draw_wall_spawns(board.get_wall_spawns(b), size, offset)
        |> ZElem(2, _)
        |> list_of_one,
      // snek
      draw_snek(b.snek, snek_width, size, offset) |> ZElem(3, _) |> list_of_one,
      // walls
      draw_walls(board.walls(b), size, offset) |> ZElem(4, _) |> list_of_one,
      // exit
      draw_exit(b.exit, board.exit_info(b), state, to_bbox, offset),
      // draw snek inputs
      // TODO: replace this with something subtle like snake eye direction
      //       or something
      // draw_snek_input(
      //   b.snek,
      //   last_tick_ms,
      //   int_fraction(size, 0.1),
      //   size,
      //   offset,
      // )
      //   |> ZElem(5, _)
      //   |> list_of_one,
      // menu bar
      draw_menu_bar(b.exit, run, last_tick_ms, w, h, size)
        |> list.map(ZElem(4, _)),
      // borders
      svg.g([attr_str("stroke", color.game_outline())], [
        line(0, 0, w, 0, grid_line_width * 2),
        line(0, size, w, size, grid_line_width),
        line(0, 0, 0, h, grid_line_width * 2),
        line(0, h, w, h, grid_line_width * 2),
        line(w, 0, w, h, grid_line_width * 2),
      ])
        |> ZElem(4, _)
        |> list_of_one,
    ]
      |> list.flatten
      |> list.sort(fn(e1: ZElem(a), e2: ZElem(a)) {
        int.compare(e1.index, e2.index)
      })
      |> list.map(fn(e: ZElem(a)) { e.elem }),
  )
}

fn list_of_one(elem: a) -> List(a) {
  [elem]
}

fn draw_snek(snek: player.Snek, snek_width: Int, size: Int, offset: Pos) {
  svg.g(
    [
      attr_str("stroke", color.snek()),
      attr("stroke-width", snek_width),
      attr_str("fill-opacity", "0"),
    ],
    [
      svg.polyline([
        attr_str("stroke-linecap", "square"),
        attr_str("points", snek_to_points(snek.body, size, offset)),
      ]),
    ],
  )
}

fn draw_snek_input(
  snek: player.Snek,
  last_snek_ms: Int,
  radius: Int,
  size: Int,
  offset: Pos,
) -> element.Element(a) {
  let color = case time.late(last_snek_ms) {
    True -> "red"
    False -> "orange"
  }
  let half_size = size / 2
  svg.g(
    [attr_str("fill", color), attr("stroke-width", 0)],
    player.input_positions(snek)
      |> list.map(fn(pos) {
        svg.circle([
          attr("cx", { pos.x * size } + half_size + offset.x),
          attr("cy", { pos.y * size } + half_size + offset.y),
          attr("r", radius),
        ])
      }),
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

fn draw_food(food: List(Pos), food_radius: Int, size: Int, offset: Pos) {
  let half_size = size / 2

  svg.g(
    [attr_str("fill", color.food()), attr("stroke-width", 0)],
    food
      |> list.map(fn(pos) {
        svg.circle([
          attr("cx", { pos.x * size } + half_size + offset.x),
          attr("cy", { pos.y * size } + half_size + offset.y),
          attr("r", food_radius),
        ])
      }),
  )
}

fn draw_edge_walls(
  pattern: String,
  w: Int,
  h: Int,
  size: Int,
  offset: Pos,
) -> element.Element(a) {
  let fill = "url(#" <> pattern <> ")"

  let path_m = fn(p: String, x: Int, y: Int) -> String {
    p <> "M " <> int.to_string(x) <> " " <> int.to_string(y)
  }
  let path_h = fn(p: String, a: Int) -> String {
    p <> " h " <> int.to_string(a)
  }
  let path_v = fn(p: String, a: Int) -> String {
    p <> " v " <> int.to_string(a)
  }
  let path_z = fn(p: String) -> String { p <> " z" }

  let wi = w - size
  let hi = h - { size * 2 }
  let path =
    path_m("", 0, size)
    |> path_h(w)
    |> path_v(h)
    |> path_h(-w)
    |> path_z
    <> " "
    |> path_m(offset.x, offset.y)
    |> path_h(wi)
    |> path_v(hi)
    |> path_h(-wi)
    |> path_z

  svg.g([attr_str("fill-rule", "evenodd")], [
    svg.path([
      attr_str("fill", color.background()),
      attr_str("d", path),
      attr("stroke-width", 0),
    ]),
    svg.path([
      attr_str("fill", fill),
      attr_str("d", path),
      attr("stroke-width", 0),
    ]),
  ])
}

fn draw_walls(walls: List(Pos), size: Int, offset: Pos) -> element.Element(a) {
  let wall_size = int_fraction(size, 0.8)
  let center_offset = int_fraction(size, 0.1)
  svg.g([attr_str("fill", color.grid_lines())], {
    {
      walls
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
}

fn draw_wall_spawns(
  wall_spawns: List(board.WallSpawnInfo),
  size: Int,
  offset: Pos,
) -> element.Element(a) {
  svg.g([attr_str("fill", "red")], {
    {
      wall_spawns
      |> list.filter(fn(info) {
        !info.has_wall && info.delay < board.wall_spawn_min
      })
      |> list.map(fn(info) {
        let #(text_color, outline_color, outline_opacity) = case info.has_food {
          True ->
            case info.delay {
              x if x >= 8 -> #("white", "white", 0.0)
              x if x >= 4 -> #("yellow", "orange", 0.3)
              _ -> #("orange", "red", 0.5)
            }
          False ->
            case info.delay {
              x if x >= 8 -> #("white", "white", 0.0)
              x if x >= 4 -> #("orange", "orange", 0.3)
              _ -> #("red", "red", 0.5)
            }
        }
        let center_offset = center_number(info.delay, size, size)
        [
          svg.text(
            [
              attr("x", info.pos.x * size + { offset.x + center_offset.x }),
              attr("y", info.pos.y * size + { offset.y + center_offset.y }),
              attr_str("class", "share-tech-mono-regular"),
              attr_str("class", "pause-text"),
              attr_str("fill", text_color),
            ],
            int.to_string(info.delay),
          ),
          {
            let rect_size = int_fraction(size, 0.8)
            let rect_offset = int_fraction(size, 0.1)
            let x = info.pos.x * size + { offset.x + rect_offset }
            let y = info.pos.y * size + { offset.y + rect_offset }
            rect_outline(
              Pos(x, y),
              rect_size,
              rect_size,
              outline_color,
              outline_opacity,
            )
          },
        ]
      })
      |> list.flatten
    }
  })
}

fn draw_exit(
  exit: board.Exit,
  exit_info: board.ExitInfo,
  state: GameState,
  to_bbox: fn(Pos) -> position.Bbox,
  offset: Pos,
) -> List(ZElem(a)) {
  let exit_bbox = to_bbox(exit_info.pos)
  let wall_bbox = to_bbox(exit_info.wall)

  let behind = 2
  let infront = 4

  case exit {
    board.ExitTimer(_, _) -> {
      let hilite = color.hsl(126, 90, 61)
      let exiting_behind = case state == Exiting {
        True -> behind
        False -> infront
      }
      [
        svg.rect([
          attr_str("fill", hilite),
          attr_str("opacity", "0.6"),
          ..bbox_to_attrs(exit_bbox, offset)
        ])
          |> ZElem(behind, _),
        svg.rect([
          attr_str("fill", hilite),
          attr_str("opacity", "1.0"),
          ..bbox_to_attrs(wall_bbox, offset)
        ])
          |> ZElem(exiting_behind, _),
        svg.line([
          attr_str("stroke", color.grid_lines()),
          attr("stroke-width", 5),
          ..bbox_lines(wall_bbox, offset, Down)
        ])
          |> ZElem(exiting_behind, _),
        svg.line([
          attr_str("stroke", color.grid_lines()),
          attr("stroke-width", 5),
          ..bbox_lines(wall_bbox, offset, Up)
        ])
          |> ZElem(exiting_behind, _),
      ]
    }
    board.Exit(_, _) -> {
      [
        svg.rect([
          attr_str("fill", color.grid_border()),
          attr_str("opacity", "0.2"),
          ..bbox_to_attrs(exit_bbox, offset)
        ])
          |> ZElem(infront, _),
        svg.rect([
          attr_str("fill", color.background()),
          attr_str("stroke", color.grid_border()),
          attr("stroke-width", 2),
          ..bbox_to_attrs(wall_bbox, offset)
        ])
          |> ZElem(infront, _),
        {
          let countdown = board.exit_countdown(exit)
          let countdown_offset =
            center_number(countdown, wall_bbox.w, wall_bbox.h)
          let pos =
            Pos(wall_bbox.x, wall_bbox.y)
            |> position.add(offset)
            |> position.add(countdown_offset)
          svg.text(
            [
              attr("x", pos.x),
              attr("y", pos.y),
              attr_str("class", "share-tech-mono-regular"),
              attr_str("class", "pause-text"),
              attr_str("fill", "white"),
            ],
            int.to_string(countdown),
          )
          |> ZElem(infront, _)
        },
      ]
    }
  }
}

fn draw_menu_bar(
  exit: board.Exit,
  run: Run,
  _last_tick_ms: Int,
  w: Int,
  _h: Int,
  size: Int,
) -> List(element.Element(a)) {
  [
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
          <> int.to_string(run.score + run.level_score)
          <> "("
          <> int.to_string(run.level_score)
          <> ")",
      ),
      svg.text(
        [
          attr("x", 135),
          attr("y", size - 12),
          attr_str("class", "share-tech-mono-regular"),
          attr_str("class", "pause-text"),
        ],
        "lives:" <> int.to_string(run.lives),
      ),
      case exit {
        board.Exit(_, to_unlock) -> {
          svg.text(
            [
              attr("x", 240),
              attr("y", size - 12),
              attr_str("class", "share-tech-mono-regular"),
              attr_str("class", "pause-text"),
            ],
            "food to unlock:" <> int.to_string(to_unlock),
          )
        }
        board.ExitTimer(_, t) -> {
          let col = case t <= 0 {
            True -> "red"
            False -> "white"
          }
          svg.text(
            [
              attr("x", 240),
              attr("y", size - 12),
              attr_str("class", "share-tech-mono-regular"),
              attr_str("class", "pause-text"),
              attr_str("fill", col),
            ],
            int.to_string(t),
          )
        }
      },
    ]),
  ]
}

fn rect_outline(
  pos: Pos,
  w: Int,
  h: Int,
  color: String,
  opacity: Float,
) -> element.Element(a) {
  let line_width = 1
  let x0 = pos.x
  let x1 = pos.x + w
  let y0 = pos.y
  let y1 = pos.y + h
  svg.g(
    [attr_str("stroke", color), attr_str("opacity", float.to_string(opacity))],
    [
      line(x0, y0, x1, y0, line_width),
      line(x0, y0, x0, y1, line_width),
      line(x0, y1, x1, y1, line_width),
      line(x1, y0, x1, y1, line_width),
    ],
  )
}

fn center_number(n: Int, w: Int, h: Int) -> Pos {
  let text_w = case n > 9 {
    True -> 9
    False -> 5
  }
  let text_h = 10
  let x = w / 2 - text_w
  let y = { h - text_h } / 2
  Pos(x, h - y)
}
