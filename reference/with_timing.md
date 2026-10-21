# Measure a function's elapsed wall-clock time

Wraps `f` so each call is timed with
[`proc.time()`](https://rdrr.io/r/base/proc.time.html). Reports elapsed
time on both success and failure (via
[`on.exit()`](https://rdrr.io/r/base/on.exit.html)), either as a cli
message, attached as an `"elapsed"` attribute on the return value, or
passed to a user callback.

## Usage

``` r
with_timing(
  f,
  ...,
  .report = c("message", "attribute", "callback"),
  .callback = NULL,
  .threshold = 0
)
```

## Arguments

- f:

  A function to wrap.

- ...:

  Reserved for future extension.

- .report:

  One of `"message"` (default; cli info alert), `"attribute"` (attach
  `attr(result, "elapsed")`), `"callback"` (invoke
  `.callback(name, elapsed, ok)`).

- .callback:

  Function used when `.report = "callback"`.

- .threshold:

  Non-negative numeric. Only report when elapsed time in seconds is
  `>= .threshold`. Default `0`.

## Value

A function that forwards its arguments to `f`.

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
[`with_retry()`](https://fabiandistler.github.io/fmisc/reference/with_retry.md)

## Examples

``` r
# \donttest{
g <- with_timing(function(x) {
  Sys.sleep(0.05)
  x
}, .threshold = 0)
g(42)
#> ℹ function(x) { took 0.050s
#> [1] 42
# }
```
