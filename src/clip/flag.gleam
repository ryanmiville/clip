//// Functions for building `Flag`s. A `Flag` is a named option with no
//// associated value, such as `--debug`. A `Flag` produces `True` when present
//// and `False` when not present.

import clip/internal/aliases.{type Args, type FnResult}
import clip/internal/arg_info.{type ArgInfo, ArgInfo, FlagInfo}
import clip/internal/errors.{type ClipError}
import clip/internal/state.{type State, State}
import clip/internal/validated.{type Validated, Validated}
import clip/internal/validated as v
import gleam/option.{type Option, None, Some}
import gleam/result

pub opaque type Flag {
  Flag(name: String, help: Option(String), short: Option(String))
}

/// Used internally, not intended for direct usage.
pub fn to_arg_info(flag: Flag) -> ArgInfo {
  ArgInfo(
    ..arg_info.empty(),
    flags: [FlagInfo(name: flag.name, short: flag.short, help: flag.help)],
  )
}

/// Add help text to a `Flag`.
pub fn help(flag: Flag, help: String) -> Flag {
  Flag(..flag, help: Some(help))
}

/// Create a new `Flag` with the provided name. `Flag`s always produce a `Bool`
/// -- `True` if present and `False` if not present.
pub fn new(name: String) -> Flag {
  Flag(name:, help: None, short: None)
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
  Flag(..flag, short: Some(short))
}

/// Run a `Flag` against a list of arguments. Used internally by `clip`, not
/// intended for direct usage.
pub fn run(flag: Flag, args: Args) -> FnResult(Bool) {
  let long_name = "--" <> flag.name
  let short_name = option.map(flag.short, fn(s) { "-" <> s })
  case args {
    [] -> #(False, Ok(#(False, [])))
    [head, ..rest] if long_name == head || short_name == Some(head) -> {
      #(True, Ok(#(True, rest)))
    }
    [head, ..rest] -> {
      let #(default, result) = run(flag, rest)
      let result = result |> result.map(fn(v) { #(v.0, [head, ..v.1]) })
      #(default, result)
    }
  }
}

pub fn run_state(
  flag: Flag,
  state: State,
) -> #(State, Validated(Bool, ClipError)) {
  let long_name = "--" <> flag.name
  let short_name = option.map(flag.short, fn(s) { "-" <> s })
  let State(args, info) = state
  case args {
    [] -> #(state, v.valid(False))
    [head, ..rest] if long_name == head || short_name == Some(head) -> {
      #(State(rest, info), v.valid(True))
    }
    [head, ..rest] -> {
      let #(State(new_args, new_info), validated) =
        run_state(flag, State(rest, info))
      #(State([head, ..new_args], new_info), validated)
    }
  }
}
