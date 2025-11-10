#' @section Smart Parallel Computing:
#' The fmisc package includes a comprehensive parallel computing framework
#' that automatically selects the best backend based on your operating system
#' and available packages.
#'
#' Key function:
#' * [smart_parallel_apply()] - Universal parallel apply with automatic backend detection
#'
#' The framework supports multiple backends including mclapply, parLapply,
#' doParallel, doMC, furrr, and future, with intelligent OS-aware selection.
#'
#' @section Custom Linting Rules:
#' The package provides custom linting rules for both lintr and flir packages.
#'
#' lintr linters:
#' * [todo_fixme_linter()] - Detects TODO/FIXME comments
#' * [deprecated_function_linter()] - Identifies deprecated functions
#'
#' flir rules are available in the package installation directory and can
#' be accessed via [get_flir_rules()].
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom data.table :=
#' @importFrom data.table .BY
#' @importFrom data.table .EACHI
#' @importFrom data.table .GRP
#' @importFrom data.table .I
#' @importFrom data.table .N
#' @importFrom data.table .NGRP
#' @importFrom data.table .SD
#' @importFrom data.table data.table
#' @importFrom foreach %dopar%
#' @importFrom Rcpp sourceCpp
#' @useDynLib fmisc, .registration = TRUE
## usethis namespace: end
NULL
