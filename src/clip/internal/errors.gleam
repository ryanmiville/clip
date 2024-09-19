import gleam/list
import gleam/option.{type Option}
import gleam/string

pub type ClipError {
  TryMapFailed(message: String)
  MissingArgument(name: String)
  MissingOption(long_name: String, short_name: Option(String))
  EmptyArgumentList(name: String)
  NoSubcommandsProvided
  Help(text: String)
}

pub type ClipErrors =
  List(ClipError)

pub fn to_string(error: ClipError) -> String {
  case error {
    TryMapFailed(msg) -> msg
    MissingArgument(name) -> "missing required arg: " <> name
    MissingOption(long_name, short_name) -> {
      let names = short_name |> option.map(fn(s) { [s] }) |> option.unwrap([])
      let names = [long_name, ..names] |> string.join(", ")
      "missing required option: " <> names
    }
    EmptyArgumentList(name) ->
      "must provide at least one valid value for: " <> name
    NoSubcommandsProvided -> "No subcommand provided"
    Help(text) -> text
  }
}

pub fn to_error_message(errors: ClipErrors) -> String {
  errors
  |> list.map(to_string)
  |> string.join("\n")
}

pub fn fail(error: ClipError) -> Result(a, ClipErrors) {
  Error([error])
}
