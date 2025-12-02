#' fmisc: Custom Linting Rules for R Code
#'
#' @description
#' The fmisc package provides custom linting rules for both lintr and flir
#' packages. It includes ready-to-use linter functions that integrate with
#' lintr and YAML-based rules for flir automatic code fixing.
#'
#' @section lintr Custom Linters:
#' The package exports several custom linters:
#' \itemize{
#'   \item \code{\link{todo_fixme_linter}}: Detects TODO/FIXME comments
#'   \item \code{\link{deprecated_function_linter}}: Identifies deprecated functions
#' }
#'
#' @section flir Custom Rules:
#' Custom rules are available in the package installation directory and can
#' be accessed via \code{\link{get_flir_rules}}. To use them, add fmisc to
#' the \code{from-package} field in your project's \code{flir/config.yml}.
#'
#' @docType package
#' @name fmisc-package
#' @aliases fmisc
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL
