#' Add a comprehensive Makefile for R package development
#'
#' @description
#' Creates a feature-rich Makefile in your package root directory with targets
#' for common R package development tasks including building, checking, testing,
#' documentation, code quality, and more.
#'
#' @details
#' Run `make help` to see available targets
#' Quick start:
#' `make all` - document, build, and check package
#' `make test` - run tests
#' `make deps-dev` - install development dependencies
#'
#' @param open Whether to open the newly created Makefile for editing.
#'   Default is `TRUE` in interactive sessions.
#' @param overwrite Whether to overwrite an existing Makefile. If `FALSE`
#'   (the default) and a Makefile already exists, you are asked for
#'   confirmation in interactive sessions; non-interactive sessions error
#'   instead of silently replacing the file.
#'
#' @return Invisibly returns the path to the created Makefile.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Create Makefile in current package
#' use_make2()
#'
#' # Create without opening
#' use_make2(open = FALSE)
#'
#' # Replace an existing Makefile without prompting
#' use_make2(overwrite = TRUE)
#' }
use_make2 <- function(open = interactive(), overwrite = FALSE) {
  # Check if we're in a package project
  if (!file.exists("DESCRIPTION")) {
    stop2("Could not find DESCRIPTION file. Are you in an R package directory?")
  }

  # Path to template and destination
  template_path <- system.file(
    "templates", "Makefile",
    package = "fmisc",
    mustWork = TRUE
  )
  dest_path <- "Makefile"

  # Check if Makefile already exists
  if (file.exists(dest_path) && !isTRUE(overwrite)) {
    if (!interactive()) {
      stop2(
        "{.file Makefile} already exists. Use {.code overwrite = TRUE} to replace it."
      )
    }
    response <- readline("Makefile already exists. Overwrite? (y/N): ")
    if (tolower(trimws(response)) != "y") {
      cli::cli_alert_info("Aborted. {.file Makefile} not modified.")
      return(invisible(dest_path))
    }
  }

  # Copy template to destination
  file.copy(template_path, dest_path, overwrite = TRUE)

  # Success message
  cli::cli_alert_success("Created {.file Makefile}")
  cli::cli_alert_info("Run {.code make help} to see available targets")
  cli::cli_bullets(c(
    "i" = "Quick start:",
    " " = "{.code make all} - document, build, and check package",
    " " = "{.code make test} - run tests",
    " " = "{.code make deps-dev} - install development dependencies"
  ))

  # Open file if requested
  if (open) {
    utils::file.edit(dest_path)
  }

  invisible(dest_path)
}
