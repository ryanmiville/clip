import clip/internal/state.{type State}
import gleam/list
import validated.{type Validated, Invalid, Valid}
import validated as v

pub type Parser(ok, error, state) =
  fn(state) -> #(state, Validated(ok, error))

pub type ParseResult(a) =
  #(State, Validated(a, String))

pub fn do(
  first_do: Parser(a, error, state),
  and_then: fn(Validated(a, error)) -> Parser(b, error, state),
) -> Parser(b, error, state) {
  fn(state) {
    let #(state, result) = first_do(state)
    and_then(result)(state)
  }
}

pub fn pure(value: ok) -> Parser(ok, error, state) {
  fn(state) { #(state, Valid(value)) }
}

pub fn next(
  first_try: Parser(a, error, state),
  and_then: fn(a) -> Parser(b, error, state),
) -> Parser(b, error, state) {
  use va <- do(first_try)
  let a = v.unwrap(va)
  use vb <- do(and_then(a))
  case va, vb {
    Valid(_), _ -> return(vb)
    Invalid(_, e1), Valid(b) -> return(Invalid(b, e1))
    Invalid(_, e1), Invalid(default, e2) ->
      return(Invalid(default, list.append(e1, e2)))
  }
}

pub fn return(validated: Validated(ok, error)) -> Parser(ok, error, state) {
  fn(state) { #(state, validated) }
}
