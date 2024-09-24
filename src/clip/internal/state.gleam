import clip/internal/arg_info.{type ArgInfo}

pub type State {
  State(rest: List(String), info: ArgInfo)
}

pub fn combine(s1: State, s2: State) {
  let info = arg_info.merge(s1.info, s2.info)
  State(s2.rest, info)
}
