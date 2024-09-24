//// Functions for building `Command`s.

import clip/arg.{type Arg}
import clip/flag.{type Flag}
import clip/internal/aliases.{type Args, type FnResult}
import clip/internal/arg_info.{type ArgInfo, ArgInfo, FlagInfo}
import clip/internal/errors.{Help, NoSubcommandsProvided}
import clip/internal/validated.{type Validated, Validated}
import clip/internal/validator.{type Validator, Validator}
import clip/opt.{type Opt}
import gleam/list
import gleam/option.{Some}

pub type ClipError =
  errors.ClipError

pub type ClipErrors =
  errors.ClipErrors

pub type State(a) {
  State(value: a, info: ArgInfo, rest: Args)
}

pub type Command(a) =
  Validator(Args, State(a), ClipError)

// pub opaque type Command(a) {
//   Command(info: ArgInfo, f: ArgsFn(a))
// }

/// The `pure` function takes a value `a` and produces a `Command` that, when /
/// run, produces `a`. You shouldn't call this function directly, but rather use
/// `clip.command`.
///
/// ```gleam
///  clip.pure(1) |> clip.run(["whatever"])
///
///  // Ok(1)
/// ```
pub fn pure(val: a) -> Command(a) {
  Validator(fn(args) { validated.valid(State(val, arg_info.empty(), args)) })
}

/// Don't call this function directly. Rather, call `cli.opt`, `clip.flag`, or
/// `clip.arg`.
// pub fn apply(ma: Command(a), mf: fn(a) -> Command(b)) -> Command(b) {
//   let f = fn(args) {
//     case ma.f(args) {
//       #(_, Ok(#(ra, args1))) -> mf(ra).f(args1)
//       #(default, Error(e1)) -> {
//         let #(next_default, result) = mf(default).f(args)
//         let new_results = case result {
//           Ok(_) -> Error(e1)
//           Error(e2) -> Error(list.append(e1, e2))
//         }
//         #(next_default, new_results)
//       }
//     }
//   }
//   Command(info: ma.info, f:)
// }

