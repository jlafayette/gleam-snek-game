import gleam/int
import gleam/io
import lustre
import lustre/attribute
import lustre/element.{text}
import lustre/element/html
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

type Model {
  Model(count: Int, theme: Theme)
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
  Model(0, theme)
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
