# Package initialization

#' @useDynLib fmisc, .registration = TRUE
#' @importFrom Rcpp sourceCpp
NULL

.onAttach <- function(libname, pkgname) {
  packageStartupMessage("fmisc: Chunking Algorithm for RAM Management")
  packageStartupMessage("Use ?process_with_chunks to get started")
}
