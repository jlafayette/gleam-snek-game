import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/set.{type Set}

import position.{type Move, type Pos, Pos}

pub type Snek {
  Snek(body: List(Pos), input: Input, dir: Move, food: Int)
}

pub fn init(p: Pos, dir: Move) -> Snek {
  Snek(body: [p, p, p], input: InputNone, dir: dir, food: 0)
}

pub fn head(snek: Snek) -> Pos {
  case snek.body {
    [head, ..] -> head
    _ -> panic as "Snek has no head"
  }
}

pub fn get_head_safe(snek: Snek) -> Option(Pos) {
  case snek.body {
    [head, ..] -> option.Some(head)
    _ -> option.None
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

pub fn move(args: MoveArgs) -> Result {
  let snek = args.snek
  let food = args.food
  let walls = args.walls
  let exit_pos = args.exit_pos
  let w = args.w
  let h = args.h

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

pub fn move_exiting(snek: Snek, exit_wall_pos: Pos) -> #(Snek, Bool) {
  // body with dropped tail and no new head
  let body1 = case snek.body {
    // get around bug with drop_last
    [_pos] -> []
    _ -> drop_last(snek.body)
  }
  // Add head on exit wall position if it's not already there
  let maybe_head = get_head_safe(snek)
  let body2 = case maybe_head {
    option.Some(head) -> {
      case head == exit_wall_pos {
        True -> body1
        False -> {
          let maybe_valid_new_head_list =
            [position.Up, position.Down, position.Left, position.Right]
            |> list.map(fn(d) { position.move(head, d) })
            |> list.filter(fn(pos) { pos == exit_wall_pos })

          case maybe_valid_new_head_list {
            [new_head_pos, ..] -> [new_head_pos, ..body1]
            [] -> body1
          }
        }
      }
    }
    option.None -> body1
  }
  let new_snek = Snek(..snek, body: body2)
  let done = body2 == []
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
  InputNone
  Input(Move)
  InputLate(Move, Move)
}

pub type MoveArgs {
  MoveArgs(
    snek: Snek,
    food: Set(Pos),
    walls: List(Pos),
    exit_pos: Option(Pos),
    w: Int,
    h: Int,
  )
}

type SimResult {
  SimResult(is_dead: Bool)
}

fn r_simulate_moves(
  acc: SimResult,
  moves: List(Move),
  args: MoveArgs,
) -> SimResult {
  case acc.is_dead {
    True -> acc
    False ->
      case moves {
        [] -> acc
        [mv, ..rest] -> {
          let result =
            move(MoveArgs(..args, snek: Snek(..args.snek, input: Input(mv))))
          case result.died {
            True -> SimResult(is_dead: True)
            False ->
              case result.exit {
                True -> SimResult(is_dead: False)
                False -> {
                  let new_args = MoveArgs(..args, snek: result.snek)
                  r_simulate_moves(acc, rest, new_args)
                }
              }
          }
        }
      }
  }
}

fn simulate_moves(moves: List(Move), args: MoveArgs) -> SimResult {
  r_simulate_moves(SimResult(is_dead: False), moves, args)
}

fn unsafe_moves_to_input(moves: List(Move)) -> Input {
  case moves {
    [mv1, mv2] -> InputLate(mv1, mv2)
    [mv] -> Input(mv)
    _ -> panic as "Expected list of one or two moves"
  }
}

pub fn keypress(move: Move, late: Bool, args: MoveArgs) -> Snek {
  let snek = args.snek
  // simulate what would happen exactly
  // for 1 or 2 moves in the future and accept and reject
  // keyboard input based on if these moves would lead to death
  // the goal is to give a little lee-way in input timing at the
  // end of a tick (late=True)

  let new = case late {
    True -> {
      // If late=True we need to simulate the result of making the
      // new input now, vs doing the current input and then the new
      // late input on the next move
      // Even if there is no current input, we assume first move
      // as going straight for the 2 move scenario
      // If the 2 input scenario would end in death, then evaluate
      // using the new late input as the current input
      // If that wouldn't end in death, or if both end in death, then
      // ? go with the 1 input scenario since that feels more direct and
      // 'in-control' for the player

      let two_moves = case snek.input {
        InputNone -> [snek.dir, move]
        Input(mv) -> [mv, move]
        // note, we could simulate both cases here
        InputLate(mv, _mv2) -> [mv, move]
      }
      let two_result = simulate_moves(two_moves, args)
      let one_result = simulate_moves([move], args)
      let no_result = simulate_moves([snek.dir], args)

      let moves_to_use = case
        one_result.is_dead,
        two_result.is_dead,
        no_result.is_dead
      {
        False, False, _ -> two_moves
        True, False, _ -> two_moves
        False, True, _ -> [move]
        True, True, False -> [snek.dir]
        True, True, True -> [move]
      }
      unsafe_moves_to_input(moves_to_use)
    }
    False -> {
      // If late=False, nothing complicated needs to happen, just
      // accept the input if it does not collide into neck
      // this allows the player to run in the wall etc... otherwise it
      // feels like they are not in control

      let accepted = Input(move)
      let rejected = snek.input
      let neck_collide = position.move(head(snek), move) == neck(snek)
      case neck_collide {
        True -> rejected
        False -> accepted
      }
    }
  }
  Snek(..snek, input: new)
}

fn new_head(snek: Snek) -> #(Pos, Input, Move) {
  let #(dir, new_input) = case snek.input {
    InputNone -> #(snek.dir, InputNone)
    Input(mv) -> #(mv, InputNone)
    InputLate(mv1, mv2) -> #(mv1, Input(mv2))
  }
  #(position.move(head(snek), dir), new_input, dir)
}

fn input_positions_recursive(
  acc: List(Pos),
  pos: Pos,
  dirs: List(Move),
) -> List(Pos) {
  case dirs {
    [d, ..rest] -> {
      let new_pos = position.move(pos, d)
      input_positions_recursive([new_pos, ..acc], new_pos, rest)
    }
    [] -> acc
  }
}

pub fn input_positions(snek: Snek) -> List(Pos) {
  let dirs = case snek.input {
    InputNone -> [snek.dir]
    Input(mv) -> [mv]
    InputLate(mv1, mv2) -> [mv1, mv2]
  }
  input_positions_recursive([], head(snek), dirs)
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
