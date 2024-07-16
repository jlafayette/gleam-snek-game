import gleam/int
import gleam/list
import gleam/set.{type Set}
import level as level_gen
import player.{type Snek}
import position.{type Pos, Pos}

pub type Board {
  Board(level: level_gen.Level, food: Set(Pos), snek: Snek, size: Int)
}

pub fn init(level_number: Int) -> Board {
  let tile_size = 40
  let level = level_gen.get(level_number)
  Board(
    level,
    init_food([level.snek_pos, ..level.walls], level.w, level.h),
    player.init(level.snek_pos, level.snek_dir),
    tile_size,
  )
}

fn init_food(exclude: List(Pos), w: Int, h: Int) -> Set(Pos) {
  let f = Pos(int.random(w), int.random(h))
  case list.contains(exclude, f) {
    True -> init_food(exclude, w, h)
    False -> set.from_list([f])
  }
}
