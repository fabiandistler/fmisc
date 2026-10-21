# fmisc 0.3.0

## Breaking changes

* `get_flir_rules()` is removed, so calling it errors and listing `fmisc`
  in the `from-package` field of `flir/config.yml` no longer loads any
  rules. The bundled rules themselves, `deprecated-sample-n` and
  `deprecated-sample-frac` (which rewrote dplyr's superseded `sample_n()`
  and `sample_frac()`), are gone with no replacement: write the rules into
  your own project instead, or drop the `from-package` entry. `flir` is no
  longer in Suggests, and the `using-fmisc` vignette that documented the
  integration is removed, so `vignette("using-fmisc")` errors (#62).

## New features

* `agent_run()` runs the Claude Code CLI (`claude -p`) once, read-only,
  in a directory and returns its answer, which must match a JSON Schema
  given as a string, as an `fmisc_agent_result`. The agent gets only the
  `Read`, `Glob` and `Grep` tools, no repo or user customisations, and the
  prompt goes on stdin. The model, turn and budget caps are fixed, and
  `timeout` bounds the whole run and kills the process tree. It uses the
  CLI's existing login, intended to be a Claude subscription, and removes
  API-key, gateway and cloud-provider variables (`ANTHROPIC_API_KEY`,
  `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `CLAUDE_CODE_USE_*`, ...)
  from the child environment so a run never bills elsewhere by accident.
  Fixed Read deny rules keep common secret files (`.env*`, `.Renviron*`,
  `*.pem`, `*.key`, SSH keys, `.netrc`, `.git-credentials`) away from the
  agent; that is defense in depth, not a sandbox. Errors are classed
  (`fmisc_agent_error` and subclasses). Needs `processx` and `jsonlite`
  (Suggests) and Claude Code CLI >= 2.1.259; not supported on Windows yet
  (#75).

* `ci_failures()` fetches the latest failed GitHub Actions run of the
  current branch and returns one row per finding (`job`, `os`, `step`,
  `kind`, `file`, `line`, `message`, `sha`, `url`). It recognises
  R CMD check ERRORs, WARNINGs and NOTEs, testthat failures and errors,
  lintr annotations and air format-check failures; a failed job it cannot
  explain is kept as kind `"unparsed"` with the raw log of the failing
  step, and a timed-out or cancelled job as kind `"timed_out"` or
  `"cancelled"`. `gh` and `gert` join Imports; both were already installed
  as dependencies of usethis (#76).

# fmisc 0.2.0

## Refactoring

* `with_cache()` is now a thin facade over `memoise::memoise()` backed by
  `cachem::cache_mem()`. `.max_size` maps to `max_n` (LRU eviction) and
  `.ttl` to `max_age`; the hand-rolled environment backend and the
  `deparse()`-based key scheme are gone (`memoise` hashes internally).
  The `.key` argument is removed: custom cache keys are not supported by
  `memoise`, so there is no drop-in replacement. `cache_info()` now
  reports `backend = "cachem"` with `size`, `max_n`, and `max_age`
  (the old `"env"`/`"memoise"` backends and `keys` element are gone).
  `memoise` and `cachem` moved from Suggests to Imports.

## New features

* `with_retry()` gains two conveniences: `.on_error` now also accepts a
  character vector of condition classes to retry on (e.g.
  `c("http_error_503")`), mirroring httr2's `is_transient` idiom; and a
  `.message = TRUE` toggle emits a `message()` before each retry.
* `undecorate()` gains a `depth` argument (default `1`); `depth = Inf`
  unwraps the full decorator chain. New vignette
  `vignette("decorators")` compares the decorators against
  `purrr::insistently()`, `memoise` + `cachem`, and `ratelimitr`, and
  documents the deliberate skip of burst-tolerant rate limiting (use
  `httr2::req_throttle()` for HTTP burst needs).
* Decorated functions now record each applied decorator (name + key
  parameters) in an `"fmisc_stack"` attribute, accumulated as wrappers
  compose via `decorate()` or the native pipe. `print()` on an
  `"fmisc_decorated"` object shows the wrapper stack outermost-first.

### Function Decorators (Function-Operator Toolkit)

* New composable "function operators" for cross-cutting concerns. Each `with_*()` takes a function as its first argument and returns a wrapped function with class `"fmisc_decorated"`, making them curry- and pipe-friendly:
  - `with_retry()` — retry with exponential backoff, jitter, `.on_error` predicate, `.on_retry` callback, and `.max_delay` cap. Raises `"fmisc_retry_exhausted"` on final failure while preserving the original condition's classes.
  - `with_timing()` — wall-clock timing via `proc.time()`, reported as cli message, `"elapsed"` attribute, or callback; reports on both success and failure.
  - `with_logging()` — call/success/error events via a default cli logger or a custom `.logger(event, data)`.
  - `with_cache()` — memoisation facade over `memoise::memoise()` + `cachem::cache_mem()` with LRU eviction (`.max_size`) and time-to-live (`.ttl`). Companions: `cache_clear()`, `cache_info()`.
  - `with_rate_limit()` — throttle to `n` calls per rolling `period` seconds; either wait or raise `"fmisc_rate_limit_exceeded"`.
* Composition helpers: `decorate()` composes unary decorators left-to-right; `is_decorated()` and `undecorate()` inspect the wrapper chain.

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
