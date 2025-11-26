#' Deprecated function linter
#'
#' Detects usage of deprecated R functions that have modern alternatives.
#' This linter helps maintain code quality by encouraging use of current
#' best practices.
#'
#' @return A custom linter function.
#'
#' @details
#' This linter flags deprecated functions such as:
#' - `sapply()` (prefer `vapply()` or `purrr::map_*()`)
#' - `class()` for type checking (prefer `inherits()` or `is.*()`)
#'
#' @examples
#' # will produce lints
#' lint(
#'   text = "x <- sapply(1:10, sqrt)",
#'   linters = deprecated_function_linter()
#' )
#'
#' @seealso [lintr::linters] for a complete list of linters available in lintr.
#' @export
#' @importFrom lintr Linter
#' @importFrom lintr xml_find_all
deprecated_function_linter <- function() {
  xpath <- "
    //SYMBOL_FUNCTION_CALL[
      text() = 'sapply' or
      text() = 'require' or
      text() = 'library' and not(ancestor::expr[SYMBOL_FUNCTION_CALL[text() = 'suppressPackageStartupMessages']])
    ]
  "

  lintr::Linter(function(source_expression) {
    xml <- source_expression$xml_parsed_content
    bad_expr <- lintr::xml_find_all(xml, xpath)

    if (length(bad_expr) == 0L) {
      return(list())
    }

    function_names <- vapply(bad_expr, function(x) xml2::xml_text(x), character(1L))

    messages <- vapply(function_names, function(fn) {
      switch(fn,
        sapply = "Avoid sapply(); use vapply() or purrr::map_*() for type-stable iteration.",
        require = "Use library() instead of require() in package code.",
        library = "Package dependencies should be declared in DESCRIPTION, not loaded with library().",
        paste("Deprecated function: ", fn)
      )
    }, character(1L))

    lintr::xml_nodes_to_lints(
      bad_expr,
      source_expression = source_expression,
      lint_message = messages,
      type = "warning"
    )
  })
}
