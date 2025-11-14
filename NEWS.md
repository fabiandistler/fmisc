# fmisc (development version)

## New Features

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
  
