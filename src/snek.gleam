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

type Pos {
  Pos(x: Int, y: Int)
}

type Snek {
  Snek(body: List(Pos), food: Int)
}

type Board {
  Board(food: Set(Pos), snek: Snek, walls: List(Pos), w: Int, h: Int, size: Int)
}

type Move {
  Left
  Right
  Down
  Up
}

type GameState {
  Menu
  Play(Move, Move)
  Pause(Move, Move)
  GameOver
}

type Model {
  Model(board: Board, tick_speed: Int, state: GameState, keydown: String)
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(Model(init_board(), 250, Menu, "N/A"), effect.none())
}

fn init_board() -> Board {
  let width = 20
  let height = 15
  let tile_size = 40
  let level = 2
  let #(walls, snek_init_pos) = init_walls(level, width, height)
  Board(
    init_food([snek_init_pos, ..walls], width, height),
    init_snek(snek_init_pos),
    walls,
    width,
    height,
    tile_size,
  )
}

fn init_snek(p: Pos) -> Snek {
  Snek(body: [p, p, p], food: 0)
}

fn init_food(exclude: List(Pos), w: Int, h: Int) -> Set(Pos) {
  let f = Pos(int.random(w), int.random(h))
  case list.contains(exclude, f) {
    True -> init_food(exclude, w, h)
    False -> set.from_list([f])
  }
}

fn init_walls(level: Int, w: Int, h: Int) -> #(List(Pos), Pos) {
  case level {
    1 -> #([], Pos(w / 2, h / 2))
    2 -> {
      let wall_h = h / 2
      let gap = 3
      let walls =
        list.range(gap, w - gap - 1)
        |> list.map(fn(x) { Pos(x, wall_h) })
      #(walls, Pos(w / 4, h / 4))
    }
    _ -> #([], Pos(w / 2, h / 2))
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
    Play(prev_mv, mv) -> {
      update_play(model, msg, prev_mv, mv)
    }
    Pause(prev_mv, mv) -> {
      update_pause(model, msg, prev_mv, mv)
    }
    GameOver -> {
      update_game_over(model, msg)
    }
  }
}

fn update_menu(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Keydown(str) if str == "Space" -> #(
      Model(..model, state: Play(Right, Right), keydown: str),
      every(model.tick_speed, Tick),
    )
    Keydown(str) -> #(Model(..model, keydown: str), effect.none())
    _ -> #(model, effect.none())
  }
}

