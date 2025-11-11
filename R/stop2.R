simple_glue <- function(message, .envir = parent.frame()) {
  if (!grepl("\\{[^}]+\\}", message)) {
    return(message)
  }

  pattern <- "\\{([^}]+)\\}"

  repeat {
    match <- regexec(pattern, message)
    if (match[[1]][1] == -1) break

    expr_start <- match[[1]][2]
    expr_length <- attr(match[[1]], "match.length")[2]
    expr <- substr(message, expr_start, expr_start + expr_length - 1)

    value <- tryCatch({
      result <- eval(parse(text = expr), envir = .envir)

      if (length(result) > 1) {
        paste(as.character(result), collapse = ", ")
      } else if (length(result) == 0) {
        "NULL"
      } else {
        as.character(result)
      }
    }, error = function(e) {
      paste0("{", expr, "}")
    })

    full_start <- match[[1]][1]
    full_length <- attr(match[[1]], "match.length")[1]
    before <- if (full_start > 1) substr(message, 1, full_start - 1) else ""
    after <- if (full_start + full_length <= nchar(message)) {
      substr(message, full_start + full_length, nchar(message))
    } else {
      ""
    }
    message <- paste0(before, value, after)
  }

  return(message)
}

#' Stop with Better Error Messages
#'
#' A helper function that uses the best available error handling method.
#' Tries to use `cli::cli_abort()` for rich formatting, falls back to
#' `rlang::abort()` for better error handling, and ultimately uses base
#' `stop()` if neither is available.
#'
#' @details
#' This function implements a fallback mechanism for error handling:
#' \itemize{
#'   \item{If \pkg{cli} is available, uses \code{\link[cli]{cli_abort}} for rich,
#'     formatted error messages with color, styling support, and native string
#'     interpolation.}
#'   \item{If \pkg{cli} is not available but \pkg{rlang} is, uses
#'     \code{\link[rlang]{abort}} for structured error objects with better
#'     error handling capabilities.}
#'   \item{If neither package is available, falls back to base R's \code{\link[base]{stop}}
#'     with \code{call. = FALSE} to follow tidyverse style conventions.}
#' }
#'
#' String interpolation with \code{{variable}} syntax is always supported:
#' \itemize{
#'   \item{If \pkg{cli} is available, full cli interpolation and formatting
#'     features are used (including \code{{.val}}, \code{{.field}}, etc.).}
#'   \item{If \pkg{cli} is not available but \pkg{glue} is, glue's interpolation
#'     engine is used, supporting \code{{{{literal}}}} escaping.}
#'   \item{If neither package is available, a simple fallback interpolation
#'     handles basic \code{{expression}} syntax. This fallback does not support
#'     advanced features like \code{{{{literal}}}} escaping for literal braces,
#'     or cli's special formatting syntax.}
#' }
#'
#' @param message An error message string. Can include string interpolation
#'   using `{variable}` syntax which will be evaluated in `.envir`.
#' @param ... Additional arguments passed to the error function.
#' @param .envir Environment for string interpolation. Defaults to parent frame.
#' @param class Character vector of error classes (for cli and rlang).
#'
#' @return This function does not return; it stops execution with an error.
#'
#' @seealso \code{\link[cli]{cli_abort}}, \code{\link[rlang]{abort}}, \code{\link[base]{stop}}
#'
#' @examples
#' \donttest{
#' # Basic usage
#' stop2("Something went wrong")
#'
#' # With variable interpolation (works regardless of installed packages)
#' x <- 5
#' stop2("Expected value < 3, got {x}")
#'
#' # With expression interpolation
#' df <- data.frame(a = 1:3)
#' stop2("Expected 5 rows, got {nrow(df)}")
#'
#' # With multiple interpolations
#' expected <- 10
#' actual <- 5
#' stop2("Expected {expected}, got {actual}")
#'
#' # With custom error class
#' stop2("Invalid input", class = "invalid_input_error")
#' }
#'
#' @export
stop2 <- function(message,
                  ...,
                  .envir = parent.frame(),
                  class = NULL) {

  if (requireNamespace("cli", quietly = TRUE)) {
    cli::cli_abort(
      message = message,
      class = class,
      .envir = .envir,
      ...
    )
  }

  if (requireNamespace("glue", quietly = TRUE)) {
    message <- glue::glue(message, .envir = .envir)
  } else {
    message <- simple_glue(message, .envir = .envir)
  }

  if (requireNamespace("rlang", quietly = TRUE)) {
    rlang::abort(
      message = message,
      class = class,
      ...
    )
  }

  stop(message, call. = FALSE, ...)
}
