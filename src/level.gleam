import gleam/int
import gleam/list
import gleam/option.{type Option, Some}
import gleam/string
import position.{type Move, type Pos, Down, Left, Pos, Right, Up}

pub type Level {
  Level(number: Int, snek_pos: Pos, snek_dir: Move, walls: List(Pos))
}

pub fn clamp(n: Int) -> Int {
  int.clamp(n, 1, 3)
}

const lvl_1 = "
....................
....................
....................
....................
....................
....................
....................
.....S>.............
....................
....................
....................
....................
....................
....................
....................
"

const lvl_2 = "
....................
....................
....................
....S>..............
....................
....................
....................
...WWWWWWWWWWWWWW...
....................
....................
....................
....................
....................
....................
....................
"

const lvl_3 = "
....................
....................
.....W........W.....
.....W........W.....
.....W........W.....
.....W........W.....
.....W........W.....
.....W........W.....
.....W........W.....
.....W........W.....
.....W....^...W.....
.....W....S...W.....
.....W........W.....
....................
....................
"

type Item {
  Wall(Pos)
  SnekInit(Pos)
  Dir(Move)
  Empty
}

type Acc =
  #(List(Pos), Option(Pos), Option(Move))

fn collect_items(acc: Acc, item: Item) -> Acc {
  case item {
    Wall(pos) -> #([pos, ..acc.0], acc.1, acc.2)
    SnekInit(pos) -> #(acc.0, Some(pos), acc.2)
    Dir(move) -> #(acc.0, acc.1, Some(move))
    _ -> acc
  }
}

fn read_row(row: #(String, Int)) -> List(Item) {
  let #(line, y) = row
  line
  |> string.split("")
  |> list.map2(list.range(0, 100), fn(char, x) {
    case char {
      "W" -> Wall(Pos(x, y))
      "S" -> SnekInit(Pos(x, y))
      "^" -> Dir(Up)
      ">" -> Dir(Right)
      "<" -> Dir(Left)
      "v" | "V" -> Dir(Down)
      _ -> Empty
    }
  })
  |> list.filter(fn(x) { x != Empty })
}

fn read(n: Int, lvl: String) -> Level {
  let acc =
    lvl
    |> string.split("\n")
    |> list.filter(fn(x) { x != "" })
    |> list.map2(list.range(0, 100), fn(line, y) { #(line, y) })
    |> list.map(fn(row) { read_row(row) })
    |> list.flatten
    |> list.fold(#([], Some(Pos(0, 0)), Some(Right)), collect_items)
  case acc {
    #(walls, Some(init_pos), Some(dir)) -> Level(n, init_pos, dir, walls)
    _ -> panic as "Bad level data"
  }
}

pub fn get(n: Int, w: Int, h: Int) -> Level {
  case n {
    1 -> read(1, lvl_1)
    2 -> read(2, lvl_2)
    3 -> read(3, lvl_3)
    _ -> get(1, w, h)
  }
}
