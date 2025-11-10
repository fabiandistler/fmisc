# fmisc: Chunking Algorithm for RAM Management

An R package that provides intelligent chunking algorithms to manage RAM usage by automatically writing chunks of data to disk. Perfect for processing large datasets that don't fit in memory.

## Features

- **Automatic RAM monitoring**: Continuously monitors RAM usage during data processing
- **Smart chunking**: Automatically calculates optimal chunk sizes based on available RAM
- **Disk-backed processing**: Seamlessly writes chunks to disk when RAM threshold is reached
- **High performance**: Rcpp implementation for performance-critical operations
- **Flexible API**: Multiple interfaces for different use cases
- **Cross-platform**: Works on Windows, Linux, and macOS

## Installation

```r
# Install from source
devtools::install_github("yourusername/fmisc")

# Or install locally
install.packages("path/to/fmisc", repos = NULL, type = "source")
```

## Quick Start

### Basic Example

```r
library(fmisc)

# Create a large dataset
large_data <- data.frame(
  x = 1:1e6,
  y = rnorm(1e6),
  z = runif(1e6)
)

# Process with automatic chunking and RAM management
result <- process_with_chunks(
  data = large_data,
  process_fn = function(chunk) {
    # Your processing logic here
    chunk$result <- chunk$x * chunk$y + chunk$z
    return(chunk)
  },
  max_ram_mb = 500,  # Stay below 500 MB
  verbose = TRUE
)
```

### Using the Chunk Iterator

```r
# Create an iterator for manual chunk processing
iterator <- create_chunk_iterator(large_data, chunk_size = 10000)

results <- list()
while (iterator$has_next()) {
  chunk <- iterator$get_next()
  processed <- your_processing_function(chunk)
  results[[length(results) + 1]] <- processed
}

final_result <- do.call(rbind, results)
```

### Using the Chunk Processor Object

```r
# Create a processor that automatically manages RAM
processor <- chunk_processor(max_ram_mb = 500, verbose = TRUE)

# Add chunks as you process them
for (i in 1:100) {
  chunk_data <- generate_chunk(i)  # Your data generation
  processed <- process_chunk(chunk_data)  # Your processing
  processor$add_chunk(processed)
}

# Get combined results (handles disk chunks automatically)
final_result <- processor$get_results()

# Clean up temporary files
processor$cleanup()
```

## Core Functions

### RAM Monitoring

```r
# Get current RAM usage
current_ram <- get_ram_usage()
print(paste("Current RAM:", current_ram, "MB"))

# Fast C++ implementation
current_ram_cpp <- get_ram_usage_cpp()

# Get system information
sys_info <- get_system_info()
print(sys_info)
# $total_ram_mb
# $available_ram_mb
# $used_ram_mb
```

### Chunk Operations

```r
# Split vector into chunks (C++ implementation for speed)
vector_data <- rnorm(1e6)
chunks <- split_vector_chunks(vector_data, chunk_size = 10000)

# Split matrix into chunks
matrix_data <- matrix(rnorm(1e6), ncol = 10)
chunks <- split_matrix_chunks(matrix_data, chunk_size = 1000)

# Calculate optimal chunk size
optimal_size <- calculate_optimal_chunk_size(
  data_size_mb = 100,
  total_rows = 1e6,
  max_ram_mb = 500,
  target_fraction = 0.1  # Use 10% of max RAM per chunk
)
```

## Advanced Usage

### Custom Combine Function

```r
# Use a custom function to combine results
result <- process_with_chunks(
  data = large_data,
  process_fn = function(chunk) {
    aggregate(chunk$value, by = list(chunk$category), FUN = mean)
  },
  combine_fn = function(x, y) {
    # Custom merge logic
    merge(x, y, by = "Group.1", all = TRUE)
  },
  max_ram_mb = 500
)
```

### Processing Files in Chunks

```r
# Process a large CSV file in chunks
process_large_csv <- function(file_path, max_ram_mb = 1000) {
  # Read file size to estimate chunks
  file_size_mb <- file.info(file_path)$size / (1024^2)

  # Read and process in chunks
  processor <- chunk_processor(max_ram_mb = max_ram_mb)

  # Read file in chunks (example with data.table)
  library(data.table)
  chunk_size <- 10000

  for (chunk in read_csv_chunks(file_path, chunk_size)) {
    processed <- process_chunk(chunk)
    processor$add_chunk(processed)
  }

  return(processor$get_results())
}
```

### Monitoring RAM Threshold

```r
# Check if RAM threshold is exceeded
if (ram_threshold_exceeded(max_ram_mb = 1000)) {
  message("RAM threshold exceeded! Writing to disk...")
  # Handle overflow
}
```

## How It Works

1. **Automatic Chunk Size Calculation**: The algorithm calculates optimal chunk sizes based on:
   - Total data size
   - Available RAM
   - Target RAM usage per chunk (default: 10% of max RAM)

2. **RAM Monitoring**: During processing:
   - RAM usage is checked after each chunk
   - When RAM exceeds threshold, accumulated results are written to disk
   - Garbage collection is triggered to free memory

3. **Disk-backed Storage**:
   - Chunks are compressed and saved as RDS files
   - Temporary directory is created for each session
   - Files are automatically cleaned up after combining

4. **Result Combination**:
   - In-memory chunks are combined first
   - Disk chunks are read and combined one at a time
   - Memory-efficient processing ensures RAM limits are respected

## Performance Tips

1. **Choose appropriate chunk sizes**: Smaller chunks = more overhead, larger chunks = more RAM usage
2. **Use C++ functions for large datasets**: Functions like `split_vector_chunks` are much faster
3. **Monitor your RAM threshold**: Set `max_ram_mb` to 60-70% of available RAM for best performance
4. **Use compression**: RDS files are automatically compressed when writing to disk
5. **Clean up**: Call `processor$cleanup()` to remove temporary files

## Platform-Specific Notes

### Linux/Unix
- Uses `/proc/self/status` for accurate RAM monitoring
- Falls back to `getrusage` if `/proc` unavailable

### macOS
- Uses `getrusage` for RAM monitoring
- Memory values reported in bytes

### Windows
- Uses Windows API (`GetProcessMemoryInfo`)
- Requires `psapi` library (automatically linked)

## Requirements

- R >= 3.5.0
- Rcpp >= 1.0.0
- C++11 compiler

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Issues

If you encounter any issues or have suggestions, please file an issue on GitHub.
