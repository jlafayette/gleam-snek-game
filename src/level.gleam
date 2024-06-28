import gleam/int
import gleam/list
import position.{type Move, type Pos, Pos, Right, Up}

pub type Level {
  Level(number: Int, snek_pos: Pos, snek_dir: Move, walls: List(Pos))
}

pub fn clamp(n: Int) -> Int {
  int.clamp(n, 1, 3)
}

pub fn get(n: Int, w: Int, h: Int) -> Level {
  case n {
    1 -> {
      Level(number: n, snek_pos: Pos(w / 3, h / 2), snek_dir: Right, walls: [])
    }
    2 -> {
      Level(number: n, snek_pos: Pos(w / 4, h / 4), snek_dir: Right, walls: {
        let wall_h = h / 2
        let gap = 3
        list.range(gap, w - gap - 1)
        |> list.map(fn(x) { Pos(x, wall_h) })
      })
    }
    3 -> {
      let gap = 2
      Level(number: n, snek_pos: Pos(w / 2, h - h / 4), snek_dir: Up, walls: {
        let wall1 = {
          let x = w / 3
          list.range(gap, h - gap - 1)
          |> list.map(fn(y) { Pos(x, y) })
        }
        let wall2 = {
          let x = w - w / 3
          list.range(gap, h - gap - 1)
          |> list.map(fn(y) { Pos(x, y) })
        }
        list.concat([wall1, wall2])
      })
    }
    _ -> get(1, w, h)
  }
}
