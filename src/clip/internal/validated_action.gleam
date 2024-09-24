import act.{type Action, do}
import clip/internal/validated.{type Validated, Validated}
import clip/internal/validated as v
import gleam/list

pub type ValidatedAction(ok, error, state) =
  Action(Validated(ok, error), state)

/// Create an action that returns the given value wrapped in an `Ok`.
///
pub fn valid(value: ok) -> ValidatedAction(ok, error, state) {
  fn(state) { #(state, v.valid(value)) }
}

/// Create an action that returns the given value wrapped in an `Error`.
///
pub fn invalid(
  default: ok,
  errors: List(error),
) -> ValidatedAction(ok, error, state) {
  fn(state) { #(state, v.invalid(default, errors)) }
}

/// Transform the value produced by an action with the given function if it is
/// wrapped in an `Ok`, returning the `Error` otherwise.
///
pub fn map(
  action: ValidatedAction(a, error, state),
  f: fn(a) -> b,
) -> ValidatedAction(b, error, state) {
  fn(state) {
    let #(state, validated) = action(state)

    case validated {
      Validated(_, Ok(a)) -> #(state, v.valid(f(a)))
      Validated(default, Error(e)) -> #(state, v.invalid(f(default), e))
    }
  }
}

pub fn try(
  first_try: ValidatedAction(a, error, state),
  and_then: fn(a) -> ValidatedAction(b, error, state),
) -> ValidatedAction(b, error, state) {
  use va <- do(first_try)
  let a = v.get_or_default(va)
  use vb <- do(and_then(a))
  case va.result, vb.result {
    Ok(_), _ -> act.return(vb)
    Error(e1), Ok(b) -> act.return(v.invalid(b, e1))
    Error(e1), Error(e2) ->
      act.return(v.invalid(vb.default, list.append(e1, e2)))
  }
}

pub fn try_all(
  actions: List(ValidatedAction(ok, error, state)),
) -> ValidatedAction(List(ok), error, state) {
  fn(state) {
    let #(state, val) =
      list.fold(actions, #(state, v.valid([])), fn(acc, action) {
        let #(state, Validated(default, result)) = acc

        case result, action(state) {
          Ok(vals), #(new_state, Validated(_, Ok(a))) -> #(
            new_state,
            v.valid([a, ..vals]),
          )
          Error(errors), #(new_state, Validated(_, Ok(a))) -> #(
            new_state,
            v.invalid([a, ..default], errors),
          )
          Ok(vals), #(new_state, Validated(d2, Error(errors))) -> #(
            new_state,
            v.invalid([d2, ..vals], [errors]),
          )
          Error(e1), #(new_state, Validated(d2, Error(e2))) -> #(
            new_state,
            v.invalid([d2, ..default], list.append(e1, [e2])),
          )
        }
      })
    let final = case val {
      Validated(_, Ok(oks)) -> v.valid(list.reverse(oks))
      Validated(oks, Error(errors)) -> {
        let errors = list.reverse(errors) |> list.flatten
        v.invalid(list.reverse(oks), errors)
      }
    }
    #(state, final)
  }
}

pub fn try_each(
  actions: List(ValidatedAction(ok, error, state)),
) -> ValidatedAction(Nil, error, state) {
  fn(state) {
    list.fold(actions, #(state, v.valid(Nil)), fn(acc, action) {
      let #(state, Validated(_, result)) = acc

      case result, action(state) {
        Ok(_), #(new_state, Validated(_, Ok(_))) -> #(new_state, v.valid(Nil))
        Error(errors), #(new_state, Validated(_, Ok(_))) -> #(
          new_state,
          v.invalid(Nil, errors),
        )
        Ok(_), #(new_state, Validated(_, Error(errors))) -> #(
          new_state,
          v.invalid(Nil, errors),
        )
        Error(e1), #(new_state, Validated(_, Error(e2))) -> #(
          new_state,
          v.invalid(Nil, list.append(e1, e2)),
        )
      }
    })
  }
}
