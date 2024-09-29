import clip/internal/arg_info.{type ArgInfo}

pub type State {
  State(rest: List(String), info: ArgInfo)
}
