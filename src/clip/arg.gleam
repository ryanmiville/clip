//// Functions for building `Arg`s. An `Arg` is a positional option.

import clip.{type Arg}
import clip/internal/arg as internal

/// Modify the value produced by an `Arg` in a way that may fail.
///
/// ```gleam
/// arg.new("age")
/// |> arg.try_map(fn(age_str) {
///   case int.parse(age_str) {
///     Ok(age) -> Ok(age)
///     Error(Nil) -> Error("Unable to parse integer")
///   }
/// })
/// ```
///
/// Note: `try_map` can change the type of an `Arg` and therefore clears any
/// previously set default value.
pub fn try_map(arg: Arg(a), default: b, f: fn(a) -> Result(b, String)) -> Arg(b) {
  internal.try_map(arg, default, f)
}

/// Modify the value produced by an `Arg` in a way that cannot fail.
///
/// ```gleam
/// arg.new("name")
/// |> arg.map(fn(name) { string.uppercase(name) })
/// ```
///
/// Note: `map` can change the type of an `Arg` and therefore clears any
/// previously set default value.
pub fn map(arg: Arg(a), f: fn(a) -> b) -> Arg(b) {
  internal.map(arg, f)
}

/// Transform an `Arg(a)` to an `Arg(Result(a, Nil)`, making it optional.
pub fn optional(arg: Arg(a)) -> Arg(Result(a, Nil)) {
  arg |> map(Ok) |> default(Error(Nil))
}

/// Provide a default value for an `Arg` when it is not provided by the user.
pub fn default(arg: Arg(a), default: a) -> Arg(a) {
  internal.default(arg, default)
}

/// Add help text to an `Arg`.
pub fn help(arg: Arg(a), help: String) -> Arg(a) {
  internal.help(arg, help)
}

/// Modify an `Arg(String)` to produce an `Int`.
///
/// ```gleam
/// arg.new("age")
/// |> arg.int
/// ```
///
/// Note: `int` changes the type of an `Arg` and therefore clears any
/// previously set default value.
pub fn int(arg: Arg(String)) -> Arg(Int) {
  internal.int(arg)
}

/// Modify an `Arg(String)` to produce a `Float`.
///
/// ```gleam
/// arg.new("height")
/// |> arg.float
/// ```
///
/// Note: `float` changes the type of an `Arg` and therefore clears any
/// previously set default value.
pub fn float(arg: Arg(String)) -> Arg(Float) {
  internal.float(arg)
}

/// Create a new `Arg` with the provided name. New `Arg`s always initially
/// produce a `String`, which is the unmodified value given by the user on the
/// command line.
pub fn new(name: String) -> Arg(String) {
  internal.new(name)
}
