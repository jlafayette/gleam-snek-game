import gleam/option.{type Option, None, Some}

pub type Pos {
  Pos(x: Int, y: Int)
}

pub fn add(p1: Pos, p2: Pos) -> Pos {
  Pos(p1.x + p2.x, p1.y + p2.y)
}

pub fn sub(p1: Pos, p2: Pos) -> Pos {
  Pos(p1.x - p2.x, p1.y - p2.y)
}

pub fn mult(p1: Pos, p2: Pos) -> Pos {
  Pos(p1.x * p2.x, p1.y * p2.y)
}

pub fn div(p1: Pos, p2: Pos) -> Pos {
  Pos(p1.x / p2.x, p1.y / p2.y)
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

pub type Bbox {
  Bbox(x: Int, y: Int, w: Int, h: Int, dir: Option(Move))
}

pub fn to_bbox(pos: Pos, w: Int, h: Int, size: Int) -> Bbox {
  let dir = case pos {
    Pos(x, _y) if x < 0 -> Some(Left)
    Pos(x, _y) if x >= w -> Some(Right)
    Pos(_x, y) if y < 0 -> Some(Up)
    Pos(_x, y) if y >= h -> Some(Down)
    _ -> None
  }
  let x = pos.x * size
  let y = pos.y * size
  let w = size
  let h = size
  let half = size / 2
  case dir {
    Some(dir) -> {
      case dir {
        Left -> Bbox(x: x + half, y: y, w: half, h: h, dir: Some(Left))
        Right -> Bbox(x: x, y: y, w: half, h: h, dir: Some(Right))
        Up -> Bbox(x: x, y: y + half, w: w, h: half, dir: Some(Up))
        Down -> Bbox(x: x, y: y, w: w, h: half, dir: Some(Down))
      }
    }
    None -> Bbox(x, y, w, h, None)
  }
}
