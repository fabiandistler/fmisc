# Changelog

## fmisc (development version)

### Refactoring

- [`with_cache()`](https://fabiandistler.github.io/fmisc/reference/with_cache.md)
  is now a thin facade over
  [`memoise::memoise()`](https://memoise.r-lib.org/reference/memoise.html)
  backed by
  [`cachem::cache_mem()`](https://cachem.r-lib.org/reference/cache_mem.html).
  `.max_size` maps to `max_n` (LRU eviction) and `.ttl` to `max_age`;
  the hand-rolled environment backend and the
  [`deparse()`](https://rdrr.io/r/base/deparse.html)-based key scheme
  are gone (`memoise` hashes internally). The `.key` argument is
  removed: custom cache keys are not supported by `memoise`, so there is
  no drop-in replacement.
  [`cache_info()`](https://fabiandistler.github.io/fmisc/reference/cache_clear.md)
  now reports `backend = "cachem"` with `size`, `max_n`, and `max_age`
  (the old `"env"`/`"memoise"` backends and `keys` element are gone).
  `memoise` and `cachem` moved from Suggests to Imports.

### New features

- [`with_retry()`](https://fabiandistler.github.io/fmisc/reference/with_retry.md)
  gains two conveniences: `.on_error` now also accepts a character
  vector of condition classes to retry on (e.g. `c("http_error_503")`),
  mirroring httr2’s `is_transient` idiom; and a `.message = TRUE` toggle
  emits a [`message()`](https://rdrr.io/r/base/message.html) before each
  retry.
- [`undecorate()`](https://fabiandistler.github.io/fmisc/reference/undecorate.md)
  gains a `depth` argument (default `1`); `depth = Inf` unwraps the full
  decorator chain. New vignette
  [`vignette("decorators")`](https://fabiandistler.github.io/fmisc/articles/decorators.md)
  compares the decorators against
  [`purrr::insistently()`](https://purrr.tidyverse.org/reference/insistently.html),
  `memoise` + `cachem`, and `ratelimitr`, and documents the deliberate
  skip of burst-tolerant rate limiting (use
  [`httr2::req_throttle()`](https://httr2.r-lib.org/reference/req_throttle.html)
  for HTTP burst needs).
- Decorated functions now record each applied decorator (name + key
  parameters) in an `"fmisc_stack"` attribute, accumulated as wrappers
  compose via
  [`decorate()`](https://fabiandistler.github.io/fmisc/reference/decorate.md)
  or the native pipe. [`print()`](https://rdrr.io/r/base/print.html) on
  an `"fmisc_decorated"` object shows the wrapper stack outermost-first.

#### Function Decorators (Function-Operator Toolkit)

- New composable “function operators” for cross-cutting concerns. Each
  `with_*()` takes a function as its first argument and returns a
  wrapped function with class `"fmisc_decorated"`, making them curry-
  and pipe-friendly:
  - [`with_retry()`](https://fabiandistler.github.io/fmisc/reference/with_retry.md)
    — retry with exponential backoff, jitter, `.on_error` predicate,
    `.on_retry` callback, and `.max_delay` cap. Raises
    `"fmisc_retry_exhausted"` on final failure while preserving the
    original condition’s classes.
  - [`with_timing()`](https://fabiandistler.github.io/fmisc/reference/with_timing.md)
    — wall-clock timing via
    [`proc.time()`](https://rdrr.io/r/base/proc.time.html), reported as
    cli message, `"elapsed"` attribute, or callback; reports on both
    success and failure.
  - [`with_logging()`](https://fabiandistler.github.io/fmisc/reference/with_logging.md)
    — call/success/error events via a default cli logger or a custom
    `.logger(event, data)`.
  - [`with_cache()`](https://fabiandistler.github.io/fmisc/reference/with_cache.md)
    — memoisation facade over
    [`memoise::memoise()`](https://memoise.r-lib.org/reference/memoise.html) +
    [`cachem::cache_mem()`](https://cachem.r-lib.org/reference/cache_mem.html)
    with LRU eviction (`.max_size`) and time-to-live (`.ttl`).
    Companions:
    [`cache_clear()`](https://fabiandistler.github.io/fmisc/reference/cache_clear.md),
    [`cache_info()`](https://fabiandistler.github.io/fmisc/reference/cache_clear.md).
  - [`with_rate_limit()`](https://fabiandistler.github.io/fmisc/reference/with_rate_limit.md)
    — throttle to `n` calls per rolling `period` seconds; either wait or
    raise `"fmisc_rate_limit_exceeded"`.
- Composition helpers:
  [`decorate()`](https://fabiandistler.github.io/fmisc/reference/decorate.md)
  composes unary decorators left-to-right;
  [`is_decorated()`](https://fabiandistler.github.io/fmisc/reference/is_decorated.md)
  and
  [`undecorate()`](https://fabiandistler.github.io/fmisc/reference/undecorate.md)
  inspect the wrapper chain.

#### Chunking and RAM Management Framework

- New chunking and RAM management framework for processing large
  datasets that exceed available memory:
  - [`process_with_chunks()`](https://fabiandistler.github.io/fmisc/reference/process_with_chunks.md)
    automatically processes data in chunks with RAM monitoring and
    automatic disk spillover when memory threshold is exceeded
  - [`create_chunk_iterator()`](https://fabiandistler.github.io/fmisc/reference/create_chunk_iterator.md)
    creates iterators that split data.frames, matrices, or vectors into
    manageable chunks
  - [`chunk_processor()`](https://fabiandistler.github.io/fmisc/reference/chunk_processor.md)
    provides a stateful processor for building custom chunking workflows
  - `get_ram_usage()` and
    [`get_ram_usage_cpp()`](https://fabiandistler.github.io/fmisc/reference/get_ram_usage_cpp.md)
    (fast C++ implementation) monitor current RAM usage
  - [`split_vector_chunks()`](https://fabiandistler.github.io/fmisc/reference/split_vector_chunks.md)
    and
    [`split_matrix_chunks()`](https://fabiandistler.github.io/fmisc/reference/split_matrix_chunks.md)
    provide fast C++ implementations for splitting data
  - [`ram_threshold_exceeded()`](https://fabiandistler.github.io/fmisc/reference/ram_threshold_exceeded.md)
    checks if current RAM usage exceeds a specified threshold
  - [`calculate_optimal_chunk_size()`](https://fabiandistler.github.io/fmisc/reference/calculate_optimal_chunk_size.md)
    automatically determines optimal chunk size based on data and RAM
    constraints
  - [`get_system_info()`](https://fabiandistler.github.io/fmisc/reference/get_system_info.md)
    provides cross-platform system information for resource planning
- Features include:
  - Automatic chunk size calculation based on data size and RAM
    constraints
  - Cross-platform RAM monitoring (Windows, Linux, macOS)
  - Disk spillover with temporary file management
  - Flexible result combination via custom `combine_fn` parameter
  - Progress monitoring with optional verbose output

#### Smart Parallel Computing Framework

- Added comprehensive parallel computing framework that automatically
  selects the best backend based on OS and available packages
- New functions:
  - [`detect_parallel_backend()`](https://fabiandistler.github.io/fmisc/reference/detect_parallel_backend.md) -
    Detect available parallelization options
  - [`setup_parallel()`](https://fabiandistler.github.io/fmisc/reference/setup_parallel.md) -
    Configure parallel computing with automatic backend selection
  - [`smart_parallel_apply()`](https://fabiandistler.github.io/fmisc/reference/smart_parallel_apply.md) -
    Universal parallel apply function
  - [`stop_parallel()`](https://fabiandistler.github.io/fmisc/reference/stop_parallel.md) -
    Clean up parallel resources
  - [`print_parallel_info()`](https://fabiandistler.github.io/fmisc/reference/print_parallel_info.md) -
    Display environment capabilities
- Features:
  - OS-aware backend selection (fork-based for Unix, socket-based for
    Windows)
  - Support for multiple backends: mclapply, parLapply, doParallel,
    doMC, furrr, future
  - Automatic fallback to sequential processing
  - Resource cleanup with
    [`on.exit()`](https://rdrr.io/r/base/on.exit.html) guarantee
  - Windows support with automatic `clusterExport()`
  - Input validation and robust error handling

### Bug fixes

- `chunk_processor()$get_results()` now correctly combines chunks in
  chronological order, combining disk-saved chunks before in-memory
  chunks.

- [`create_chunk_iterator()`](https://fabiandistler.github.io/fmisc/reference/create_chunk_iterator.md)
  now properly excludes list objects from vector validation, preventing
  incorrect handling of list inputs.
