import clip
import clip/arg
import clip/flag
import clip/opt
import gleam/list
import gleeunit
import gleeunit/should
import qcheck
import test_helper/qcheck_util

pub fn main() {
  gleeunit.main()
}

pub fn complex_command_test() {
  let result =
    {
      use a <- clip.opt(opt.new("a"))
      use b <- clip.flag(flag.new("b"))
      use c <- clip.arg(arg.new("c"))
      use d <- clip.arg_many(arg.new("d"))
      clip.return(#(a, b, c, d))
    }
    |> clip.run(["--a", "a", "--b", "c", "d", "e", "f"])

  result
  |> should.equal(Ok(#("a", True, "c", ["d", "e", "f"])))
}

pub fn complex_command_help_test() {
  let expected =
    "complex -- complex command

Usage:

  complex [OPTIONS] C [D...] E...

Arguments:

  C          \t
  [D...]     \tZero or more
  E...       \tOne or more

Options:

  (--a A)    \t
  [--b]      \t
  [--help,-h]\tPrint this help"

  let result =
    {
      use a <- clip.opt(opt.new("a"))
      use b <- clip.flag(flag.new("b"))
      use c <- clip.arg(arg.new("c"))
      use d <- clip.arg_many(arg.new("d"))
      use e <- clip.arg_many1(arg.new("e"))
      clip.return(#(a, b, c, d, e))
    }
    |> clip.add_help("complex", "complex command")
    |> clip.run(["--help"])

  result
  |> should.equal(Error(expected))
}

pub fn opt_and_flag_order_does_not_matter_test() {
  let argv =
    [["--a", "a"], ["--b"], ["c", "d", "e", "f"]] |> list.shuffle |> list.concat

  let result =
    {
      use a <- clip.opt(opt.new("a"))
      use b <- clip.flag(flag.new("b"))
      use c <- clip.arg(arg.new("c"))
      use d <- clip.arg_many(arg.new("d"))
      clip.return(#(a, b, c, d))
    }
    |> clip.run(argv)

  result
  |> should.equal(Ok(#("a", True, "c", ["d", "e", "f"])))
}

pub fn arg_many_accepts_all_after_double_dash_test() {
  use #(first, rest) <- qcheck_util.given(qcheck.tuple2(
    qcheck_util.clip_string(),
    qcheck.list_generic(qcheck.string_non_empty(), 2, 5),
  ))

  let result =
    {
      use a <- clip.opt(opt.new("a"))
      use b <- clip.arg_many(arg.new("b"))
      clip.return(#(a, b))
    }
    |> clip.run(["--a", first, "--", ..rest])

  result
  |> should.equal(Ok(#(first, rest)))
}

pub fn subcommands_test() {
  let command =
    clip.subcommands([
      #("a", clip.opt(opt.new("a"), clip.return)),
      #("b", clip.opt(opt.new("b"), clip.return)),
      #("c", clip.opt(opt.new("c"), clip.return)),
    ])

  command
  |> clip.run(["a", "--a", "first"])
  |> should.equal(Ok("first"))

  command
  |> clip.run(["b", "--b", "second"])
  |> should.equal(Ok("second"))

  command
  |> clip.run(["c", "--c", "third"])
  |> should.equal(Ok("third"))
}

pub fn subcommands_with_default_test() {
  let command =
    clip.subcommands_with_default(
      [
        #("a", clip.opt(opt.new("a"), clip.return)),
        #("b", clip.opt(opt.new("b"), clip.return)),
      ],
      clip.opt(opt.new("c"), clip.return),
    )

  command
  |> clip.run(["a", "--a", "first"])
  |> should.equal(Ok("first"))

  command
  |> clip.run(["b", "--b", "second"])
  |> should.equal(Ok("second"))

  command
  |> clip.run(["--c", "third"])
  |> should.equal(Ok("third"))
}
