import gleam/int
import gleam/list
import position.{type Move, type Pos, Down, Left, Pos, Right, Up}

pub type Snek {
  Snek(body: List(Pos), dir: Move, food: Int)
}

pub fn init(p: Pos, dir: Move) -> Snek {
  Snek(body: [p, p, p], dir: dir, food: 0)
}

pub fn head(snek: Snek) -> Pos {
  case snek.body {
    [head, ..] -> head
    _ -> panic as "Snek has no head"
  }
}

pub fn neck(snek: Snek) -> Pos {
  case snek.body {
    [_, neck, ..] -> neck
    _ -> panic as "Snek has no neck"
  }
}

pub fn new_head(snek: Snek, prev_mv: Move, mv: Move) -> #(Pos, Move) {
  let head1 = position.move(head(snek), mv)
  let collide = neck(snek) == head1
  case collide {
    True -> #(position.move(head(snek), prev_mv), prev_mv)
    False -> #(head1, mv)
  }
}

pub fn update(snek: Snek, new_head: Pos, move: Move, ate: Bool) -> Snek {
  let food = int.max(0, snek.food - 1)
  let food = case ate {
    True -> food + 2
    False -> food
  }
  case snek.food > 0 {
    True -> {
      let body = snek.body
      Snek([new_head, ..body], move, food)
    }
    False -> {
      let body = drop_last(snek.body)
      Snek([new_head, ..body], move, food)
    }
  }
}

pub fn check_self_collide(head: Pos, snek: Snek) -> Bool {
  let body = case snek.food > 0 {
    True -> snek.body
    False -> drop_last(snek.body)
  }
  list.contains(body, head)
}

pub fn body_contains(snek: Snek, pos: Pos) -> Bool {
  list.contains(snek.body, pos)
}

fn drop_last(xs: List(v)) -> List(v) {
  xs |> drop_last_recursive([]) |> list.reverse
}

fn drop_last_recursive(xs: List(v), acc: List(v)) -> List(v) {
  case xs {
    [x, _] -> [x, ..acc]
    [x, ..rest] -> drop_last_recursive(rest, [x, ..acc])
    _ -> acc
  }
}
