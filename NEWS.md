# fmisc (development version)

## New features

### Function Decorators (Function-Operator Toolkit)

* New composable "function operators" for cross-cutting concerns. Each `with_*()` takes a function as its first argument and returns a wrapped function with class `"fmisc_decorated"`, making them curry- and pipe-friendly:
  - `with_retry()` — retry with exponential backoff, jitter, `.on_error` predicate, `.on_retry` callback, and `.max_delay` cap. Raises `"fmisc_retry_exhausted"` on final failure while preserving the original condition's classes.
  - `with_timing()` — wall-clock timing via `proc.time()`, reported as cli message, `"elapsed"` attribute, or callback; reports on both success and failure.
  - `with_logging()` — call/success/error events via a default cli logger or a custom `.logger(event, data)`.
  - `with_cache()` — memoisation. Delegates to `memoise::memoise()` when available and unbounded; otherwise uses a built-in env-backed cache with LRU eviction (`.max_size`) and time-to-live (`.ttl`). Companions: `cache_clear()`, `cache_info()`.
  - `with_rate_limit()` — throttle to `n` calls per rolling `period` seconds; either wait or raise `"fmisc_rate_limit_exceeded"`.
* Composition helpers: `decorate()` composes unary decorators left-to-right; `is_decorated()` and `undecorate()` inspect the wrapper chain.

### Dependency Injection

* New `di_container()` — a closure-based dependency-injection container with:
  - `register()` / `resolve()` / `has()` / `names()` / `unregister()` — service registration and resolution.
  - Three lifecycles: `"singleton"` (factory once, cached), `"transient"` (factory each resolve), `"value"` (stored as-is).
  - Auto-wiring by formal argument name, with `.deps` for explicit remapping.
  - Circular-dependency detection (`"fmisc_di_cycle"`), missing-service errors (`"fmisc_di_missing"`), duplicate-registration errors (`"fmisc_di_duplicate"`).
  - `child()` scopes that shadow the parent without mutation.
  - `override()` returning a `restore()` closure that reinstates the prior registration and clears the singleton cache.
  - `inject()` — pre-bind formals matching registered service names into a user function.
  - Special `.container` factory formal to receive the owning container.
* `with_di_overrides(container, overrides, code)` — withr-style helper that applies a set of overrides for the duration of an expression and always restores them via `on.exit()`.
* `print.fmisc_di_container()` — cli-formatted listing of local registrations.

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

