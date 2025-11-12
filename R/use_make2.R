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
#'
#' @return Invisibly returns the path to the created Makefile.
#'
#' @importFrom utils file.edit
#' @export
#'
#' @examples
#' \dontrun{
#' # Create Makefile in current package
#' use_make2()
#'
#' # Create without opening
#' use_make2(open = FALSE)
#' }
use_make2 <- function(open = interactive()) {
  # Check if we're in a package project
  if (!file.exists("DESCRIPTION")) {
    stop(
      "Could not find DESCRIPTION file. ",
      "Are you in an R package directory?",
      call. = FALSE
    )
  }

  # Path to template and destination
  template_path <- system.file(
    "templates", "Makefile",
    package = "fmisc",
    mustWork = TRUE
  )
  dest_path <- "Makefile"

  # Check if Makefile already exists
  if (file.exists(dest_path)) {
    message("Makefile already exists. Overwrite? (y/N): ")
    response <- tolower(trimws(readline()))
    if (response != "y") {
      message("Aborted. Makefile not modified.")
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
    file.edit(dest_path)
  }

  invisible(dest_path)
}
