#!/usr/bin/env Rscript
#
# Example Usage of Smart Parallel Framework
#
# This script demonstrates the various ways to use the smart parallel
# framework for R.

# Source the main file
source("smart_parallel.R")

message("\n=== Smart Parallel Framework Examples ===\n")

# Example 1: Check environment
message("Example 1: Checking parallel environment")
message("==========================================")
print_parallel_info()
message("\n")

# Example 2: Simple parallel computation
message("Example 2: Simple parallel computation")
message("========================================")
message("Computing squares of 1:20 in parallel...")
result <- smart_parallel_apply(1:20, function(x) x^2, n_cores = 2)
message(sprintf("Results: %s ...\n", paste(unlist(result[1:10]), collapse = " ")))

# Example 3: Parallel computation with timing
message("Example 3: Performance comparison")
message("==================================")

test_function <- function(x) {
  # Simulate some work
  sum(sqrt(1:10000))
  return(x^2)
}

# Sequential
message("Sequential execution: ", appendLF = FALSE)
start_time <- Sys.time()
result_seq <- lapply(1:100, test_function)
seq_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
message(sprintf("%.3f seconds", seq_time))

# Parallel
message("Parallel execution:   ", appendLF = FALSE)
start_time <- Sys.time()
result_par <- smart_parallel_apply(1:100, test_function, n_cores = 2)
par_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
message(sprintf("%.3f seconds", par_time))

speedup <- seq_time / par_time
message(sprintf("Speedup: %.2fx\n", speedup))

# Example 4: Reusing setup
message("Example 4: Reusing setup for multiple operations")
message("==================================================")
setup <- setup_parallel(n_cores = 2, verbose = TRUE)

message("Operation 1: Square roots")
result1 <- smart_parallel_apply(1:50, sqrt, setup = setup)

message("Operation 2: Natural logarithms")
result2 <- smart_parallel_apply(1:50, log, setup = setup)

message("Operation 3: Cubes")
result3 <- smart_parallel_apply(1:50, function(x) x^3, setup = setup)

stop_parallel(setup)
message("Cleanup complete\n")

# Example 5: Custom function with multiple arguments
message("Example 5: Custom function with arguments")
message("==========================================")

transform_data <- function(x, scale, shift) {
  (x * scale) + shift
}

result <- smart_parallel_apply(
  X = 1:20,
  FUN = transform_data,
  scale = 2.5,
  shift = 100,
  n_cores = 2
)

message("Transform f(x) = 2.5x + 100 for x in 1:5:")
message(sprintf("  Results: %s ...\n", paste(unlist(result[1:5]), collapse = " ")))

# Example 6: Error handling demonstration
message("Example 6: Error handling")
message("=========================")

# Function that might fail
risky_function <- function(x) {
  if (x == 5) {
    warning("Warning at x=5")
  }
  if (x > 100) {
    stop("Error: x > 100")
  }
  return(x * 2)
}

message("Processing with potential warnings...")
result <- suppressWarnings(
  smart_parallel_apply(1:10, risky_function, n_cores = 2)
)
message(sprintf("Successfully processed: %d items\n", length(result)))

message("=== All examples completed successfully! ===")
