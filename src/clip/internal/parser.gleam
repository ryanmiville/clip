import clip/internal/validated.{type Validated, Validated}
import clip/internal/validated as v
import gleam/list

pub type Parser(ok, error, state) =
  fn(state) -> #(state, Validated(ok, error))

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
  fn(state) { #(state, v.valid(value)) }
}

pub fn try(
  first_try: Parser(a, error, state),
  and_then: fn(a) -> Parser(b, error, state),
) -> Parser(b, error, state) {
  use va <- do(first_try)
  let a = v.get_or_default(va)
  use vb <- do(and_then(a))
  case va.result, vb.result {
    Ok(_), _ -> return(vb)
    Error(e1), Ok(b) -> return(v.invalid(b, e1))
    Error(e1), Error(e2) -> return(v.invalid(vb.default, list.append(e1, e2)))
  }
}

pub fn return(validated: Validated(ok, error)) -> Parser(ok, error, state) {
  fn(state) { #(state, validated) }
}
