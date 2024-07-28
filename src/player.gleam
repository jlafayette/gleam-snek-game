import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/set.{type Set}
import position.{type Move, type Pos, Pos}

pub type Snek {
  Snek(body: List(Pos), input: Input, dir: Move, food: Int)
}

pub fn init(p: Pos, dir: Move) -> Snek {
  Snek(body: [p, p, p], input: None, dir: dir, food: 0)
}

pub fn head(snek: Snek) -> Pos {
  case snek.body {
    [head, ..] -> head
    _ -> panic as "Snek has no head"
  }
}

fn neck(snek: Snek) -> Pos {
  case snek.body {
    [_, neck, ..] -> neck
    _ -> panic as "Snek has no neck"
  }
}

pub fn tail(snek: Snek) -> #(Pos, Int) {
  r_tail(#(Pos(-1, -1), 0), snek.body)
}

fn r_tail(acc: #(Pos, Int), body: List(Pos)) -> #(Pos, Int) {
  let #(p, n) = acc
  case body {
    [t, ..rest] ->
      case p == t {
        True -> r_tail(#(p, n + 1), rest)
        False -> r_tail(#(t, 1), rest)
      }
    [] -> acc
  }
}

pub type Result {
  Result(snek: Snek, died: Bool, exit: Bool, ate: Bool)
}

pub fn move(
  snek: Snek,
  food: Set(Pos),
  walls: List(Pos),
  exit_pos: Option(Pos),
  w: Int,
  h: Int,
) -> Result {
  let #(head, new_input, mv_taken) = new_head(snek)
  let ate = set.contains(food, head)
  let new_snek = update(snek, head, mv_taken, ate)
  let game_over =
    check_out_of_boards(head, w, h)
    || list.contains(walls, head)
    || check_self_collide(head, snek)
  let exit = case exit_pos {
    option.Some(pos) -> pos == head
    option.None -> False
  }
  Result(
    snek: Snek(..new_snek, input: new_input),
    died: game_over,
    ate: ate,
    exit: exit,
  )
}

pub fn move_exiting(snek: Snek) -> #(Snek, Bool) {
  let body = case snek.body {
    // get around bug with drop_last
    [_pos] -> []
    _ -> drop_last(snek.body)
  }
  let new_snek = Snek(..snek, body: body)
  let done = body == []
  #(new_snek, done)
}

fn check_out_of_boards(head: Pos, w: Int, h: Int) -> Bool {
  case head {
    Pos(x, _) if x < 0 -> True
    Pos(x, _) if x >= w -> True
    Pos(_, y) if y < 0 -> True
    Pos(_, y) if y >= h -> True
    _ -> False
  }
}

pub type Input {
  None
  One(Move)
  Future(Move)
  Double(Move, Move)
}

pub fn keypress(snek: Snek, move: Move) -> Snek {
  let new = case snek.input {
    None -> One(move)
    One(prev_mv) -> Double(prev_mv, move)
    Future(mv) -> Double(mv, move)
    Double(_mv1, mv2) -> Double(mv2, move)
  }
  Snek(..snek, input: new)
}

fn new_head(snek: Snek) -> #(Pos, Input, Move) {
  case snek.input {
    None -> {
      #(position.move(head(snek), snek.dir), snek.input, snek.dir)
    }
    One(mv) -> {
      let head1 = position.move(head(snek), mv)
      case neck(snek) == head1 {
        True -> #(position.move(head(snek), snek.dir), None, snek.dir)
        False -> #(head1, None, mv)
      }
    }
    Future(mv) -> {
      let head1 = position.move(head(snek), mv)
      case neck(snek) == head1 {
        True -> #(position.move(head(snek), snek.dir), None, snek.dir)
        False -> #(head1, None, mv)
      }
    }
    Double(mv1, mv2) -> {
      let head1 = position.move(head(snek), mv2)
      case neck(snek) == head1 {
        True -> #(position.move(head(snek), mv1), Future(mv2), mv1)
        False -> #(head1, None, mv2)
      }
    }
  }
}

fn update(snek: Snek, new_head: Pos, move: Move, ate: Bool) -> Snek {
  let food = int.max(0, snek.food - 1)
  let food = case ate {
    True -> food + 2
    False -> food
  }
  case snek.food > 0 {
    True -> {
      let body = snek.body
      Snek([new_head, ..body], snek.input, move, food)
    }
    False -> {
      let body = drop_last(snek.body)
      Snek([new_head, ..body], snek.input, move, food)
    }
  }
}

fn check_self_collide(head: Pos, snek: Snek) -> Bool {
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
