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
#'     formatted error messages with color and styling support.}
#'   \item{If \pkg{cli} is not available but \pkg{rlang} is, uses
#'     \code{\link[rlang]{abort}} for structured error objects with better
#'     error handling capabilities.}
#'   \item{If neither package is available, falls back to base R's \code{\link[base]{stop}}
#'     with \code{call. = FALSE} to follow tidyverse style conventions.}
#' }
#'
#' @param message An error message string. Can include cli-style formatting
#'   like `{variable}` if cli is available, or glue-style formatting for rlang.
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
#' # With variable interpolation (if cli available)
#' x <- 5
#' stop2("Expected value < 3, got {x}")
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

  if (requireNamespace("rlang", quietly = TRUE)) {
    rlang::abort(
      message = message,
      class = class,
      ...
    )
  }

  stop(message, call. = FALSE, ...)
}
