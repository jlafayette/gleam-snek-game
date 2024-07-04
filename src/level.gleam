import gleam/int
import gleam/list
import gleam/option.{type Option, Some}
import gleam/string
import position.{type Move, type Pos, Down, Left, Pos, Right, Up}

pub type Exit {
  Exit(pos: Pos, to_unlock: Int)
  ExitTimer(pos: Pos, timer: Int)
}

pub type Level {
  Level(
    number: Int,
    snek_pos: Pos,
    snek_dir: Move,
    walls: List(Pos),
    exit: Exit,
    score: Int,
    eaten: Int,
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
  |> list.map2(list.range(0, 100), fn(char, x) {
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
    |> list.map2(list.range(0, 100), fn(line, y) { #(line, y) })
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
      )
    _ -> panic as "Bad level data"
  }
}

pub fn clamp(n: Int) -> Int {
  int.clamp(n, 1, 5)
}

pub fn get(n: Int, w: Int, h: Int) -> Level {
  case n {
    1 -> read(1, lvl_1)
    2 -> read(2, lvl_2)
    3 -> read(3, lvl_3)
    4 -> read(4, lvl_4)
    5 -> read(5, lvl_5)
    _ -> get(1, w, h)
  }
}

fn time_to_escape(_lvl: Level) -> Int {
  // TODO: use width and height of board
  20 + 15
}

pub fn update(lvl: Level, increase: Int) -> Level {
  let increased = increase > 0
  case increased {
    True -> {
      let eaten = lvl.eaten + 1
      let exit_revealed = lvl.eaten >= 9
      let exit = case lvl.exit, exit_revealed {
        // TODO: base init timer on distance of snake to exit
        Exit(p, _), True -> ExitTimer(pos: p, timer: time_to_escape(lvl))
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
