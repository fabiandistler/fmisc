# Retry a function with exponential backoff

Wraps `f` so that on error the call is retried up to `max_tries` times,
with a delay of `backoff^attempt` seconds between attempts (optionally
jittered and capped).

## Usage

``` r
with_retry(
  f,
  max_tries = 3L,
  backoff = 2,
  ...,
  .on_error = NULL,
  .max_delay = Inf,
  .jitter = TRUE,
  .on_retry = NULL,
  .message = FALSE
)
```

## Arguments

- f:

  A function to wrap.

- max_tries:

  Positive integer. Maximum number of attempts (including the first).
  Default `3`.

- backoff:

  Non-negative number. Base of the exponential delay in seconds; delay
  for attempt `k` is `backoff^k`. Default `2` (i.e. 2, 4, 8, 16 s). Use
  `0` to disable delays.

- ...:

  Passed to the wrapped function on each call. Reserved for future
  extensions; currently forwarded via the wrapper's `...`.

- .on_error:

  Optional predicate `function(cnd) -> logical`, or a character vector
  of condition classes to retry on (e.g. `c("http_error_503")`),
  mirroring httr2's `is_transient` idiom. When the predicate returns
  `FALSE` (or the error matches none of the classes) the error is
  re-raised immediately. Default `NULL` retries all errors.

- .max_delay:

  Numeric cap on individual retry delays in seconds. Default `Inf`.

- .jitter:

  Logical. If `TRUE` (default), each delay is multiplied by a uniform
  random factor in `[0.5, 1.5]` to avoid synchronized retries.

- .on_retry:

  Optional callback `function(attempt, delay, cnd)` invoked before each
  sleep. Errors in the callback are swallowed.

- .message:

  Logical. If `TRUE`, emits a
  [`message()`](https://rdrr.io/r/base/message.html) before each retry
  describing the attempt and delay. Default `FALSE`.

## Value

A function that forwards its arguments to `f`. On persistent failure
raises a condition of class `"fmisc_retry_exhausted"` preserving the
original condition's classes.

## See also

Other decorators:
[`cache_clear()`](https://fabiandistler.github.io/fmisc/reference/cache_clear.md),
[`decorate()`](https://fabiandistler.github.io/fmisc/reference/decorate.md),
[`fmisc_decorators`](https://fabiandistler.github.io/fmisc/reference/fmisc_decorators.md),
[`is_decorated()`](https://fabiandistler.github.io/fmisc/reference/is_decorated.md),
[`print.fmisc_decorated()`](https://fabiandistler.github.io/fmisc/reference/print.fmisc_decorated.md),
[`undecorate()`](https://fabiandistler.github.io/fmisc/reference/undecorate.md),
[`with_cache()`](https://fabiandistler.github.io/fmisc/reference/with_cache.md),
[`with_logging()`](https://fabiandistler.github.io/fmisc/reference/with_logging.md),
[`with_rate_limit()`](https://fabiandistler.github.io/fmisc/reference/with_rate_limit.md),
[`with_timing()`](https://fabiandistler.github.io/fmisc/reference/with_timing.md)

## Examples

``` r
if (FALSE) { # \dontrun{
flaky <- function(x) {
  if (runif(1) < 0.7) stop("transient")
  x * 2
}
robust <- with_retry(flaky, max_tries = 5, backoff = 0.1)
robust(21)
} # }
```
