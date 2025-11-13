#' Smart Parallel Framework Selector
#'
#' This module provides intelligent selection and setup of R parallelization
#' frameworks based on OS capabilities and available packages.
#'
#' @family parallel
#' @keywords internal

#' Detect the best parallelization backend for the current environment
#'
#' @return A list containing backend information:
#'   \item{backend}{Character string identifying the backend. One of:
#'     "mclapply", "parLapply", "doParallel", "doMC", "future",
#'     "foreach", or "sequential"}
#'   \item{os_type}{Operating system type (unix or windows)}
#'   \item{available_cores}{Number of available CPU cores}
#'   \item{packages}{List of available parallel packages}
#'
#' @seealso [setup_parallel()], [smart_parallel_apply()]
#' @family parallel
#' @export
#'
#' @examples
#' # Detect available backend
#' info <- detect_parallel_backend()
#' print(info$backend)
#' print(info$available_cores)
detect_parallel_backend <- function() {
  # Detect OS type
  os_type <- .Platform$OS.type

  # Get number of available cores (handle NA case)
  available_cores <- parallel::detectCores(logical = TRUE)
  if (is.na(available_cores)) {
    available_cores <- 1  # Safe fallback
    warning("Could not detect CPU cores, defaulting to 1")
  }

  # Check for available packages
  packages <- list(
    parallel = requireNamespace("parallel", quietly = TRUE),
    foreach = requireNamespace("foreach", quietly = TRUE),
    doParallel = requireNamespace("doParallel", quietly = TRUE),
    doMC = requireNamespace("doMC", quietly = TRUE),
    future = requireNamespace("future", quietly = TRUE),
    furrr = requireNamespace("furrr", quietly = TRUE)
  )

  # Select best backend based on OS and available packages
  backend <- "sequential"

  if (os_type == "unix") {
    # Unix-like systems (Linux, macOS) - prefer fork-based parallelization
    if (packages$furrr && packages$future) {
      backend <- "furrr"
    } else if (packages$doMC && packages$foreach) {
      backend <- "doMC"
    } else if (packages$parallel) {
      backend <- "mclapply"
    } else if (packages$doParallel && packages$foreach) {
      backend <- "doParallel"
    }
  } else {
    # Windows - must use socket-based parallelization
    if (packages$furrr && packages$future) {
      backend <- "furrr"
    } else if (packages$doParallel && packages$foreach) {
      backend <- "doParallel"
    } else if (packages$parallel) {
      backend <- "parLapply"
    } else if (packages$foreach) {
      backend <- "foreach"
    }
  }

  list(
    backend = backend,
    os_type = os_type,
    available_cores = available_cores,
    packages = packages
  )
}


