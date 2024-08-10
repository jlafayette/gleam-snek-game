import gleam/float
import gleam/int

pub const tick_speed = 250

const late_fraction = 0.6

@external(javascript, "./time_ffi.mjs", "getTime")
pub fn get() -> Int

pub fn ms_since(t: Int) -> Int {
  get() - t
}

pub fn late(t: Int) -> Bool {
  let ms_since = get() - t
  let lower_bound = int.to_float(tick_speed) *. late_fraction |> float.round
  ms_since > lower_bound
}
