#' Smart Parallel Framework Selector
#'
#' This module provides intelligent selection and setup of R parallelization
#' frameworks based on OS capabilities and available packages.
#'
#' @author Auto-generated
#' @date 2025-11-10

#' Detect the best parallelization backend for the current environment
#'
#' @return A list containing backend information:
#'   \item{backend}{Character string identifying the backend (mclapply, parLapply, doParallel, doMC, future, foreach, sequential)}
#'   \item{os_type}{Operating system type (unix or windows)}
#'   \item{available_cores}{Number of available CPU cores}
#'   \item{packages}{List of available parallel packages}
#'
#' @examples
#' info <- detect_parallel_backend()
#' print(info$backend)
#' print(info$available_cores)
detect_parallel_backend <- function() {
  # Detect OS type
  os_type <- .Platform$OS.type

  # Get number of available cores
  available_cores <- parallel::detectCores(logical = TRUE)

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
#' @param n_cores Number of cores to use. Default is NULL (auto-detect and use all but one)
#' @param backend Force a specific backend. Default is NULL (auto-detect)
#' @param verbose Print setup information. Default is TRUE
#'
#' @return A list with cluster object (if applicable) and backend information
#'
#' @examples
#' # Auto-detect and setup
#' setup <- setup_parallel()
#'
#' # Use specific number of cores
#' setup <- setup_parallel(n_cores = 4)
#'
#' # Force specific backend
#' setup <- setup_parallel(backend = "doParallel")
setup_parallel <- function(n_cores = NULL, backend = NULL, verbose = TRUE) {
  info <- detect_parallel_backend()

  # Determine number of cores to use
  if (is.null(n_cores)) {
    # Use all cores minus 1 to keep system responsive
    n_cores <- max(1, info$available_cores - 1)
  } else {
    n_cores <- min(n_cores, info$available_cores)
  }

  # Use specified backend or auto-detected one
  selected_backend <- if (!is.null(backend)) backend else info$backend

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
#' @param setup The setup object returned by setup_parallel()
#'
#' @examples
#' setup <- setup_parallel()
#' # ... do parallel work ...
#' stop_parallel(setup)
stop_parallel <- function(setup) {
  if (!is.null(setup$cluster)) {
    parallel::stopCluster(setup$cluster)
  }

  if (setup$backend == "furrr") {
    future::plan(future::sequential)
  }

  invisible(NULL)
}


#' Universal parallel apply function
#'
#' Applies a function to elements of a vector/list using the best available
#' parallel backend automatically.
#'
#' @param X A vector or list to iterate over
#' @param FUN Function to apply to each element
#' @param n_cores Number of cores to use (NULL for auto)
#' @param ... Additional arguments passed to FUN
#' @param setup Optional pre-configured setup object from setup_parallel()
#'
#' @return A list of results
#'
#' @examples
#' # Simple parallel computation
#' result <- smart_parallel_apply(1:10, function(x) x^2)
#'
#' # With additional arguments
#' result <- smart_parallel_apply(1:10, function(x, p) x^p, p = 3)
#'
#' # Reusing setup for multiple operations
#' setup <- setup_parallel(n_cores = 4)
#' result1 <- smart_parallel_apply(1:100, sqrt, setup = setup)
#' result2 <- smart_parallel_apply(1:100, log, setup = setup)
#' stop_parallel(setup)
smart_parallel_apply <- function(X, FUN, n_cores = NULL, ..., setup = NULL) {
  # Create setup if not provided
  cleanup <- FALSE
  if (is.null(setup)) {
    setup <- setup_parallel(n_cores = n_cores, verbose = FALSE)
    cleanup <- TRUE
  }

  # Execute based on backend
  result <- tryCatch({
    if (setup$backend == "mclapply") {
      parallel::mclapply(X, FUN, ..., mc.cores = setup$n_cores)

    } else if (setup$backend == "parLapply") {
      parallel::parLapply(setup$cluster, X, FUN, ...)

    } else if (setup$backend %in% c("doMC", "doParallel", "foreach")) {
      i <- NULL  # Avoid R CMD check NOTE
      foreach::foreach(i = X, .combine = c) %dopar% {
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

  # Cleanup if we created the setup
  if (cleanup) {
    stop_parallel(setup)
  }

  result
}


#' Print parallel backend information
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
