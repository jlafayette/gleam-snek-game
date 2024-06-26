import position.{type Move, type Pos}

pub type Input {
  None
  One(Move)
  Future(Move)
  Double(Move, Move)
}

pub fn keypress(input: Input, move: Move) -> Input {
  todo
}

pub fn end_turn(input: Input) -> #(Input, Move) {
  todo
}
