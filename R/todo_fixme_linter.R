#' TODO/FIXME comment linter
#'
#' Checks for TODO and FIXME comments in code. This linter helps identify
#' tasks that need attention and ensures they are tracked properly.
#'
#' @return A custom linter function.
#'
#' @examples
#' # will produce lints
#' lint(
#'   text = "# TODO: implement this",
#'   linters = todo_fixme_linter()
#' )
#'
#' lint(
#'   text = "# FIXME: this is broken",
#'   linters = todo_fixme_linter()
#' )
#'
#' @seealso [lintr::linters] for a complete list of linters available in lintr.
#' @export
#' @importFrom lintr make_linter_from_xpath
todo_fixme_linter <- function() {
  xpath <- "//COMMENT[
    contains(text(), 'TODO') or
    contains(text(), 'FIXME') or
    contains(text(), 'XXX') or
    contains(text(), 'HACK')
  ]"

  lintr::make_linter_from_xpath(
    xpath = xpath,
    lint_message = "TODO/FIXME/XXX/HACK comments found. Consider addressing or tracking in issue tracker.",
    type = "warning"
  )
}
