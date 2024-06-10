import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/queue.{type Queue}
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{text}
import lustre/element/html
import lustre/element/svg
import lustre/event
import lustre/ui.{type Theme, Px, Rem, Size, Theme}
import lustre/ui/button
import lustre/ui/util/colour
import lustre/ui/util/styles

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

// --- Model

type Pos {
  Pos(x: Int, y: Int)
}

type Board {
  Board(food: List(Pos), snek: Queue(Pos))
}

type Model {
  Model(theme: Theme, board: Board, keydown: String)
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  let theme =
    Theme(
      space: Size(base: Rem(1.5), ratio: 1.618),
      text: Size(base: Rem(1.125), ratio: 1.215),
      radius: Px(4.0),
      primary: colour.slate_dark(),
      greyscale: colour.slate(),
      error: colour.red(),
      success: colour.green(),
      warning: colour.yellow(),
      info: colour.blue(),
    )
  #(
    Model(
      theme,
      Board(
        [Pos(0, 0), Pos(9, 9), Pos(3, 8)],
        queue.from_list([Pos(6, 6), Pos(6, 6), Pos(6, 6)]),
      ),
      "N/A",
    ),
    effect.none(),
  )
}

// --- Update

type Move {
  Left
  Right
  Down
  Up
}

type Msg {
  Move(Move)
  Keydown(String)
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Move(move) -> #(
      Model(
        ..model,
        board: Board(..model.board, snek: move_snek(model.board.snek, move)),
      ),
      effect.none(),
    )
    Keydown(str) -> #(Model(..model, keydown: str), effect.none())
  }
}

fn move_snek(snek: Queue(Pos), move: Move) -> Queue(Pos) {
  case queue.pop_front(snek) {
    Ok(#(head, _)) -> {
      let s = drop_last(snek)
      queue.push_front(s, new_head(head, move))
    }
    Error(_) -> queue.new()
  }
}

fn new_head(head: Pos, move: Move) -> Pos {
  case move {
    Left -> Pos(head.x - 1, head.y)
    Right -> Pos(head.x + 1, head.y)
    Down -> Pos(head.x, head.y + 1)
    Up -> Pos(head.x, head.y - 1)
  }
}

fn drop_last(snek: Queue(Pos)) -> Queue(Pos) {
  case queue.pop_back(snek) {
    Ok(#(_, q)) -> q
    Error(_) -> queue.new()
  }
}

// --- View

fn view(model: Model) {
  html.div([], [
    styles.elements(),
    styles.theme(model.theme),
    ui.centre(
      [],
      ui.prose([], [
        ui.centre([], html.h1([], [text("Snek Game")])),
        ui.centre([], html.h3([], [text("Use WASD or arrow keys to move")])),
        html.br([]),
      ]),
    ),
    ui.centre(
      [],
      ui.cluster([], [
        html.p([], [text(model.keydown)]),
        square_button(Move(Left), "Lf"),
        square_button(Move(Right), "Rt"),
        square_button(Move(Down), "Dn"),
        square_button(Move(Up), "Up"),
      ]),
    ),
    ui.centre([], grid(model.board)),
  ])
}

fn square_button(msg: Msg, txt: String) {
  let px_size = "40px"
  ui.button(
    [
      event.on_click(msg),
      button.solid(),
      attribute.style([
        #("height", px_size),
        #("width", px_size),
        #("text-align", "center"),
        #("padding", "0px"),
        #("line-height", "0px"),
      ]),
    ],
    [text(txt)],
  )
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
  let w = 800
  let h = 600
  let size = 40
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
        attr_str("fill", "#393939"),
      ]),
      // borders
      svg.g([attr_str("stroke", "#0f0b19")], [
        line(0, 0, w, 0, grid_line_width * 2),
        line(0, 0, 0, h, grid_line_width * 2),
        line(0, h, w, h, grid_line_width * 2),
        line(w, 0, w, h, grid_line_width * 2),
      ]),
      // vertical interior grid lines
      svg.g(
        [attr_str("stroke", "#0f0b19")],
        list.range(1, { w / size } - 1)
          |> list.map(fn(a) {
            let x = a * size
            line(x, 0, x, h, grid_line_width)
          }),
      ),
      // horizontal interior grid lines
      svg.g(
        [attr_str("stroke", "#0f0b19")],
        list.range(1, { h / size } - 1)
          |> list.map(fn(a) {
            let y = a * size
            line(0, y, w, y, grid_line_width)
          }),
      ),
      // food
      svg.g(
        [attr_str("fill", "#f43f5e"), attr("stroke-width", 0)],
        board.food
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
          attr_str("stroke", "#03d3fc"),
          attr("stroke-width", snek_width),
          attr_str("fill-opacity", "0"),
        ],
        [
          svg.polyline([
            attr_str("stroke-linecap", "square"),
            // attr_str("stroke-linejoin", "round"),
            // attr_str("points", "20,20 20,60 60,60"),
            attr_str("points", snek_to_points(board.snek, size)),
          ]),
        ],
      ),
    ],
  )
}

fn snek_to_points(snek: Queue(Pos), size: Int) -> String {
  let half_size = size / 2
  snek
  |> queue.to_list
  |> list.map(fn(pos) {
    Pos({ pos.x * size } + half_size, { pos.y * size } + half_size)
  })
  |> list.map(fn(pos) { int.to_string(pos.x) <> "," <> int.to_string(pos.y) })
  |> list.fold("", fn(pos, acc) { acc <> " " <> pos })
}
