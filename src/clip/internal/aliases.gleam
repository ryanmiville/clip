import clip/internal/errors.{type ClipError, type ClipErrors}
import clip/internal/state.{type State}
import clip/internal/validated.{type Validated}

pub type FnResult(a) =
  #(a, Result(#(a, List(String)), ClipErrors))

pub type ParseResult(a) =
  #(State, Validated(a, ClipError))

pub type Args =
  List(String)

pub type ArgsFn(a) =
  fn(Args) -> FnResult(a)
