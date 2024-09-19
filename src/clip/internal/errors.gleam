pub type ClipError =
  String

pub type ClipErrors =
  List(ClipError)

pub fn fail(message: String) -> Result(a, ClipErrors) {
  Error([message])
}
