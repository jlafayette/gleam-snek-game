import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/set
import level as level_gen
import player.{type Snek}
import position.{type Pos, Down, Left, Pos, Right, Up}
import sound

const width = level_gen.width

const height = level_gen.height

pub type Exit {
  Exit(pos: Pos, to_unlock: Int)
  ExitTimer(pos: Pos, timer: Int)
}

// TODO: move some of this into the grid
// wall spawn -> grid
pub type Level {
  Level(number: Int, score: Int, w: Int, h: Int, wall_spawn: List(Pos))
}

fn get_level(parsed: level_gen.Parsed) -> Level {
  Level(
    number: parsed.number,
    score: 0,
    w: width,
    h: height,
    wall_spawn: parsed.spawns,
  )
}

pub type Grid =
  Dict(Pos, Square)

pub type Board {
  Board(level: Level, grid: Grid, snek: Snek, exit: Exit, size: Int)
}

pub fn food(b: Board) -> List(Pos) {
  dict.to_list(b.grid)
  |> list.filter(fn(kv) {
    case kv.1 {
      Square(fg: FgFood, bg: _) -> True
      _ -> False
    }
  })
  |> list.map(fn(kv) { kv.0 })
}

pub fn walls(b: Board) -> List(Pos) {
  dict.to_list(b.grid)
  |> list.filter(fn(kv) {
    case kv.1 {
      Square(fg: FgWall, bg: _) -> True
      _ -> False
    }
  })
  |> list.map(fn(kv) { kv.0 })
}

fn all_pos(w: Int, h: Int) -> List(Pos) {
  list.range(0, h - 1)
  |> list.map(fn(y) {
    list.range(0, w - 1)
    |> list.map(fn(x) { Pos(x, y) })
  })
  |> list.flatten
}

type BgSquare {
  BgExit
  BgWallSpawn(Int)
  BgEmpty
}

type FgSquare {
  FgSnakeBody
  FgSnakeTail(Int)
  FgFood
  FgEmpty
  // doesn't allow head to overlap wall - can fix this later
  FgWall
}

pub opaque type Square {
  Square(bg: BgSquare, fg: FgSquare)
}

pub fn init(level_number: Int) -> Board {
  let tile_size = 40
  let parsed = level_gen.get(level_number)
  let level = parsed |> get_level
  let snek = player.init(parsed.snek_init, parsed.snek_dir)
  let #(tail_pos, tail_count) = player.tail(snek)

  let w = level.w
  let h = level.h
  let grid =
    all_pos(w, h)
    |> list.map(fn(p) {
      case list.contains(parsed.walls, p) {
        True -> #(p, Square(fg: FgWall, bg: BgEmpty))
        False ->
          case tail_pos == p {
            True -> #(p, Square(bg: BgEmpty, fg: FgSnakeTail(tail_count)))
            False ->
              case player.body_contains(snek, p) {
                True -> #(p, Square(bg: BgEmpty, fg: FgSnakeBody))
                False -> #(p, Square(bg: BgEmpty, fg: FgEmpty))
              }
          }
      }
    })
    |> dict.from_list
    |> init_food(w, h)
    |> add_exit(parsed.exit_pos)

  Board(level, grid, snek, Exit(parsed.exit_pos, 10), tile_size)
}

pub fn update(board: Board) -> #(Board, player.Result) {
  let exit = case board.exit {
    Exit(_, _) -> None
    ExitTimer(pos, _) -> Some(pos)
  }
  let result =
    player.move(
      board.snek,
      set.from_list(food(board)),
      walls(board),
      exit,
      board.level.w,
      board.level.h,
    )
  let score_increase = case result.died, result.ate {
    False, True -> {
      sound.play(sound.Eat)
      1
    }
    _, _ -> 0
  }
  let grid = update_food(board.grid, board.level.w, board.level.h)
  let #(tail_pos, tail_count) = player.tail(result.snek)
  let grid =
    dict.map_values(grid, fn(pos, square) {
      case pos == tail_pos {
        True -> Square(..square, fg: FgSnakeTail(tail_count))
        False -> {
          case player.body_contains(result.snek, pos) {
            True -> Square(..square, fg: FgSnakeBody)
            False -> square
          }
        }
      }
    })
  #(
    Board(
      ..board,
      grid: grid,
      snek: result.snek,
      exit: update_exit(board.exit, board.level, score_increase),
      level: board.level,
    )
      |> update_walls,
    result,
  )
}

