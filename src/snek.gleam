import gleam/int
import gleam/io
import gleam/list
import lustre
import lustre/attribute
import lustre/element.{text}
import lustre/element/html
import lustre/element/svg
import lustre/event.{on_click}
import lustre/ui.{type Theme, Px, Rem, Size, Theme}
import lustre/ui/button
import lustre/ui/util/colour
import lustre/ui/util/styles

pub fn main() {
  io.println("Hello from snek!")
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type Pos {
  Pos(x: Int, y: Int)
}

type Board {
  Board(food: List(Pos))
}

type Model {
  Model(count: Int, theme: Theme, board: Board)
}

fn init(_flags) -> Model {
  let theme =
    Theme(
      space: Size(base: Rem(1.5), ratio: 1.618),
      text: Size(base: Rem(1.125), ratio: 1.215),
      radius: Px(4.0),
      primary: colour.jade(),
      greyscale: colour.slate(),
      error: colour.red(),
      success: colour.green(),
      warning: colour.yellow(),
      info: colour.blue(),
    )
  Model(0, theme, Board([Pos(0, 0), Pos(9, 9), Pos(3, 8)]))
}

type Msg {
  Incr
  Decr
}

fn update(model: Model, msg: Msg) -> Model {
  let count = case msg {
    Incr -> model.count + 1
    Decr -> model.count - 1
  }
  Model(..model, count: count)
}

fn view(model: Model) {
  let count = int.to_string(model.count)
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
        square_button(Decr, "-"),
        ui.centre([], html.p([], [text(count)])),
        square_button(Incr, "+"),
      ]),
    ),
    ui.centre([], grid(model.board)),
  ])
}

fn square_button(msg: Msg, txt: String) {
  let px_size = "40px"
  ui.button(
    [
      on_click(msg),
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

fn grid(board: Board) {
  let w = 400
  let h = 400
  let size = 40
  let half_size = size / 2
  let food_radius = half_size - 4
  svg.svg(
    [
      attr("width", w),
      attr("height", h),
      attr_str("xmlns", "http://www.w3.org/2000/svg"),
      attr_str("version", "1.1"),
    ],
    [
      // borders
      svg.g([attr_str("stroke", "grey")], [
        line(0, 0, w, 0, 4),
        line(0, 0, 0, h, 4),
        line(0, h, w, h, 4),
        line(w, 0, w, h, 4),
      ]),
      // vertical interior grid lines
      svg.g(
        [attr_str("stroke", "grey")],
        list.range(1, { w / size } - 1)
          |> list.map(fn(a) {
            let x = a * size
            line(x, 0, x, h, 2)
          }),
      ),
      // horizontal interior grid lines
      svg.g(
        [attr_str("stroke", "grey")],
        list.range(1, { h / size } - 1)
          |> list.map(fn(a) {
            let y = a * size
            line(0, y, w, y, 2)
          }),
      ),
      // food
      svg.g(
        [attr_str("fill", "red"), attr("stroke-width", 0)],
        board.food
          |> list.map(fn(pos) {
            svg.circle([
              //  <circle cx="50" cy="50" r="50" />
              attr("cx", { pos.x * size } + half_size),
              attr("cy", { pos.y * size } + half_size),
              attr("r", food_radius),
            ])
          }),
      ),
    ],
  )
}
