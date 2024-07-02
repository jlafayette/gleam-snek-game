import gleam/float
import gleam/int

// #0f0b19
pub fn background() {
  hsl(257, 39, 7)
}

// #0f0b19
pub fn grid_border() {
  hsl(257, 39, 60)
}

pub fn game_outline() {
  hsl(257, 39, 60)
}

// #393939
pub fn grid_background() {
  hsl(257, 39, 7)
  // hsl(0, 0, 22)
}

pub const grid_lines = grid_border

// #f43f5e
pub fn food() {
  hsl(350, 89, 60)
}

// #03d3fc
pub fn snek() {
  hsl(190, 98, 50)
}

pub fn rgb(r: Int, g: Int, b: Int) -> String {
  "rgb("
  <> int.to_string(r)
  <> ","
  <> int.to_string(g)
  <> ","
  <> int.to_string(b)
  <> ")"
}

pub fn rgba(r: Int, g: Int, b: Int, a: Float) -> String {
  "rgba("
  <> int.to_string(r)
  <> ","
  <> int.to_string(g)
  <> ","
  <> int.to_string(b)
  <> ","
  <> float.to_string(a)
  <> ")"
}

pub fn hsl(h: Int, s: Int, l: Int) -> String {
  "hsl("
  <> int.to_string(h)
  <> ","
  <> int.to_string(s)
  <> "%,"
  <> int.to_string(l)
  <> "%)"
}

pub fn hsla(h: Int, s: Int, l: Int, a: Float) -> String {
  "hsla("
  <> int.to_string(h)
  <> ","
  <> int.to_string(s)
  <> "%,"
  <> int.to_string(l)
  <> "%,"
  <> float.to_string(a)
  <> ")"
}
