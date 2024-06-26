pub type Pos {
  Pos(x: Int, y: Int)
}

pub type Move {
  Left
  Right
  Down
  Up
}

pub fn move(p: Pos, dir: Move) -> Pos {
  case dir {
    Left -> Pos(p.x - 1, p.y)
    Right -> Pos(p.x + 1, p.y)
    Down -> Pos(p.x, p.y + 1)
    Up -> Pos(p.x, p.y - 1)
  }
}
