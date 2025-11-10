#!/usr/bin/env Rscript
#
# Example Usage of Smart Parallel Framework
#
# This script demonstrates the various ways to use the smart parallel
# framework for R.

# Source the main file
source("smart_parallel.R")

cat("\n=== Smart Parallel Framework Examples ===\n\n")

# Example 1: Check environment
cat("Example 1: Checking parallel environment\n")
cat("==========================================\n")
print_parallel_info()
cat("\n\n")

# Example 2: Simple parallel computation
cat("Example 2: Simple parallel computation\n")
cat("========================================\n")
cat("Computing squares of 1:20 in parallel...\n")
result <- smart_parallel_apply(1:20, function(x) x^2, n_cores = 2)
cat("Results:", unlist(result[1:10]), "...\n\n")

# Example 3: Parallel computation with timing
cat("Example 3: Performance comparison\n")
cat("==================================\n")

test_function <- function(x) {
  # Simulate some work
  sum(sqrt(1:10000))
  return(x^2)
}

# Sequential
cat("Sequential execution: ")
start_time <- Sys.time()
result_seq <- lapply(1:100, test_function)
seq_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
cat(sprintf("%.3f seconds\n", seq_time))

# Parallel
cat("Parallel execution:   ")
start_time <- Sys.time()
result_par <- smart_parallel_apply(1:100, test_function, n_cores = 2)
par_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
cat(sprintf("%.3f seconds\n", par_time))

speedup <- seq_time / par_time
cat(sprintf("Speedup: %.2fx\n\n", speedup))

# Example 4: Reusing setup
cat("Example 4: Reusing setup for multiple operations\n")
cat("==================================================\n")
setup <- setup_parallel(n_cores = 2, verbose = TRUE)

cat("Operation 1: Square roots\n")
result1 <- smart_parallel_apply(1:50, sqrt, setup = setup)

cat("Operation 2: Natural logarithms\n")
result2 <- smart_parallel_apply(1:50, log, setup = setup)

cat("Operation 3: Cubes\n")
result3 <- smart_parallel_apply(1:50, function(x) x^3, setup = setup)

stop_parallel(setup)
cat("Cleanup complete\n\n")

# Example 5: Custom function with multiple arguments
cat("Example 5: Custom function with arguments\n")
cat("==========================================\n")

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

cat("Transform f(x) = 2.5x + 100 for x in 1:5:\n")
cat("  Results:", unlist(result[1:5]), "...\n\n")

# Example 6: Error handling demonstration
cat("Example 6: Error handling\n")
cat("=========================\n")

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

cat("Processing with potential warnings...\n")
result <- suppressWarnings(
  smart_parallel_apply(1:10, risky_function, n_cores = 2)
)
cat("Successfully processed:", length(result), "items\n\n")

cat("=== All examples completed successfully! ===\n")
