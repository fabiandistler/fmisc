#' Stop with Better Error Messages
#'
#' A helper function that uses the best available error handling method.
#' Tries to use `cli::cli_abort()` for rich formatting, falls back to
#' `rlang::abort()` for better error handling, and ultimately uses base
#' `stop()` if neither is available.
#'
#' @param message An error message string. Can include cli-style formatting
#'   like `{variable}` if cli is available, or glue-style formatting for rlang.
#' @param ... Additional arguments passed to the error function.
#' @param .envir Environment for string interpolation. Defaults to parent frame.
#' @param class Character vector of error classes (for cli and rlang).
#'
#' @return This function does not return; it stops execution with an error.
#'
#' @examples
#' \dontrun{
#' # Basic usage
#' stop_better("Something went wrong")
#'
#' # With variable interpolation (if cli available)
#' x <- 5
#' stop_better("Expected value < 3, got {x}")
#'
#' # With custom error class
#' stop_better("Invalid input", class = "invalid_input_error")
#' }
#'
#' @export
stop_better <- function(message,
                        ...,
                        .envir = parent.frame(),
                        class = NULL) {
  # Try cli::cli_abort first (best error messages with formatting)
  if (requireNamespace("cli", quietly = TRUE)) {
    cli::cli_abort(
      message = message,
      class = class,
      .envir = .envir,
      ...
    )
  }

  # Fall back to rlang::abort (better than base stop)
  if (requireNamespace("rlang", quietly = TRUE)) {
    rlang::abort(
      message = message,
      class = class,
      ...
    )
  }

  # Last resort: base R stop
  # Use call. = FALSE to match tidyverse style (no call in error message)
  stop(message, call. = FALSE, ...)
}
