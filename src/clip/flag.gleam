//// Functions for building `Flag`s. A `Flag` is a named option with no
//// associated value, such as `--debug`. A `Flag` produces `True` when present
//// and `False` when not present.

import clip
import clip/internal/flag as internal

pub type Flag =
  clip.Flag

/// Add help text to a `Flag`.
pub fn help(flag: Flag, help: String) -> Flag {
  internal.help(flag, help)
}

/// Create a new `Flag` with the provided name. `Flag`s always produce a `Bool`
/// -- `True` if present and `False` if not present.
pub fn new(name: String) -> Flag {
  internal.new(name)
}

/// Add a short name for the given `Flag`. Short names are provided at the
/// command line with a single `-` as a prefix.
///
/// ```gleam
///   clip.command(fn(a) { a })
///   |> clip.flag(flag.new("debug") |> flag.short("d"))
///   |> clip.run(["-d"])
///
/// // Ok(True)
/// ```
pub fn short(flag: Flag, short: String) -> Flag {
  internal.short(flag, short)
}
