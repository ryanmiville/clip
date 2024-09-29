//// Functions for building `Opt`s. An `Opt` is a named option with a
//// value, such as `--name "Drew"`

import clip.{type Opt}
import clip/internal/opt as internal

/// Modify the value produced by an `Opt` in a way that may fail.
///
/// ```gleam
/// opt.new("age")
/// |> opt.try_map(fn(age_str) {
///   case int.parse(age_str) {
///     Ok(age) -> Ok(age)
///     Error(Nil) -> Error("Unable to parse integer")
///   }
/// })
/// ```
///
/// Note: `try_map` can change the type of an `Opt` and therefore clears any
/// previously set default value.
pub fn try_map(opt: Opt(a), default: b, f: fn(a) -> Result(b, String)) -> Opt(b) {
  internal.try_map(opt, default, f)
}

/// Modify the value produced by an `Opt` in a way that cannot fail.
///
/// ```gleam
/// opt.new("name")
/// |> opt.map(fn(name) { string.uppercase(name) })
/// ```
///
/// Note: `map` can change the type of an `Opt` and therefore clears any
/// previously set default value.
pub fn map(opt: Opt(a), f: fn(a) -> b) -> Opt(b) {
  internal.map(opt, f)
}

/// Provide a default value for an `Opt` when it is not provided by the user.
pub fn default(opt: Opt(a), default: a) -> Opt(a) {
  internal.default(opt, default)
}

/// Transform an `Opt(a)` to an `Opt(Result(a, Nil)`, making it optional.
pub fn optional(opt: Opt(a)) -> Opt(Result(a, Nil)) {
  internal.optional(opt)
}

/// Add help text to an `Opt`.
pub fn help(opt: Opt(a), help: String) -> Opt(a) {
  internal.help(opt, help)
}

/// Create a new `Opt` with the provided name. New `Opt`s always initially
/// produce a `String`, which is the unmodified value given by the user on the
/// command line.
pub fn new(name: String) -> Opt(String) {
  internal.new(name)
}

/// Add a short name for the given `Opt`. Short names are provided at the
/// command line with a single `-` as a prefix.
///
/// ```gleam
///   clip.command(fn(a) { a })
///   |> clip.opt(opt.new("name") |> opt.short("n"))
///   |> clip.run(["-n", "Drew"])
///
/// // Ok("Drew")
/// ```
pub fn short(opt: Opt(String), short_name: String) -> Opt(String) {
  short(opt, short_name)
}

/// Modify an `Opt(String)` to produce an `Int`.
///
/// ```gleam
/// opt.new("age")
/// |> opt.int
/// ```
///
/// Note: `int` changes the type of an `Opt` and therefore clears any
/// previously set default value.
pub fn int(opt: Opt(String)) -> Opt(Int) {
  internal.int(opt)
}

/// Modify an `Opt(String)` to produce a `Float`.
///
/// ```gleam
/// opt.new("height")
/// |> opt.float
/// ```
///
/// Note: `float` changes the type of an `Opt` and therefore clears any
/// previously set default value.
pub fn float(opt: Opt(String)) -> Opt(Float) {
  internal.float(opt)
}
