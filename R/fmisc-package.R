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
#' @section Function Decorators:
#' A composable toolkit of "function operators" for cross-cutting concerns:
#' [with_retry()], [with_timing()], [with_logging()], [with_cache()], and
#' [with_rate_limit()]. Wrappers stack with the native pipe or via
#' [decorate()], and can be inspected with [is_decorated()] and
#' [undecorate()].
#'
#' @section Dependency Injection:
#' [di_container()] provides a lightweight, closure-based DI container
#' with auto-wiring by formal argument name, singleton/transient/value
#' lifecycles, child scopes, and test-time overrides via
#' [with_di_overrides()].
#'
#' @section Custom Linting Rules:
#' The package provides custom flir rules available in the package installation
#' directory and can be accessed via [get_flir_rules()].
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