fn update_play(
  model: Model,
  msg: Msg,
  prev_mv: Move,
  mv: Move,
) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Keydown(str) -> {
      let state = case str {
        "KeyW" | "ArrowUp" -> Play(prev_mv, Up)
        "KeyA" | "ArrowLeft" -> Play(prev_mv, Left)
        "KeyS" | "ArrowDown" -> Play(prev_mv, Down)
        "KeyD" | "ArrowRight" -> Play(prev_mv, Right)
        "Escape" | "Space" -> {
          let _ = window_clear_interval()
          Pause(prev_mv, mv)
        }
        _ -> Play(prev_mv, mv)
      }
      #(Model(..model, keydown: str, state: state), effect.none())
    }
    Tick -> {
      io.debug("tick")
      #(move(model, prev_mv, mv), effect.none())
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

fn update_pause(
  model: Model,
  msg: Msg,
  prev_mv: Move,
  mv: Move,
) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Keydown(str) -> {
      case str {
        "Escape" | "Space" -> {
          #(
            Model(..model, keydown: str, state: Play(prev_mv, mv)),
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
              board: init_board(),
              keydown: str,
              state: Play(Right, Right),
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

fn move(model: Model, prev_mv: Move, mv: Move) -> Model {
  let #(new_board, game_over, mv_taken) = move_snek(model.board, prev_mv, mv)
  case game_over {
    True -> Model(..model, board: new_board, state: GameOver)
    False -> Model(..model, board: new_board, state: Play(mv_taken, mv_taken))
  }
}

fn move_snek(board: Board, prev_mv: Move, mv: Move) -> #(Board, Bool, Move) {
  case board.snek.body {
    [head, ..body] -> {
      let #(head, mv_taken) = new_head(head, body, prev_mv, mv)
      let #(new_food, ate) = update_food(head, board.food)
      let new_food = add_random_food(head, board, new_food)
      let snek = {
        let food = int.max(0, board.snek.food - 1)
        let food = case ate {
          True -> food + 2
          False -> food
        }
        case board.snek.food > 0 {
          True -> {
            let body = board.snek.body
            Snek([head, ..body], food)
          }
          False -> {
            let body = drop_last(board.snek.body)
            Snek([head, ..body], food)
          }
        }
      }
      let game_over =
        check_collide(head, board.w, board.h)
        || check_wall_collide(head, board.walls)
        || check_self_collide(head, board.snek)
      #(Board(..board, snek: snek, food: new_food), game_over, mv_taken)
    }
    _ -> #(board, True, mv)
  }
}

fn check_self_collide(head: Pos, snek: Snek) -> Bool {
  let body = case snek.food > 0 {
    True -> snek.body
    False -> drop_last(snek.body)
  }
  list.contains(body, head)
}

fn check_wall_collide(head: Pos, walls: List(Pos)) -> Bool {
  list.contains(walls, head)
}

fn update_food(head: Pos, food: Set(Pos)) -> #(Set(Pos), Bool) {
  let len1 = set.size(food)
  let food2 = set.delete(food, head)
  let len2 = set.size(food2)
  #(food2, len1 > len2)
}

fn add_random_food(head: Pos, board: Board, food: Set(Pos)) -> Set(Pos) {
  let w = board.w
  let h = board.h
  let snek = board.snek
  let walls = board.walls
  case int.random(5) {
    0 -> {
      let p = random_pos(w, h)
      case head == p || body_contains(snek, p) || check_wall_collide(p, walls) {
        True -> food
        False -> set.insert(food, p)
      }
    }
    _ -> food
  }
}

fn body_contains(snek: Snek, pos: Pos) -> Bool {
  list.contains(snek.body, pos)
}

fn random_pos(w: Int, h: Int) -> Pos {
  Pos(int.random(w), int.random(h))
}

fn check_collide(head: Pos, w: Int, h: Int) -> Bool {
  case head {
    Pos(x, _) if x < 0 -> True
    Pos(x, _) if x >= w -> True
    Pos(_, y) if y < 0 -> True
    Pos(_, y) if y >= h -> True
    _ -> False
  }
}

fn new_head(head: Pos, body: List(Pos), prev_mv: Move, mv: Move) -> #(Pos, Move) {
  let head1 = case mv {
    Left -> Pos(head.x - 1, head.y)
    Right -> Pos(head.x + 1, head.y)
    Down -> Pos(head.x, head.y + 1)
    Up -> Pos(head.x, head.y - 1)
  }
  let collide = case body {
    [neck, ..] -> head1 == neck
    _ -> False
  }
  case collide {
    True -> {
      let head = case prev_mv {
        Left -> Pos(head.x - 1, head.y)
        Right -> Pos(head.x + 1, head.y)
        Down -> Pos(head.x, head.y + 1)
        Up -> Pos(head.x, head.y - 1)
      }
      #(head, prev_mv)
    }
    False -> #(head1, mv)
  }
}

fn drop_last(xs: List(v)) -> List(v) {
  xs |> drop_last_recursive([]) |> list.reverse
}

fn drop_last_recursive(xs: List(v), acc: List(v)) -> List(v) {
  case xs {
    [x, _] -> [x, ..acc]
    [x, ..rest] -> drop_last_recursive(rest, [x, ..acc])
    _ -> acc
  }
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
    Play(_, _) -> [grid(model.board)]
    Pause(_, _) -> {
      [
        grid(model.board),
        html.div([class("pause-mask")], [
          // html.div([], [
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
        grid(model.board),
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

fn grid(board: Board) {
  let size = board.size
  let w = board.w * size
  let h = board.h * size
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
      // borders
      svg.g([attr_str("stroke", color.grid_border())], [
        line(0, 0, w, 0, grid_line_width * 2),
        line(0, 0, 0, h, grid_line_width * 2),
        line(0, h, w, h, grid_line_width * 2),
        line(w, 0, w, h, grid_line_width * 2),
      ]),
      // vertical interior grid lines
      svg.g(
        [attr_str("stroke", color.grid_lines())],
        list.range(1, { w / size } - 1)
          |> list.map(fn(a) {
            let x = a * size
            line(x, 0, x, h, grid_line_width)
          }),
      ),
      // horizontal interior grid lines
      svg.g(
        [attr_str("stroke", color.grid_lines())],
        list.range(1, { h / size } - 1)
          |> list.map(fn(a) {
            let y = a * size
            line(0, y, w, y, grid_line_width)
          }),
      ),
      // walls
      svg.g(
        [attr_str("fill", color.background()), attr("strok-width", 0)],
        board.walls
          |> list.map(fn(pos) {
            svg.rect([
              attr("x", pos.x * size),
              attr("y", pos.y * size),
              attr("width", size),
              attr("height", size),
            ])
          }),
      ),
      // food
      svg.g(
        [attr_str("fill", color.food()), attr("stroke-width", 0)],
        board.food
          |> set.to_list
          |> list.map(fn(pos) {
            svg.circle([
              attr("cx", { pos.x * size } + half_size),
              attr("cy", { pos.y * size } + half_size),
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
            attr_str("points", snek_to_points(board.snek.body, size)),
          ]),
        ],
      ),
    ],
  )
}

fn snek_to_points(snek: List(Pos), size: Int) -> String {
  let half_size = size / 2
  snek
  |> list.map(fn(pos) {
    Pos({ pos.x * size } + half_size, { pos.y * size } + half_size)
  })
  |> list.map(fn(pos) { int.to_string(pos.x) <> "," <> int.to_string(pos.y) })
  |> list.fold("", fn(pos, acc) { acc <> " " <> pos })
}
