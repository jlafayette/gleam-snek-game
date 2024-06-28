import color
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/set.{type Set}
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{text}
import lustre/element/html
import lustre/element/svg

import level
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
  Board(food: Set(Pos), snek: Snek, walls: List(Pos), w: Int, h: Int, size: Int)
}

type GameState {
  Menu
  Play
  Pause
  GameOver
}

type Model {
  Model(
    board: Board,
    score: Int,
    tick_speed: Int,
    state: GameState,
    keydown: String,
  )
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(Model(init_board(), 0, 250, Menu, "N/A"), effect.none())
}

fn init_board() -> Board {
  let width = 20
  let height = 15
  let tile_size = 40
  let level = level.get(3, width, height)
  Board(
    init_food([level.snek_pos, ..level.walls], width, height),
    player.init(level.snek_pos, level.snek_dir),
    level.walls,
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
      #(
        Model(
          ..model,
          board: Board(..model.board, snek: new_snek),
          keydown: str,
          state: new_state,
        ),
        effect.none(),
      )
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

fn update_game_over(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Keydown(str) -> {
      case str {
        "Space" -> {
          #(
            Model(..model, board: init_board(), keydown: str, state: Play),
            every(model.tick_speed, Tick),
          )
        }
        _ -> #(Model(..model, keydown: str), effect.none())
      }
    }
    _ -> #(model, effect.none())
  }
}

fn reset_board(board: Board, lvl: Int) -> Board {
  // let level =  get_level.get(lvl)
  // Board(..board, snek: player.init(pos, Right))
  todo
}

fn move(model: Model) -> Model {
  let board = model.board
  let #(snek, game_over, ate) =
    player.move(model.board.snek, board.food, board.walls, board.w, board.h)
  let new_food = update_food(board)
  let score_increase = case game_over, ate {
    False, True -> 200
    _, _ -> 0
  }
  let new_board = Board(..board, snek: snek, food: new_food)
  case game_over {
    True -> Model(..model, score: 0, board: new_board, state: GameOver)
    False ->
      Model(
        ..model,
        board: new_board,
        score: model.score + score_increase,
        state: Play,
      )
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
  let walls = board.walls
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
      [
        html.div([class("mask")], [
          html.h1([class("game-header")], [text("Snek Game")]),
          html.p([class("sub-header"), menu_font_class()], [
            text("Press 'SPACE' to start"),
          ]),
          html.h3([class("controls-header"), menu_font_class()], [
            text("Controls"),
          ]),
          html.p([class("controls-text"), menu_font_class()], [
            text("Use WASD or arrow keys to move"),
          ]),
        ]),
      ]
    }
    Play -> [grid(model.board, model.score)]
    Pause -> {
      [
        grid(model.board, model.score),
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
    GameOver -> {
      [
        grid(model.board, model.score),
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

fn attr(name: String, value: Int) -> attribute.Attribute(a) {
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

fn grid(board: Board, score: Int) {
  let size = board.size
  let offset = Pos(0, size)
  let w = board.w * size + offset.x
  let h = board.h * size + offset.y
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
      // background
      svg.rect([
        attr("width", w),
        attr("height", h),
        attr("stroke-width", 0),
        attr_str("fill", color.grid_background()),
      ]),
      // vertical interior grid lines
      svg.g(
        [attr_str("stroke", color.grid_lines())],
        list.range(1, { w / size } - 1)
          |> list.map(fn(a) {
            let x = a * size
            line(x, size, x, h, grid_line_width)
          }),
      ),
      // horizontal interior grid lines
      svg.g(
        [attr_str("stroke", color.grid_lines())],
        list.range(1, { h / size } - 1)
          |> list.map(fn(a) {
            let y = a * size + offset.y
            line(0, y, w, y, grid_line_width)
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
            attr_str(
              "points",
              snek_to_points(board.snek.body, size, Pos(0, size)),
            ),
          ]),
        ],
      ),
      // walls
      svg.g(
        [attr_str("fill", color.background()), attr("strok-width", 0)],
        board.walls
          |> list.map(fn(pos) {
            svg.rect([
              attr("x", pos.x * size + offset.x),
              attr("y", pos.y * size + offset.y),
              attr("width", size),
              attr("height", size),
            ])
          }),
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
            attr("y", offset.y - 12),
            attr_str("class", "share-tech-mono-regular"),
            attr_str("class", "pause-text"),
          ],
          "score:" <> int.to_string(score),
        ),
      ]),
      // borders
      svg.g([attr_str("stroke", color.grid_border())], [
        line(0, 0, w, 0, grid_line_width * 2),
        line(0, offset.y, w, size, grid_line_width),
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