#' Setup parallel backend with automatic configuration
#'
#' @param n_cores Number of cores to use. Default is NULL (auto-detect and use
#'   all but one core to keep system responsive)
#' @param backend Force a specific backend. Default is NULL (auto-detect).
#'   Options: "mclapply", "parLapply", "doParallel", "doMC", "furrr",
#'   "foreach", "sequential"
#' @param verbose Print setup information. Default is TRUE
#'
#' @return A list with cluster object (if applicable) and backend information:
#'   \item{cluster}{Cluster object (or NULL if not applicable)}
#'   \item{backend}{Character string of selected backend}
#'   \item{n_cores}{Number of cores configured}
#'   \item{info}{Backend detection information}
#'
#' @seealso [detect_parallel_backend()], [stop_parallel()],
#'   [smart_parallel_apply()]
#' @family parallel
#' @export
#'
#' @examples
#' \donttest{
#' # Auto-detect and setup
#' setup <- setup_parallel()
#' stop_parallel(setup)
#'
#' # Use specific number of cores
#' setup <- setup_parallel(n_cores = 2)
#' stop_parallel(setup)
#'
#' # Force specific backend
#' setup <- setup_parallel(backend = "doParallel")
#' stop_parallel(setup)
#' }
setup_parallel <- function(n_cores = NULL, backend = NULL, verbose = TRUE) {
  info <- detect_parallel_backend()

  # Validate n_cores parameter
  if (!is.null(n_cores)) {
    if (!is.numeric(n_cores) || length(n_cores) != 1 || n_cores < 1) {
      stop(
        "n_cores must be a positive integer, got: ",
        paste(n_cores, collapse = ", "),
        call. = FALSE
      )
    }
    n_cores <- as.integer(n_cores)
  }

  # Determine number of cores to use
  if (is.null(n_cores)) {
    # Leave one core free for system responsiveness
    n_cores <- max(1, info$available_cores - 1)
  } else {
    n_cores <- min(n_cores, info$available_cores)
  }

  # Use specified backend or auto-detected one
  if (!is.null(backend)) {
    valid_backends <- c("mclapply", "parLapply", "doParallel",
                        "doMC", "furrr", "foreach", "sequential")
    if (!backend %in% valid_backends) {
      stop(
        "Invalid backend: '", backend, "'. Must be one of: ",
        paste(valid_backends, collapse = ", "),
        call. = FALSE
      )
    }
    selected_backend <- backend
  } else {
    selected_backend <- info$backend
  }

  cluster <- NULL

  # Setup based on backend
  if (selected_backend == "mclapply") {
    if (verbose) {
      message(sprintf("Using mclapply with %d cores (fork-based parallelization)", n_cores))
    }
    options(mc.cores = n_cores)

  } else if (selected_backend == "parLapply") {
    if (verbose) {
      message(sprintf("Using parLapply with %d cores (socket-based parallelization)", n_cores))
    }
    cluster <- parallel::makeCluster(n_cores, type = "PSOCK")

  } else if (selected_backend == "doMC") {
    if (verbose) {
      message(sprintf("Using doMC with %d cores (fork-based parallelization)", n_cores))
    }
    doMC::registerDoMC(cores = n_cores)

  } else if (selected_backend == "doParallel") {
    if (verbose) {
      message(sprintf("Using doParallel with %d cores (socket-based parallelization)", n_cores))
    }
    cluster <- parallel::makeCluster(n_cores)
    doParallel::registerDoParallel(cluster)

  } else if (selected_backend == "furrr") {
    if (verbose) {
      message(sprintf("Using furrr with %d cores (future-based parallelization)", n_cores))
    }
    future::plan(future::multisession, workers = n_cores)

  } else if (selected_backend == "foreach") {
    if (verbose) {
      message(sprintf("Using foreach with %d cores (sequential fallback)", n_cores))
    }
    foreach::registerDoSEQ()

  } else {
    if (verbose) {
      message("No parallel backend available, using sequential processing")
    }
  }

  list(
    cluster = cluster,
    backend = selected_backend,
    n_cores = n_cores,
    info = info
  )
}


#' Stop parallel backend and clean up resources
#'
#' @param setup The setup object returned by [setup_parallel()]
#'
#' @seealso [setup_parallel()], [smart_parallel_apply()]
#' @family parallel
#' @export
#'
#' @examples
#' \donttest{
#' setup <- setup_parallel(n_cores = 2)
#' # ... do parallel work ...
#' stop_parallel(setup)
#' }
stop_parallel <- function(setup) {
  # Validate setup parameter
  if (!is.list(setup)) {
    stop("setup must be a list returned by setup_parallel()", call. = FALSE)
  }
  if (!all(c("backend", "cluster") %in% names(setup))) {
    stop("setup must have 'backend' and 'cluster' elements", call. = FALSE)
  }

  # Clean up cluster if it exists
  if (!is.null(setup$cluster)) {
    tryCatch(
      parallel::stopCluster(setup$cluster),
      error = function(e) {
        warning("Failed to stop cluster: ", e$message, call. = FALSE)
      }
    )
  }

  # Reset future plan if using furrr
  if (!is.null(setup$backend) && setup$backend == "furrr") {
    tryCatch(
      future::plan(future::sequential),
      error = function(e) {
        warning("Failed to reset future plan: ", e$message, call. = FALSE)
      }
    )
  }

  invisible(NULL)
}


