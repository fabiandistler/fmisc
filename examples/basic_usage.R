# Basic Usage Examples for fmisc Package
# Demonstrates chunking algorithm with RAM management

library(fmisc)

# ========================================
# Example 1: Basic Chunking with RAM Management
# ========================================

cat("\n=== Example 1: Basic Chunking ===\n")

# Check system information
sys_info <- get_system_info()
cat(sprintf("Total RAM: %.2f MB\n", sys_info$total_ram_mb))
cat(sprintf("Available RAM: %.2f MB\n", sys_info$available_ram_mb))
cat(sprintf("Current usage: %.2f MB\n", sys_info$used_ram_mb))

# Create sample data
set.seed(123)
n <- 100000
sample_data <- data.frame(
  id = 1:n,
  value1 = rnorm(n),
  value2 = runif(n),
  value3 = rpois(n, lambda = 5)
)

cat(sprintf("\nData size: %.2f MB\n", object.size(sample_data) / (1024^2)))

# Process with automatic chunking
result <- process_with_chunks(
  data = sample_data,
  process_fn = function(chunk) {
    # Example processing: add computed column
    chunk$computed <- chunk$value1 * chunk$value2 + chunk$value3
    chunk$squared <- chunk$value1^2
    return(chunk)
  },
  max_ram_mb = 200,  # Low threshold to demonstrate disk writing
  verbose = TRUE
)

cat("\nProcessing complete!\n")
cat(sprintf("Result dimensions: %d rows, %d cols\n", nrow(result), ncol(result)))
cat(sprintf("Final RAM usage: %.2f MB\n", get_ram_usage()))

# ========================================
# Example 2: Using Chunk Iterator
# ========================================

cat("\n\n=== Example 2: Manual Chunk Iterator ===\n")

# Create iterator
chunk_size <- 10000
iterator <- create_chunk_iterator(sample_data, chunk_size = chunk_size)

cat(sprintf("Total chunks: %d\n", iterator$total_chunks))
cat(sprintf("Chunk size: %d rows\n", chunk_size))

# Process chunks manually
results_list <- list()
while (iterator$has_next()) {
  chunk <- iterator$get_next()

  # Example processing
  processed <- data.frame(
    id = chunk$id,
    mean_value = (chunk$value1 + chunk$value2) / 2
  )

  results_list[[length(results_list) + 1]] <- processed

  if (iterator$current_chunk() %% 3 == 0) {
    cat(sprintf("Processed chunk %d/%d\n",
                iterator$current_chunk(), iterator$total_chunks))
  }
}

result2 <- do.call(rbind, results_list)
cat(sprintf("\nFinal result: %d rows\n", nrow(result2)))

# ========================================
# Example 3: Chunk Processor Object
# ========================================

cat("\n\n=== Example 3: Chunk Processor Object ===\n")

# Create processor
processor <- chunk_processor(max_ram_mb = 150, verbose = TRUE)

# Simulate processing multiple chunks
for (i in 1:10) {
  # Generate chunk
  chunk_data <- data.frame(
    iteration = i,
    x = rnorm(10000),
    y = runif(10000)
  )

  # Process chunk
  processed <- data.frame(
    iteration = chunk_data$iteration,
    result = chunk_data$x + chunk_data$y
  )

  # Add to processor (handles RAM automatically)
  processor$add_chunk(processed)

  cat(sprintf("Added chunk %d (RAM: %.2f MB)\n", i, processor$get_ram_usage()))
}

# Get combined results
result3 <- processor$get_results()
cat(sprintf("\nCombined result: %d rows\n", nrow(result3)))

# Clean up
processor$cleanup()

# ========================================
# Example 4: Fast C++ Chunk Splitting
# ========================================

cat("\n\n=== Example 4: Fast C++ Chunk Splitting ===\n")

# Create large vector
large_vector <- rnorm(1e6)
cat(sprintf("Vector size: %.2f MB\n", object.size(large_vector) / (1024^2)))

# Split using C++ (fast)
system.time({
  chunks_cpp <- split_vector_chunks(large_vector, chunk_size = 10000)
})
cat(sprintf("Created %d chunks using C++\n", length(chunks_cpp)))

# Create large matrix
large_matrix <- matrix(rnorm(1e6), ncol = 100)
cat(sprintf("\nMatrix size: %.2f MB\n", object.size(large_matrix) / (1024^2)))

# Split matrix using C++
system.time({
  matrix_chunks <- split_matrix_chunks(large_matrix, chunk_size = 1000)
})
cat(sprintf("Created %d matrix chunks using C++\n", length(matrix_chunks)))

# ========================================
# Example 5: Optimal Chunk Size Calculation
# ========================================

cat("\n\n=== Example 5: Optimal Chunk Size ===\n")

data_size_mb <- 500
total_rows <- 1e6
max_ram_mb <- 1000

optimal_size <- calculate_optimal_chunk_size(
  data_size_mb = data_size_mb,
  total_rows = total_rows,
  max_ram_mb = max_ram_mb,
  target_fraction = 0.1
)

cat(sprintf("Data: %.2f MB with %d rows\n", data_size_mb, total_rows))
cat(sprintf("RAM limit: %.2f MB\n", max_ram_mb))
cat(sprintf("Optimal chunk size: %d rows\n", optimal_size))
cat(sprintf("Number of chunks: %d\n", ceiling(total_rows / optimal_size)))

# ========================================
# Example 6: Aggregation with Custom Combine
# ========================================

cat("\n\n=== Example 6: Aggregation with Custom Combine ===\n")

# Create categorical data
categorical_data <- data.frame(
  category = sample(LETTERS[1:5], 50000, replace = TRUE),
  value = rnorm(50000)
)

# Process with aggregation
result6 <- process_with_chunks(
  data = categorical_data,
  process_fn = function(chunk) {
    # Aggregate within chunk
    aggregate(chunk$value, by = list(category = chunk$category), FUN = mean)
  },
  combine_fn = function(x, y) {
    # Combine aggregated results
    combined <- rbind(x, y)
    # Re-aggregate to get final means
    aggregate(combined$x, by = list(category = combined$category), FUN = mean)
  },
  max_ram_mb = 100,
  verbose = TRUE
)

cat("\nAggregated results:\n")
print(result6)

# ========================================
# Summary
# ========================================

cat("\n\n=== Summary ===\n")
cat("All examples completed successfully!\n")
cat(sprintf("Final RAM usage: %.2f MB\n", get_ram_usage()))
cat("\nKey features demonstrated:\n")
cat("  1. Automatic chunking with RAM management\n")
cat("  2. Manual chunk iteration\n")
cat("  3. Chunk processor object\n")
cat("  4. Fast C++ implementations\n")
cat("  5. Optimal chunk size calculation\n")
cat("  6. Custom combine functions for aggregation\n")
