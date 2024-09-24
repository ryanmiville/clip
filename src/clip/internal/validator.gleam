import clip/internal/validated.{type Validated, Validated}
import clip/internal/validated as v
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None}

pub type Validator(in, out, error) {
  Validator(run: fn(in) -> Validated(out, error))
}

pub fn run(validator: Validator(i, o, e), input: i) -> Validated(o, e) {
  validator.run(input)
}

pub fn to_result(validated: Validated(a, e)) -> Result(a, List(e)) {
  validated.result
}

pub fn map(validator: Validator(i, a, e), f: fn(a) -> b) -> Validator(i, b, e) {
  Validator(run: fn(input) { v.map(validator.run(input), f) })
}

pub fn try_map(
  validator: Validator(i, a, e),
  default: b,
  f: fn(a) -> Result(b, e),
) -> Validator(i, b, e) {
  Validator(run: fn(input) { v.try_map(validator.run(input), default, f) })
}

pub fn run_all(vs: List(fn(i) -> Validated(o, e)), input: i) -> Validated(o, e) {
  list.map(vs, Validator)
  |> combine_all
  |> run(input)
}

pub fn all(vs: List(fn(i) -> Validated(o, e))) -> Validator(i, o, e) {
  list.map(vs, Validator)
  |> combine_all
}

pub fn combine_all(vs: List(Validator(i, o, e))) -> Validator(i, o, e) {
  case list.reduce(vs, combine) {
    Ok(v) -> v
    Error(Nil) -> panic as "list cannot be empty"
  }
}

pub fn combine(
  v1: Validator(in, out1, error),
  v2: Validator(in, out2, error),
) -> Validator(in, out2, error) {
  Validator(run: fn(input) { v.combine(v1.run(input), v2.run(input)) })
}

pub fn try(
  first: Validator(in, a, error),
  next: fn(a) -> Validator(in, b, error),
) -> Validator(in, b, error) {
  Validator(run: fn(input) {
    case first.run(input) {
      Validated(_, Ok(a)) -> next(a).run(input)
      Validated(a, Error(e1)) -> {
        case next(a).run(input) {
          Validated(_, Ok(b)) -> v.invalid(b, e1)
          Validated(b, Error(e2)) -> v.invalid(b, list.append(e1, e2))
        }
      }
    }
  })
}

pub fn valid(value: a) -> Validator(i, a, e) {
  Validator(fn(_) { v.valid(value) })
}
