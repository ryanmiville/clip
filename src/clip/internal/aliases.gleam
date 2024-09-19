import clip/internal/errors.{type ClipErrors}

pub type FnResult(a) =
  #(a, Result(#(a, List(String)), ClipErrors))

pub type Args =
  List(String)

pub type ArgsFn(a) =
  fn(Args) -> FnResult(a)
