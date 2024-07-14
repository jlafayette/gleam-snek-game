import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/string
import player.{type Snek}
import position.{type Move, type Pos, Down, Left, Pos, Right, Up}

import sound

pub type Exit {
  Exit(pos: Pos, to_unlock: Int)
  ExitTimer(pos: Pos, timer: Int)
}

const width = 20

const height = 15

pub type Level {
  Level(
    number: Int,
    snek_pos: Pos,
    snek_dir: Move,
    walls: List(Pos),
    exit: Exit,
    score: Int,
    eaten: Int,
    w: Int,
    h: Int,
  )
}

const lvl_1 = "
.........E..........
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
E...................
....................
....................
....................
"

const lvl_3 = "
....................
....................
.....W........W.....
.....W........W.....
.....W........W....E
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

const lvl_4 = "
....................
..S>................
....................
..WWWWWWWWWWWW......
....................
....................
....................
......WWWWWWWWWWWW..
....................
....................
....................
..WWWWWWWWWWWW......
....................
...................E
....................
"

const lvl_5 = "
....................
..S>................
....................
.....WWWWWWWWWW.....
....................
...W............W...
...W............W...
...W............W..E
...W............W...
...W............W...
....................
.....WWWWWWWWWW.....
....................
....................
....................
"

type Item {
  Wall(Pos)
  SnekInit(Pos)
  Dir(Move)
  ExitItem(Pos)
  Empty
}

type Acc =
  #(List(Pos), Option(Pos), Option(Move), Option(Pos))

fn collect_items(acc: Acc, item: Item) -> Acc {
  case item {
    Wall(pos) -> #([pos, ..acc.0], acc.1, acc.2, acc.3)
    SnekInit(pos) -> #(acc.0, Some(pos), acc.2, acc.3)
    Dir(move) -> #(acc.0, acc.1, Some(move), acc.3)
    ExitItem(pos) -> #(acc.0, acc.1, acc.2, Some(pos))
    _ -> acc
  }
}

fn read_row(row: #(String, Int)) -> List(Item) {
  let #(line, y) = row
  line
  |> string.split("")
  |> list.map2(list.range(0, width), fn(char, x) {
    case char {
      "W" -> Wall(Pos(x, y))
      "S" -> SnekInit(Pos(x, y))
      "^" -> Dir(Up)
      ">" -> Dir(Right)
      "<" -> Dir(Left)
      "v" | "V" -> Dir(Down)
      "E" | "e" -> ExitItem(Pos(x, y))
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
    |> list.map2(list.range(0, height), fn(line, y) { #(line, y) })
    |> list.map(fn(row) { read_row(row) })
    |> list.flatten
    |> list.fold(
      #([], Some(Pos(0, 0)), Some(Right), Some(Pos(0, 0))),
      collect_items,
    )
  case acc {
    #(walls, Some(init_pos), Some(dir), Some(exit)) ->
      Level(
        number: n,
        snek_pos: init_pos,
        snek_dir: dir,
        walls: walls,
        exit: Exit(exit, 10),
        score: 0,
        eaten: 0,
        w: width,
        h: height,
      )
    _ -> panic as "Bad level data"
  }
}

pub fn clamp(n: Int) -> Int {
  int.clamp(n, 1, 5)
}

pub fn get(n: Int) -> Level {
  case n {
    1 -> read(1, lvl_1)
    2 -> read(2, lvl_2)
    3 -> read(3, lvl_3)
    4 -> read(4, lvl_4)
    5 -> read(5, lvl_5)
    _ -> get(1)
  }
}

const abs = int.absolute_value

fn distance(p1: Pos, p2: Pos) -> Int {
  abs(p1.x - p2.x) + abs(p1.y - p2.y)
}

fn update_walls(lvl: Level, snek: Snek) -> Level {
  case lvl.exit {
    ExitTimer(exit, t) if t < 0 -> {
      let w = lvl.w
      let h = lvl.h
      // let exit = Pos(2, 0)
      // let body = [Pos(0, 0), Pos(0, 1)]
      let body = snek.body
      let walls = lvl.walls

      let candidates =
        list.range(0, w - 1)
        |> list.map(fn(x) {
          list.range(0, h - 1)
          |> list.map(fn(y) { Pos(x, y) })
        })
        |> list.flatten
        |> list.map(fn(p) { #(p, distance(p, exit)) })
        |> list.filter(fn(a) {
          let #(p, _) = a
          !list.contains(body, p) && !list.contains(walls, p)
        })
        |> list.sort(fn(a, b) {
          let #(_, da) = a
          let #(_, db) = b
          case da == db {
            True -> order.Eq
            False ->
              case da < db {
                // reversed
                True -> order.Gt
                False -> order.Lt
              }
          }
        })
      let new_wall = case candidates {
        [f, ..] -> Some(f.0)
        [] -> None
      }
      case new_wall {
        Some(wall) -> Level(..lvl, walls: [wall, ..lvl.walls])
        None -> lvl
      }
    }
    _ -> lvl
  }
}

fn time_to_escape(lvl: Level) -> Int {
  lvl.w + lvl.h
}

pub fn update(lvl: Level, increase: Int, snek: Snek) -> Level {
  let increased = increase > 0
  let lvl = case increased {
    True -> {
      let eaten = lvl.eaten + 1
      let exit_revealed = lvl.eaten >= 9
      let exit = case lvl.exit, exit_revealed {
        // TODO: base init timer on distance of snake to exit
        Exit(p, _), True -> {
          sound.play(sound.DoorOpen)
          ExitTimer(pos: p, timer: time_to_escape(lvl))
        }
        Exit(p, _), False -> Exit(p, 10 - eaten)
        ExitTimer(p, t), _ -> ExitTimer(p, t - 1)
      }
      Level(..lvl, score: lvl.score + increase, eaten: eaten, exit: exit)
    }
    False -> {
      let exit = case lvl.exit {
        ExitTimer(p, t) -> ExitTimer(p, t - 1)
        e -> e
      }
      Level(..lvl, exit: exit)
    }
  }
  update_walls(lvl, snek)
}

pub type Orientation {
  Horizontal
  Vertical
}

pub type ExitInfo {
  ExitInfo(pos: Pos, wall: Pos, orientation: Orientation)
}

pub fn exit(p: Pos, w: Int, h: Int) -> ExitInfo {
  let w1 = w - 1
  let h1 = h - 1
  let dir = case p {
    Pos(x, _y) if x == 0 -> Left
    Pos(x, _y) if x == w1 -> Right
    Pos(_x, y) if y == 0 -> Up
    Pos(_x, y) if y == h1 -> Down
    _ -> panic as "Invalid exit"
  }
  case dir {
    Left -> ExitInfo(p, Pos(p.x - 1, p.y), Vertical)
    Right -> ExitInfo(p, Pos(p.x + 1, p.y), Vertical)
    Up -> ExitInfo(p, Pos(p.x, p.y - 1), Horizontal)
    Down -> ExitInfo(p, Pos(p.x, p.y + 1), Horizontal)
  }
}

pub fn exit_countdown(lvl: Level) -> Int {
  int.max(10 - lvl.score, 0)
}
