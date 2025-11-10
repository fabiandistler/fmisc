#' Get flir rules from fmisc package
#'
#' Returns the path to the flir rules directory in the fmisc package.
#' These rules can be used in flir/config.yml by adding fmisc to the
#' `from-package` field.
#'
#' @return Character string with the path to the rules directory.
#'
#' @details
#' To use these rules in your project, add the following to your
#' `flir/config.yml` file:
#'
#' ```yaml
#' from-package:
#'   - fmisc
#' ```
#'
#' @examples
#' \dontrun{
#' # Get the rules directory
#' get_flir_rules()
#'
#' # Use in flir
#' library(flir)
#' setup_flir()
#' # Then edit flir/config.yml to add fmisc to from-package
#' }
#'
#' @export
get_flir_rules <- function() {
  system.file("flir", "rules", package = "fmisc", mustWork = TRUE)
}