#' Universal parallel apply function
#'
#' Applies a function to elements of a vector/list using the best available
#' parallel backend automatically. This function automatically detects the best
#' parallelization method for your system and applies FUN to each element of X.
#'
#' @param X A vector or list to iterate over
#' @param FUN Function to apply to each element
#' @param n_cores Number of cores to use (NULL for auto-detection)
#' @param ... Additional arguments passed to FUN
#' @param setup Optional pre-configured setup object from [setup_parallel()].
#'   If provided, n_cores is ignored. Reusing setup is more efficient for
#'   multiple operations.
#'
#' @return A list of results
#'
#' @seealso [setup_parallel()], [detect_parallel_backend()]
#' @family parallel
#' @export
#'
#' @examples
#' # Simple parallel computation
#' result <- smart_parallel_apply(1:10, function(x) x^2)
#'
#' \donttest{
#' # With additional arguments
#' result <- smart_parallel_apply(1:10, function(x, p) x^p, p = 3)
#'
#' # Reusing setup for multiple operations (more efficient)
#' setup <- setup_parallel(n_cores = 2)
#' result1 <- smart_parallel_apply(1:100, sqrt, setup = setup)
#' result2 <- smart_parallel_apply(1:100, log, setup = setup)
#' stop_parallel(setup)
#' }
smart_parallel_apply <- function(X, FUN, n_cores = NULL, ..., setup = NULL) {
  # Create setup if not provided
  cleanup <- FALSE
  if (is.null(setup)) {
    setup <- setup_parallel(n_cores = n_cores, verbose = FALSE)
    cleanup <- TRUE
    # Ensure cleanup happens even if there's an error
    on.exit({
      if (cleanup) {
        stop_parallel(setup)
      }
    }, add = TRUE)
  }

  # Execute based on backend
  result <- tryCatch({
    if (setup$backend == "mclapply") {
      parallel::mclapply(X, FUN, ..., mc.cores = setup$n_cores)

    } else if (setup$backend == "parLapply") {
      # On Windows, we need to export variables to cluster nodes
      if (.Platform$OS.type == "windows") {
        # Export all variables from parent environment
        parallel::clusterExport(
          setup$cluster,
          varlist = ls(envir = parent.frame()),
          envir = parent.frame()
        )
      }
      parallel::parLapply(setup$cluster, X, FUN, ...)

    } else if (setup$backend %in% c("doMC", "doParallel", "foreach")) {
      i <- NULL  # Avoid R CMD check NOTE
      # Use .combine = list to ensure consistent return type
      foreach::foreach(i = X, .combine = list, .multicombine = TRUE) %dopar% {
        FUN(i, ...)
      }

    } else if (setup$backend == "furrr") {
      furrr::future_map(X, FUN, ...)

    } else {
      # Sequential fallback
      lapply(X, FUN, ...)
    }
  }, error = function(e) {
    warning(sprintf("Parallel execution failed, falling back to sequential: %s", e$message))
    lapply(X, FUN, ...)
  })

  result
}


#' Print parallel backend information
#'
#' Displays detailed information about your parallel computing environment,
#' including available CPU cores, recommended backend, and installed packages.
#'
#' @return Invisibly returns the backend detection information
#'
#' @seealso [detect_parallel_backend()]
#' @family parallel
#' @export
#'
#' @examples
#' print_parallel_info()
print_parallel_info <- function() {
  info <- detect_parallel_backend()

  message("=== Parallel Computing Environment ===")
  message(sprintf("OS Type: %s", info$os_type))
  message(sprintf("Available Cores: %d", info$available_cores))
  message(sprintf("Recommended Backend: %s", info$backend))
  message("\nAvailable Packages:")

  for (pkg in names(info$packages)) {
    status <- if (info$packages[[pkg]]) "✓" else "✗"
    message(sprintf("  %s %s", status, pkg))
  }

  message("\nBackend Priority:")
  if (info$os_type == "unix") {
    message("  1. furrr (future-based, most flexible)")
    message("  2. doMC (fork-based, fast for Unix)")
    message("  3. mclapply (fork-based, built-in)")
    message("  4. doParallel (socket-based, compatible)")
  } else {
    message("  1. furrr (future-based, most flexible)")
    message("  2. doParallel (socket-based, Windows compatible)")
    message("  3. parLapply (socket-based, built-in)")
    message("  4. foreach (sequential fallback)")
  }

  invisible(info)
}


# Example usage demonstration
if (FALSE) {
  # This code block won't run when sourced, it's just for documentation

  # Example 1: Check what's available
  print_parallel_info()

  # Example 2: Simple parallel computation
  result <- smart_parallel_apply(1:100, function(x) {
    Sys.sleep(0.1)
    x^2
  })

  # Example 3: Manual setup for multiple operations
  setup <- setup_parallel(n_cores = 4)

  result1 <- smart_parallel_apply(1:1000, sqrt, setup = setup)
  result2 <- smart_parallel_apply(1:1000, log, setup = setup)
  result3 <- smart_parallel_apply(1:1000, function(x) x^3, setup = setup)

  stop_parallel(setup)

  # Example 4: With custom function and arguments
  custom_function <- function(x, multiplier, offset) {
    (x * multiplier) + offset
  }

  result <- smart_parallel_apply(
    1:100,
    custom_function,
    multiplier = 5,
    offset = 10,
    n_cores = 2
  )
}
