# Rate-limit a function to N calls per period

Wraps `f` so at most `n` calls are permitted within any rolling
`period`-second window. When the limit is reached, either sleeps until a
slot opens (`.wait = TRUE`, the default) or raises an error of class
`"fmisc_rate_limit_exceeded"` (`.wait = FALSE`).

## Usage

``` r
with_rate_limit(f, n, period = 1, ..., .wait = TRUE)
```

## Arguments

- f:

  A function to wrap.

- n:

  Positive integer. Maximum calls per window.

- period:

  Positive numeric. Window length in seconds.

- ...:

  Reserved for future extension.

- .wait:

  Logical. If `TRUE` sleep to obey the limit; if `FALSE` error
  immediately when the limit would be exceeded.

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
[`with_retry()`](https://fabiandistler.github.io/fmisc/reference/with_retry.md),
[`with_timing()`](https://fabiandistler.github.io/fmisc/reference/with_timing.md)

## Examples

``` r
if (FALSE) { # \dontrun{
g <- with_rate_limit(function(x) x, n = 2, period = 1)
g(1)
g(2)
g(3) # third call sleeps until the window rolls
} # }
```
