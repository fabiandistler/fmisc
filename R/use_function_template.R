#' Use the tidyverse-style function template
#'
#' @description
#' Creates a new R file based on the comprehensive function template that
#' includes best practices from the tidyverse style guide and design guide.
#' The template covers argument ordering, validation, error handling, dots usage,
#' and documentation patterns that are not automatically checked by lintr/styler.
#'
#' @details
#' The template includes:
#' * Roxygen2 documentation with best practices
#' * Argument ordering checklist (data → descriptors → ... → details)
#' * Multiple validation options (stopifnot, cli, rlang, checkmate)
#' * Dots handling patterns
#' * NULL pattern for optional arguments
#' * Side-effect functions pattern
#' * Options object pattern
#' * Error constructor pattern
#' * Comprehensive design principles checklist
#'
#' After creating the file, delete sections you don't need and customize
#' the function to your requirements.
#'
#' @param name Name of the R file to create (without .R extension).
#'   The file will be created in the R/ directory.
#' @param open Whether to open the newly created file for editing.
#'   Default is `TRUE` in interactive sessions.
#'
#' @return Invisibly returns `TRUE` if the file was created, `FALSE` otherwise.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Create a new function file from the template
#' use_function_template("my_function")
#'
#' # Create without opening
#' use_function_template("my_function", open = FALSE)
#' }
use_function_template <- function(name, open = interactive()) {
  # Sanitize the name (remove .R extension if provided)
  name <- sub("\\.R$", "", name)

  if (!grepl("^[a-zA-Z.][a-zA-Z0-9_.]*$", name) || grepl("[/\\\\]", name)) {
    cli::cli_abort(
      c(
        "{.arg name} must be a valid R identifier.",
        "x" = "{.val {name}} contains invalid characters.",
        "i" = "Use only letters, digits, dots, and underscores."
      )
    )
  }

  # Construct the save path
  save_as <- file.path("R", paste0(name, ".R"))

  # Use the template
  result <- usethis::use_template(
    template = "function_template.R",
    save_as = save_as,
    data = list(),
    ignore = FALSE,
    open = open,
    package = "fmisc"
  )

  # Success message
  cli::cli_alert_success("Created {.file {save_as}} from function template")
  cli::cli_bullets(c(
    "i" = "The template includes comprehensive best practices",
    " " = "Delete sections you don't need",
    " " = "Customize the function to your requirements"
  ))

  invisible(result)
}
