# Smart Parallel Framework for R

Intelligent R parallelization that automatically selects the best parallel computing framework based on your operating system and available packages.

## Features

- **Automatic OS Detection**: Detects whether you're on Unix-like (Linux/macOS) or Windows
- **Smart Backend Selection**: Automatically chooses the best parallelization method:
  - Unix/Linux/macOS: Prefers fork-based (`doMC`, `mclapply`)
  - Windows: Uses socket-based (`doParallel`, `parLapply`)
- **Graceful Fallback**: Falls back to sequential processing if no parallel packages are available
- **Unified Interface**: Simple API regardless of underlying backend
- **Resource Management**: Automatic cleanup of cluster resources

## Supported Backends

The function supports these R parallelization frameworks (in order of preference):

### Unix-like Systems (Linux, macOS)
1. **furrr** - Future-based parallelization (most flexible)
2. **doMC** - Fork-based multicore (fast, low overhead)
3. **mclapply** - Built-in parallel package with fork
4. **doParallel** - Socket-based (cross-platform compatible)

### Windows
1. **furrr** - Future-based parallelization (most flexible)
2. **doParallel** - Socket-based clusters (Windows compatible)
3. **parLapply** - Built-in parallel package with sockets
4. **foreach** - Sequential fallback

## Installation

The `parallel` package is included with base R. For enhanced functionality, install additional packages:

```r
# Recommended packages
install.packages("foreach")
install.packages("doParallel")
install.packages("future")
install.packages("furrr")

# Unix/Linux/macOS only
install.packages("doMC")
```

## Usage

### Quick Start

```r
source("smart_parallel.R")

# Check your environment
print_parallel_info()

# Simple parallel computation
result <- smart_parallel_apply(1:100, function(x) x^2)
```

### Basic Examples

#### Example 1: Automatic Configuration

```r
# The function auto-detects the best backend and core count
result <- smart_parallel_apply(1:1000, sqrt)
```

#### Example 2: Specify Core Count

```r
# Use specific number of cores
result <- smart_parallel_apply(1:1000, log, n_cores = 4)
```

#### Example 3: Reuse Configuration

```r
# Setup once, use multiple times (more efficient)
setup <- setup_parallel(n_cores = 4)

result1 <- smart_parallel_apply(1:1000, sqrt, setup = setup)
result2 <- smart_parallel_apply(1:1000, log, setup = setup)
result3 <- smart_parallel_apply(1:1000, function(x) x^3, setup = setup)

# Always cleanup when done
stop_parallel(setup)
```

#### Example 4: Custom Functions with Arguments

```r
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
```

#### Example 5: Check Available Backends

```r
# Get detailed information about your environment
info <- detect_parallel_backend()
print(info$backend)          # Current recommended backend
print(info$available_cores)  # Number of CPU cores
print(info$packages)         # Which packages are installed
```

## API Reference

### Main Functions

#### `detect_parallel_backend()`

Detects the best parallelization backend for your environment.

**Returns**: List with `backend`, `os_type`, `available_cores`, and `packages`

#### `setup_parallel(n_cores = NULL, backend = NULL, verbose = TRUE)`

Sets up parallel computing with automatic configuration.

**Parameters**:
- `n_cores`: Number of cores to use (NULL = auto-detect, use all but one)
- `backend`: Force specific backend (NULL = auto-detect)
- `verbose`: Print setup information (default: TRUE)

**Returns**: Setup object with cluster and configuration details

#### `stop_parallel(setup)`

Stops parallel backend and cleans up resources.

**Parameters**:
- `setup`: Setup object from `setup_parallel()`

#### `smart_parallel_apply(X, FUN, n_cores = NULL, ..., setup = NULL)`

Universal parallel apply function that works across all backends.

**Parameters**:
- `X`: Vector or list to iterate over
- `FUN`: Function to apply to each element
- `n_cores`: Number of cores (NULL = auto)
- `...`: Additional arguments passed to FUN
- `setup`: Optional pre-configured setup object

**Returns**: List of results

#### `print_parallel_info()`

Prints detailed information about your parallel computing environment.

## How It Works

1. **OS Detection**: Uses `.Platform$OS.type` to determine the operating system
2. **Package Detection**: Checks which parallelization packages are installed
3. **Backend Selection**: Chooses optimal backend based on OS and available packages
4. **Automatic Setup**: Configures the selected backend with appropriate parameters
5. **Execution**: Runs your code using the best available method
6. **Cleanup**: Automatically manages cluster resources

## Performance Tips

1. **Reuse Setup**: If running multiple parallel operations, create one setup and reuse it
2. **Right-size Cores**: Don't always use all cores; leave 1-2 for system responsiveness
3. **Task Granularity**: Parallel overhead matters; use for tasks that take >0.1s each
4. **Windows Overhead**: Socket-based parallelization (Windows) has more overhead than fork-based (Unix)

## Error Handling

The function includes automatic fallback:
- If parallel execution fails, it automatically falls back to sequential `lapply()`
- Warnings are issued when fallback occurs
- Sequential processing is guaranteed to work even if no parallel packages exist

## Requirements

- R ≥ 3.0.0
- `parallel` package (included with R)
- Optional: `foreach`, `doParallel`, `doMC`, `future`, `furrr`

## License

This code is provided as-is for educational and production use.
