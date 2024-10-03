//// Functions for building `Command`s.

import clip/arg.{type Arg}
import clip/flag.{type Flag}
import clip/internal/arg_info.{type ArgInfo, ArgInfo}
import clip/internal/parser.{type ParseResult, type Parser}
import clip/internal/state.{type State, State}
import clip/opt.{type Opt}
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import validated.{Invalid, Valid}

pub opaque type Command(a) {
  Command(run: Parser(a, String, State))
}

/// The `return` function takes a value `val` and produces a `Command` that, when
/// run, produces `val`. You should only call this function directly when your
/// command doesn't require any arguments. Otherwise, use `clip.command`.
///
/// ```gleam
///  clip.return(1) |> clip.run(["whatever"])
///
///  // Ok(1)
/// ```
///
/// See the [subcommand example](https://github.com/drewolson/clip/tree/main/examples/subcommand)
/// for idiomatic usage of `return`.
pub fn return(val: a) -> Command(a) {
  Command(parser.pure(val))
}

/// The `param` function provides an alternative syntax for building curried
/// functions. The following two code blocks are equivalent:
///
/// ```gleam
/// fn(a) {
///   fn(b) {
///     thing(a, b)
///   }
/// }
/// ```
///
/// ```gleam
/// {
///   use a <- clip.param
///   use b <- clip.param
///
///   thing(a, b)
/// }
/// ```
///
/// You can use either style when calling `clip.command`.
/// See the [param syntax example](https://github.com/drewolson/clip/tree/main/examples/param-syntax)
/// for more details.
pub fn param(f: fn(a) -> b) -> fn(a) -> b {
  f
}

/// Don't call this function directly. Rather, call `cli.opt`, `clip.flag`,
/// `clip.arg`, `clip.arg_many`, or `clip.arg_many1`.
// pub fn apply(mf: Command(fn(a) -> b), ma: Command(a)) -> Command(b) {
//   Command(info: arg_info.merge(mf.info, ma.info), f: fn(args) {
//     use #(f, args1) <- result.try(mf.f(args))
//     use #(a, args2) <- result.try(ma.f(args1))
//     Ok(#(f(a), args2))
//   })
// }

/// The `command` function is use to start building a parser. You provide a
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
// pub fn command(f: fn(a) -> b) -> Command(fn(a) -> b) {
//   return(f)
// }

/// Creates a `Command` that always produces `Error(message)` when run.
// pub fn fail(message: String) -> Command(a) {
//   Command(info: arg_info.empty(), f: fn(_args) { Error(message) })
// }

fn to_command(
  arg_type: arg_type,
  to_arg_info: fn(arg_type) -> ArgInfo,
  run: fn(arg_type, State) -> ParseResult(a),
) -> Command(a) {
  Command(fn(state: State) {
    let info = arg_info.merge(state.info, to_arg_info(arg_type))
    let state = State(..state, info:)
    let #(new_state, val) = run(arg_type, state)
    case val {
      Valid(a) -> #(new_state, Valid(a))
      Invalid(default, errors) -> #(new_state, Invalid(default, errors))
    }
  })
}

fn do_next(first: Command(a), next: fn(a) -> Command(b)) -> Command(b) {
  Command({
    use a <- parser.next(first.run)
    next(a).run
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
///
/// `arg` will not attempt to parse options starting with `-` unless the
/// special `--` value has been previously passed or the option is a negative
/// integer or float.
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
///
/// `arg_many` will not attempt to parse options starting with `-` unless the
/// special `--` value has been previously passed or the option is a negative
/// integer or float.
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
///
/// `arg_many1` will not attempt to parse options starting with `-` unless the
/// special `--` value has been previously passed or the option is a negative
/// integer or float.
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
  state: State,
) -> ParseResult(a) {
  let State(args, info) = state
  case subcommands, args {
    [#(name, command), ..], [head, ..rest] if name == head ->
      command.run(State(rest, info))
    [_, ..rest], _ -> run_subcommands(rest, default, state)
    [], _ -> #(state, Invalid(default, ["no subcommands provided."]))
  }
}

/// Build a command with subcommands and a default top-level command if no
/// subcommand matches. This is an advanced use case, see the examples directory
/// for more help.
fn run_subcommands_with_default(
  subcommands: List(#(String, Command(a))),
  default: Command(a),
  state: State,
) -> ParseResult(a) {
  let State(args, info) = state
  case subcommands, args {
    [#(name, command), ..], [head, ..rest] if name == head ->
      command.run(State(rest, info))
    [_, ..rest], _ -> run_subcommands_with_default(rest, default, state)
    [], _ -> default.run(state)
  }
}

pub fn subcommands_with_default(
  subcommands: List(#(String, Command(a))),
  default: Command(a),
) -> Command(a) {
  Command(fn(state) {
    run_subcommands_with_default(subcommands, default, state)
  })
}

/// Build a command with subcommands. This is an advanced use case, see the
/// examples directory for more help.
pub fn subcommands(subcommands: List(#(String, Command(a)))) -> Command(a) {
  let assert Ok(#(_, cmd)) = list.first(subcommands)
  Command(fn(state) {
    let default =
      Command(fn(inner) {
        let #(_, val) = cmd.run(inner)
        #(state, Invalid(validated.unwrap(val), ["no subcommands provided."]))
      })
    run_subcommands_with_default(subcommands, default, state)
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
        arg_info.FlagInfo(
          name: "help",
          short: Some("h"),
          help: Some("Print this help"),
        ),
      ],
    )

  Command(fn(state) {
    let State(args, _) = state
    let #(state, val) = command.run(State(..state, rest: [""]))

    case args {
      ["-h", ..] | ["--help", ..] -> {
        #(
          state,
          Invalid(validated.unwrap(val), [
            arg_info.help_text(
              arg_info.merge(state.info, help_info),
              name,
              description,
            ),
          ]),
        )
      }
      _ -> command.run(state)
    }
  })
}

/// Run a command. Running a `Command(a)` will return either `Ok(a)` or an
/// `Error(String)`. The `Error` value is intended to be printed to the user.
pub fn run(command: Command(a), args: List(String)) -> Result(a, String) {
  let state = State(args, arg_info.empty())
  let #(_, validated) = command.run(state)
  validated.to_result(validated)
  |> result.map_error(string.join(_, "\n"))
}
