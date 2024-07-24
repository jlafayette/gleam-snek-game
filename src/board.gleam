import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/set
import level as level_gen
import player.{type Snek}
import position.{type Pos, Pos}
import sound

pub type Grid =
  Dict(Pos, Square)

pub type Board {
  Board(level: level_gen.Level, grid: Grid, snek: Snek, size: Int)
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

fn all_pos(w: Int, h: Int) -> List(Pos) {
  list.range(0, h - 1)
  |> list.map(fn(y) {
    list.range(0, w - 1)
    |> list.map(fn(x) { Pos(x, y) })
  })
  |> list.flatten
}

type BgSquare {
  BgWall
  BgExit
  BgWallSpawn(Int)
  BgEmpty
}

type FgSquare {
  FgSnakeBody
  FgSnakeTail(Int)
  FgFood
  FgEmpty
}

pub opaque type Square {
  Square(bg: BgSquare, fg: FgSquare)
}

pub fn init(level_number: Int) -> Board {
  let tile_size = 40
  let level = level_gen.get(level_number)
  let snek = player.init(level.snek_pos, level.snek_dir)
  let #(tail_pos, tail_count) = player.tail(snek)

  let w = level.w
  let h = level.h
  let grid =
    all_pos(w, h)
    |> list.map(fn(p) {
      case list.contains(level.walls, p) {
        True -> #(p, Square(bg: BgWall, fg: FgEmpty))
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

  Board(level, grid, snek, tile_size)
}

pub fn update(board: Board) -> #(Board, player.Result) {
  let exit = case board.level.exit {
    level_gen.Exit(_, _) -> None
    level_gen.ExitTimer(pos, _) -> Some(pos)
  }
  let result =
    player.move(
      board.snek,
      set.from_list(food(board)),
      board.level.walls,
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
      level: level_gen.update(board.level, score_increase, result.snek),
    ),
    result,
  )
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

pub fn exit_info(b: Board) -> level_gen.ExitInfo {
  level_gen.exit(b.level.exit.pos, b.level.w, b.level.h)
}
