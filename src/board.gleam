import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
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

pub type Level {
  Level(number: Int, w: Int, h: Int)
}

fn get_level(parsed: level_gen.Parsed) -> Level {
  Level(number: parsed.number, w: width, h: height)
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
  FgFood
  FgWall
  FgEmpty
}

pub opaque type Square {
  Square(bg: BgSquare, fg: FgSquare)
}

pub fn init(level_number: Int) -> Board {
  let tile_size = 40
  let parsed = level_gen.get(level_number)
  let level = parsed |> get_level
  let snek = player.init(parsed.snek_init, parsed.snek_dir)

  let w = level.w
  let h = level.h
  let grid =
    all_pos(w, h)
    |> list.map(fn(p) {
      case list.contains(parsed.walls, p) {
        True -> #(p, Square(fg: FgWall, bg: BgEmpty))
        False -> #(p, Square(bg: BgEmpty, fg: FgEmpty))
      }
    })
    |> dict.from_list
    |> init_food(w, h)
    |> init_exit(parsed.exit_pos)
    |> init_wall_spawns(parsed.spawns)

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
  // add food
  let grid =
    update_food(
      board.grid,
      result.snek,
      result.ate,
      board.level.w,
      board.level.h,
    )
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

fn init_wall_spawns(g: Grid, spawns: List(Pos)) -> Grid {
  let spawn_lookup =
    spawns
    |> list.map2([0, 4, 8, 12], fn(pos, delay) { #(pos, delay) })
    |> dict.from_list
  g
  |> dict.map_values(fn(p, square) {
    case dict.get(spawn_lookup, p) {
      Ok(delay) -> Square(..square, bg: BgWallSpawn(delay))
      Error(_) -> square
    }
  })
}

fn init_exit(g: Grid, pos: Pos) -> Grid {
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

fn update_food(grid: Grid, snek: Snek, ate: Bool, w: Int, h: Int) -> Grid {
  let grid = case int.random(5) {
    0 -> {
      let p = random_pos(w, h)
      case dict.get(grid, p) {
        Ok(square) ->
          case square {
            Square(fg: FgEmpty, bg: BgEmpty)
            | Square(fg: FgEmpty, bg: BgWallSpawn(_)) -> {
              case player.body_contains(snek, p) {
                True -> grid
                False -> dict.insert(grid, p, Square(..square, fg: FgFood))
              }
            }
            _ -> grid
          }
        _ -> grid
      }
    }
    _ -> grid
  }
  // delete newly eaten food
  case ate {
    True ->
      dict.update(grid, player.head(snek), fn(o) {
        case o {
          Some(square) -> {
            case square {
              Square(fg: FgFood, bg: _) -> Square(..square, fg: FgEmpty)
              _ -> square
            }
          }
          None -> Square(fg: FgEmpty, bg: BgEmpty)
        }
      })
    False -> grid
  }
}

fn random_pos(w: Int, h: Int) -> Pos {
  Pos(int.random(w), int.random(h))
}

pub fn next_level(b: Board) -> Board {
  init(b.level.number + 1)
}

pub fn exit_info(b: Board) -> ExitInfo {
  get_exit_info(b.exit.pos, b.level.w, b.level.h)
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
    ExitTimer(_exit, t) if t < 0 -> {
      let w = b.level.w
      let h = b.level.h

      // create a list of squares to spread spawn into
      // for each spawn, if 0, then spawn in adjacent squares
      let update_grid =
        b.grid
        |> dict.to_list
        |> list.filter(fn(kv) {
          case kv.1 {
            Square(fg: FgEmpty, bg: BgWallSpawn(delay)) -> {
              delay <= 0
            }
            Square(fg: FgFood, bg: BgWallSpawn(delay)) -> {
              delay <= 0
            }
            _ -> False
          }
        })
        |> list.map(fn(kv) {
          let #(pos, square) = kv
          [
            Pos(pos.x - 1, pos.y),
            Pos(pos.x + 1, pos.y),
            Pos(pos.x, pos.y - 1),
            Pos(pos.x, pos.y + 1),
          ]
          // filter out of bounds
          |> list.filter(fn(pos) {
            pos.x >= 0 && pos.x < w && pos.y >= 0 && pos.y < h
          })
          // filter out snake body
          |> list.filter(fn(pos) { !player.body_contains(b.snek, pos) })
          |> list.map(fn(pos) { #(pos, Square(..square, bg: BgWallSpawn(9))) })
        })
        |> list.flatten
        // convert this to a dict
        |> dict.from_list

      // combine dicts
      let new_grid =
        dict.combine(b.grid, update_grid, fn(a, b) {
          case a {
            Square(fg: FgEmpty, bg: BgEmpty) -> b
            Square(fg: FgFood, bg: BgEmpty) -> Square(a.fg, bg: b.bg)
            _ -> a
          }
        })
        |> spawn_walls(b.snek)
        |> tick_down_wall_spawns
      Board(..b, grid: new_grid)
    }
    _ -> b
  }
}

fn tick_down_wall_spawns(g: Grid) -> Grid {
  dict.map_values(g, fn(_pos, square) {
    case square {
      Square(fg: _, bg: BgWallSpawn(delay)) ->
        Square(..square, bg: BgWallSpawn(int.max(0, delay - 1)))
      _ -> square
    }
  })
}

fn spawn_walls(g: Grid, snek: Snek) -> Grid {
  dict.map_values(g, fn(pos, square) {
    case square {
      Square(fg: FgEmpty, bg: BgWallSpawn(delay))
      | Square(fg: FgFood, bg: BgWallSpawn(delay)) -> {
        case delay <= 0 && !player.body_contains(snek, pos) {
          True -> Square(fg: FgWall, bg: BgWallSpawn(0))
          False -> square
        }
      }
      _ -> square
    }
  })
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

pub fn get_wall_spawns(b: Board) -> List(#(Pos, Int)) {
  dict.to_list(b.grid)
  |> list.filter(fn(kv) {
    case kv.1 {
      Square(fg: _, bg: BgWallSpawn(_)) -> True
      _ -> False
    }
  })
  |> list.map(fn(kv) {
    case kv.1 {
      Square(fg: _, bg: BgWallSpawn(delay)) -> #(kv.0, delay)
      _ -> #(kv.0, 0)
    }
  })
}
