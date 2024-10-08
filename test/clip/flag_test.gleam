import clip
import clip/flag
import gleeunit/should
import test_helper/qcheck_util

pub fn flag_test() {
  use value <- qcheck_util.given(qcheck_util.clip_string())

  let command = clip.flag(flag.new(value), clip.return)

  clip.run(command, ["--" <> value])
  |> should.equal(Ok(True))

  clip.run(command, [])
  |> should.equal(Ok(False))
}

pub fn short_test() {
  use value <- qcheck_util.given(qcheck_util.clip_string())

  let command = clip.flag(flag.new("flag") |> flag.short(value), clip.return)

  clip.run(command, ["-" <> value])
  |> should.equal(Ok(True))

  clip.run(command, [])
  |> should.equal(Ok(False))
}
