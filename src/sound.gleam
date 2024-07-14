import gleam/float
import gleam/list

pub type Sound {
  Pause
  Unpause
  LevelFinished
  Eat
  HitWall
  Move
  DoorOpen
}

@external(javascript, "./sound_ffi.mjs", "playSound")
pub fn play(sound: Sound) -> Nil

pub fn lookup(sound: Sound) -> String {
  case sound {
    Pause -> "pause.mp3"
    Unpause -> "unpause.mp3"
    LevelFinished -> "level_finished.mp3"
    Eat -> {
      [
        // "eat1_num.mp3",
        // "eat2_num.mp3",
        // "eat3_num.mp3",
        "eat4_num.mp3",
        // "eat5_num.mp3",
        // "eat6_mmm.mp3",
        "eat7_tasty.mp3", "eat8_num_num_num.mp3",
      ]
      |> pick_random
    }
    HitWall -> "hit_wall.mp3"
    Move -> "move2.mp3"
    DoorOpen -> "door_open.mp3"
  }
}

// Return random 0.0 - 1.0 mapped to new range
fn random(lo: Float, hi: Float) -> Float {
  let v = float.random()
  // lo +. { v -. 0.0 } *. { hi -. lo } /. { 1.0 -. 0.0 }
  lo +. v *. { hi -. lo }
}

pub fn lookup_rate(sound: Sound) -> Float {
  case sound {
    Eat -> random(1.7, 1.9)
    LevelFinished -> 1.7
    DoorOpen -> 2.0
    _ -> random(0.95, 1.05)
  }
}

pub fn lookup_gain(sound: Sound) -> Float {
  case sound {
    Move -> 0.2
    HitWall -> 0.8
    _ -> random(0.95, 1.05)
  }
}

fn take_first(items: List(a)) -> a {
  case items {
    [first, ..] -> first
    _ -> panic as "needs at least 1 element in list"
  }
}

pub fn pick_random(items) {
  items |> list.shuffle |> take_first
}