fn add_exit(g: Grid, pos: Pos) -> Grid {
  dict.update(g, pos, fn(o) {
    case o {
      Some(square) -> Square(..square, bg: BgExit)
      _ -> Square(fg: FgEmpty, bg: BgEmpty)
    }
  })
}

fn init_food(g: Grid, w: Int, h: Int) -> Grid {
  let f = Pos(int.random(w), int.random(h))
  case dict.get(g, f) {
    Ok(square) ->
      case square {
        Square(fg: FgEmpty, bg: BgEmpty)
        | Square(fg: FgEmpty, bg: BgWallSpawn(_)) ->
          dict.insert(g, f, Square(..square, fg: FgFood))
        _ -> init_food(g, w, h)
      }
    Error(_) ->
      panic as {
        "illegal grid does not contain "
        <> int.to_string(w)
        <> "x"
        <> int.to_string(h)
      }
  }
}

fn update_food(grid: Grid, w: Int, h: Int) -> Grid {
  case int.random(5) {
    0 -> {
      let p = random_pos(w, h)
      case dict.get(grid, p) {
        Ok(square) ->
          case square {
            Square(fg: FgEmpty, bg: BgEmpty)
            | Square(fg: FgEmpty, bg: BgWallSpawn(_)) ->
              dict.insert(grid, p, Square(..square, fg: FgFood))
            _ -> grid
          }
        _ -> grid
      }
    }
    _ -> grid
  }
}

fn random_pos(w: Int, h: Int) -> Pos {
  Pos(int.random(w), int.random(h))
}

pub fn next_level(b: Board) -> Board {
  init(b.level.number + 1)
}

pub fn level_score(b: Board) -> Int {
  b.level.score
}

pub fn exit_info(b: Board) -> ExitInfo {
  get_exit_info(b.exit.pos, b.level.w, b.level.h)
}

const abs = int.absolute_value

fn distance(p1: Pos, p2: Pos) -> Int {
  abs(p1.x - p2.x) + abs(p1.y - p2.y)
}

fn update_exit(exit: Exit, lvl: Level, increase: Int) -> Exit {
  let increased = increase > 0
  let to_unlock = case exit, increased {
    Exit(_, to_unlock), True -> to_unlock - 1
    _, _ -> 0
  }
  let exit_revealed = to_unlock <= 0
  case increased {
    True -> {
      case exit, exit_revealed {
        // TODO: base init timer on distance of snake to exit
        Exit(p, _), True -> {
          sound.play(sound.DoorOpen)
          ExitTimer(pos: p, timer: time_to_escape(lvl))
        }
        Exit(p, _), False -> Exit(p, to_unlock)
        ExitTimer(p, t), _ -> ExitTimer(p, t - 1)
      }
    }
    False -> {
      case exit {
        ExitTimer(p, t) -> ExitTimer(p, t - 1)
        e -> e
      }
    }
  }
}

fn update_walls(b: Board) -> Board {
  case b.exit {
    ExitTimer(exit, t) if t < 0 -> {
      let w = b.level.w
      let h = b.level.h
      let body = b.snek.body
      let walls = walls(b)

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
        Some(wall) -> {
          let new_grid =
            dict.update(b.grid, wall, fn(o) {
              case o {
                Some(square) -> Square(..square, fg: FgWall)
                None -> Square(fg: FgWall, bg: BgEmpty)
              }
            })
          Board(..b, grid: new_grid)
        }
        None -> b
      }
    }
    _ -> b
  }
}

fn time_to_escape(lvl: Level) -> Int {
  lvl.w + lvl.h
}

pub type Orientation {
  Horizontal
  Vertical
}

pub type ExitInfo {
  ExitInfo(pos: Pos, wall: Pos, orientation: Orientation)
}

pub fn get_exit_info(p: Pos, w: Int, h: Int) -> ExitInfo {
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

pub fn exit_countdown(e: Exit) -> Int {
  case e {
    Exit(_, to_unlock) -> to_unlock
    _ -> 0
  }
}
