# fmisc (development version)

## New features

### Chunking and RAM Management Framework

* New chunking and RAM management framework for processing large datasets that exceed available memory:
  - `process_with_chunks()` automatically processes data in chunks with RAM monitoring and automatic disk spillover when memory threshold is exceeded
  - `create_chunk_iterator()` creates iterators that split data.frames, matrices, or vectors into manageable chunks
  - `chunk_processor()` provides a stateful processor for building custom chunking workflows
  - `get_ram_usage()` and `get_ram_usage_cpp()` (fast C++ implementation) monitor current RAM usage
  - `split_vector_chunks()` and `split_matrix_chunks()` provide fast C++ implementations for splitting data
  - `ram_threshold_exceeded()` checks if current RAM usage exceeds a specified threshold
  - `calculate_optimal_chunk_size()` automatically determines optimal chunk size based on data and RAM constraints
  - `get_system_info()` provides cross-platform system information for resource planning

* Features include:
  - Automatic chunk size calculation based on data size and RAM constraints
  - Cross-platform RAM monitoring (Windows, Linux, macOS)
  - Disk spillover with temporary file management
  - Flexible result combination via custom `combine_fn` parameter
  - Progress monitoring with optional verbose output

### Smart Parallel Computing Framework

* Added comprehensive parallel computing framework that automatically selects the best backend based on OS and available packages
* New functions:
  - `detect_parallel_backend()` - Detect available parallelization options
  - `setup_parallel()` - Configure parallel computing with automatic backend selection
  - `smart_parallel_apply()` - Universal parallel apply function
  - `stop_parallel()` - Clean up parallel resources
  - `print_parallel_info()` - Display environment capabilities

* Features:
  - OS-aware backend selection (fork-based for Unix, socket-based for Windows)
  - Support for multiple backends: mclapply, parLapply, doParallel, doMC, furrr, future
  - Automatic fallback to sequential processing
  - Resource cleanup with `on.exit()` guarantee
  - Windows support with automatic `clusterExport()`
  - Input validation and robust error handling

## Bug fixes

* `chunk_processor()$get_results()` now correctly combines chunks in chronological order, combining disk-saved chunks before in-memory chunks.

* `create_chunk_iterator()` now properly excludes list objects from vector validation, preventing incorrect handling of list inputs.