pub fn combine(c1: Command(a), c2: Command(b)) {
  Validator(fn(args) {
    let v1 = c1.run(args)
    let v2 = c2.run(args)
    case v1.result, v2.result {
      Ok(a), Ok(b) -> {
        let info = arg_info.merge(a.info, b.info)
        validated.valid(#(b.value, info, b.rest))
      }
      Ok(a), Error(e) -> {
        let info = arg_info.merge(a.info, v2.default.info)
        validated.invalid(#(v2.default.value, info, a.rest), e)
      }
      Error(e), Ok(b) -> {
        let info = arg_info.merge(v1.default.info, b.info)
        validated.invalid(#(b.value, info, b.rest), e)
      }
      Error(e1), Error(e2) -> {
        let info = arg_info.merge(v1.default.info, v2.default.info)
        validated.invalid(#(v2.default.value, info, args), list.append(e1, e2))
      }
    }
  })
}

/// The `command` function is use to start building a parser. You provided a
/// curried function and then provide arguments to be supplied to that function.
///
/// ```gleam
/// clip.command(fn(a) { fn(b) { #(a, b) } })
/// |> clip.opt(opt.new("first"))
/// |> clip.opt(opt.new("second"))
/// |> clip.run(["--first", "foo", "--second", "bar"])
///
/// // Ok(#("foo", "bar"))
/// ```
pub fn command(f: fn(a) -> b) -> Command(fn(a) -> b) {
  pure(f)
}

/// Creates a `Command` that always produces `Error(message)` when run.
pub fn fail(default: a, error: ClipError) -> Command(a) {
  Validator(fn(args) {
    validated.invalid(State(default, arg_info.empty(), args), [error])
  })
}

/// Parse an option built using the `clip/opt` module and provide it to a
/// `Command` function build using `clip.command()`
///
/// ```gleam
/// clip.command(fn(a) { a })
/// |> clip.opt(opt.new("first"))
/// |> clip.run(["--first", "foo"])
///
/// // Ok("foo")
/// ```
pub fn opt(opt: Opt(a), next: fn(a) -> Command(b)) -> Command(b) {
  to_command(opt, opt.to_arg_info, opt.run)
  |> do_next(next)
}

fn do_next(first: Command(a), next: fn(a) -> Command(b)) -> Command(b) {
  use a <- validator.try(first)
  Validator(fn(_) {
    case next(a.value).run(a.rest) {
      Validated(_, Ok(State(value, info, rest))) ->
        validated.valid(State(value, arg_info.merge(a.info, info), rest))
      Validated(State(value, info, _), Error(errors)) ->
        validated.invalid(
          State(value, arg_info.merge(a.info, info), a.rest),
          errors,
        )
    }
  })
}

fn to_command(
  arg_type: arg_type,
  to_arg_info: fn(arg_type) -> ArgInfo,
  run: fn(arg_type, Args) -> FnResult(a),
) -> Command(a) {
  Validator(fn(args) {
    let info = to_arg_info(arg_type)
    let #(a, result) = run(arg_type, args)
    case result {
      Ok(#(a, rest)) -> validated.valid(State(a, info, rest))
      Error(errors) -> validated.invalid(State(a, info, args), errors)
    }
  })
}

/// Parse the next positional argument built using the `clip/arg` module and
/// provide it to a `Command` function build using `clip.command()`
///
/// ```gleam
/// clip.command(fn(a) { a })
/// |> clip.arg(arg.new("foo"))
/// |> clip.run(["foo"])
///
/// // Ok("foo")
/// ```
pub fn arg(arg: Arg(a), next: fn(a) -> Command(b)) -> Command(b) {
  to_command(arg, arg.to_arg_info, arg.run)
  |> do_next(next)
}

/// Parse the next zero or more positional arguments built using the `clip/arg`
/// module and provide them as a `List` to a `Command` function build using
/// `clip.command()`. `arg_many` is greedy, parsing as many options as possible
/// until parsing fails. If zero values are parsed successfuly, an empty
/// `List` is provided.
///
/// ```gleam
/// clip.command(fn(a) { a })
/// |> clip.arg_many(arg.new("foo"))
/// |> clip.run(["foo", "bar", "baz"])
///
/// // Ok(["foo", "bar", "baz"])
/// ```
pub fn arg_many(arg: Arg(a), next: fn(List(a)) -> Command(b)) -> Command(b) {
  to_command(arg, arg.to_arg_info_many, arg.run_many)
  |> do_next(next)
}

/// Parse the next one or more positional arguments built using the `clip/arg`
/// module and provide them as a `List` to a `Command` function build using
/// `clip.command()`. `arg_many` is greedy, parsing as many options as possible
/// until parsing fails. Parsing fails if zero values are parsed successfully.
///
/// ```gleam
/// clip.command(fn(a) { a })
/// |> clip.arg_many1(arg.new("foo"))
/// |> clip.run(["foo", "bar", "baz"])
///
/// // Ok(["foo", "bar", "baz"])
/// ```
pub fn arg_many1(arg: Arg(a), next: fn(List(a)) -> Command(b)) -> Command(b) {
  to_command(arg, arg.to_arg_info_many1, arg.run_many1)
  |> do_next(next)
}

/// Parse a flag built using the `clip/flag` module and provide it to a
/// `Command` function build using `clip.command()`
///
/// ```gleam
/// clip.command(fn(a) { a })
/// |> clip.flag(flag.new("foo"))
/// |> clip.run(["--foo"])
///
/// // Ok(True)
/// ```
pub fn flag(flag: Flag, next: fn(Bool) -> Command(a)) -> Command(a) {
  to_command(flag, flag.to_arg_info, flag.run)
  |> do_next(next)
}

fn run_subcommands(
  subcommands: List(#(String, Command(a))),
  default: a,
  args: Args,
) -> FnResult(a) {
  case subcommands, args {
    [#(name, command), ..], [head, ..rest] if name == head ->
      do_run(command, rest)
    [_, ..rest], _ -> run_subcommands(rest, default, args)
    [], _ -> #(default, errors.fail(NoSubcommandsProvided))
  }
}

fn run_subcommands_with_default(
  subcommands: List(#(String, Command(a))),
  default: Command(a),
  args: Args,
) -> Validated(State(a), ClipError) {
  case subcommands, args {
    [#(name, command), ..], [head, ..rest] if name == head -> command.run(rest)
    [_, ..rest], _ -> run_subcommands_with_default(rest, default, args)
    [], _ -> default.run(args)
  }
}

fn do_run(command: Command(a), args: Args) -> FnResult(a) {
  let validated = command.run(args)
  case validated.result {
    Ok(State(a, _, rest)) -> #(a, Ok(#(a, rest)))
    Error(errors) -> #(validated.default.value, Error(errors))
  }
}

/// Build a command with subcommands and a default top-level command if no
/// subcommand matches. This is an advanced use case, see the examples directory
/// for more help.
pub fn subcommands_with_default(
  subcommands: List(#(String, Command(a))),
  default: Command(a),
) -> Command(a) {
  Validator(fn(args) {
    let sub_names = list.map(subcommands, fn(p) { p.0 })
    let vd = default.run(args)
    let info = case vd.result {
      Ok(a) -> a.info
      _ -> vd.default.info
    }
    let sub_arg_info = ArgInfo(..info, subcommands: sub_names)
    let default =
      validator.map(default, fn(a) { State(a.value, sub_arg_info, a.rest) })
    run_subcommands_with_default(subcommands, default, args)
  })
}

/// Build a command with subcommands. This is an advanced use case, see the
/// examples directory for more help.
pub fn subcommands(subcommands: List(#(String, Command(a)))) -> Command(a) {
  let assert Ok(#(_, cmd)) = list.first(subcommands)
  Validator(fn(args) {
    let default =
      Validator(fn(args) {
        let Validated(default_value, _) = cmd.run(args)
        validated.invalid(default_value, [NoSubcommandsProvided])
      })
    run_subcommands_with_default(subcommands, default, args)
  })
}

/// Add the help (`-h`, `--help`) flags to your program to display usage help
/// to the user. The provided `name` and `description` will be used to generate
/// the help text.
pub fn add_help(
  command: Command(a),
  name: String,
  description: String,
) -> Command(a) {
  let help_info =
    ArgInfo(
      ..arg_info.empty(),
      flags: [
        FlagInfo(name: "help", short: Some("h"), help: Some("Print this help")),
      ],
    )

  Validator(fn(args) {
    let default = command.run([""]).default
    case args {
      ["-h", ..] | ["--help", ..] -> {
        validated.invalid(default, [
          Help(arg_info.help_text(
            arg_info.merge(default.info, help_info),
            name,
            description,
          )),
        ])
      }
      other -> command.run(other)
    }
  })
}

/// Run a command. Running a `Command(a)` will return either `Ok(a)` or an
/// `Error(String)`. The `Error` value is intended to be printed to the user.
pub fn run(command: Command(a), args: List(String)) -> Result(a, ClipErrors) {
  case command.run(args).result {
    Ok(a) -> Ok(a.value)
    Error(e) -> Error(e)
  }
}

pub fn error_message(errors: ClipErrors) -> String {
  errors.to_error_message(errors)
}
