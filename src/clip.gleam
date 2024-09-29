import clip/internal/arg
import clip/internal/arg_info.{type ArgInfo, ArgInfo}
import clip/internal/errors.{Help, NoSubcommandsProvided}
import clip/internal/flag
import clip/internal/opt
import clip/internal/parser.{type ParseResult, type Parser}
import clip/internal/state.{type State, State}
import gleam/list
import gleam/option.{Some}
import validated.{Invalid, Valid}

pub type Arg(a) =
  arg.Arg(a)

pub type Flag =
  flag.Flag

pub type Opt(a) =
  opt.Opt(a)

pub type ClipError =
  errors.ClipError

pub type ClipErrors =
  errors.ClipErrors

pub opaque type Command(a) {
  Command(run: Parser(a, ClipError, State))
}

pub fn parsed(val: a) -> Command(a) {
  Command(parser.pure(val))
}

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

pub fn opt(opt: Opt(a), next: fn(a) -> Command(b)) -> Command(b) {
  to_command(opt, opt.to_arg_info, opt.run)
  |> do_next(next)
}

pub fn arg(arg: Arg(a), next: fn(a) -> Command(b)) -> Command(b) {
  to_command(arg, arg.to_arg_info, arg.run)
  |> do_next(next)
}

pub fn arg_many(arg: Arg(a), next: fn(List(a)) -> Command(b)) -> Command(b) {
  to_command(arg, arg.to_arg_info_many, arg.run_many)
  |> do_next(next)
}

pub fn arg_many1(arg: Arg(a), next: fn(List(a)) -> Command(b)) -> Command(b) {
  to_command(arg, arg.to_arg_info_many1, arg.run_many1)
  |> do_next(next)
}

pub fn flag(flag: Flag, next: fn(Bool) -> Command(a)) -> Command(a) {
  to_command(flag, flag.to_arg_info, flag.run)
  |> do_next(next)
}

pub fn subcommands_with_default(
  subcommands: List(#(String, Command(a))),
  default: Command(a),
) -> Command(a) {
  Command(fn(state: State) {
    let sub_names = list.map(subcommands, fn(p) { p.0 })
    let info = ArgInfo(..state.info, subcommands: sub_names)
    let state = State(..state, info:)
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
        #(state, Invalid(validated.unwrap(val), [NoSubcommandsProvided]))
      })
    run_subcommands_with_default(subcommands, default, state)
  })
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
    [], _ -> #(state, Invalid(default, [NoSubcommandsProvided]))
  }
}

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
            Help(arg_info.help_text(
              arg_info.merge(state.info, help_info),
              name,
              description,
            )),
          ]),
        )
      }
      _ -> command.run(state)
    }
  })
}

/// Run a command. Running a `Command(a)` will return either `Ok(a)` or an
/// `Error(String)`. The `Error` value is intended to be printed to the user.
pub fn run(command: Command(a), args: List(String)) -> Result(a, ClipErrors) {
  let state = State(args, arg_info.empty())
  let #(_, validated) = command.run(state)
  validated.to_result(validated)
}

pub fn error_message(errors: ClipErrors) -> String {
  errors.to_error_message(errors)
}
