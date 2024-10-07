pub type Validated(a, e) {
  Valid(a)
  Invalid(a, List(e))
}

pub fn to_result(validated: Validated(a, e)) -> Result(a, List(e)) {
  case validated {
    Valid(a) -> Ok(a)
    Invalid(_, errors) -> Error(errors)
  }
}

pub fn unwrap(validated: Validated(a, e)) -> a {
  case validated {
    Valid(a) -> a
    Invalid(a, _) -> a
  }
}
