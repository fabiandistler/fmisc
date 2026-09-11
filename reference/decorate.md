# Compose several decorators onto a function

Applies decorators to `f` left-to-right so that `decorate(f, d1, d2)` is
equivalent to `d2(d1(f))` and reads outside-in. Each decorator must be a
unary function `function(g) -> function`. For decorators with
configuration, wrap them in a closure or use the native pipe directly
(which is the recommended idiom).

## Usage

``` r
decorate(f, ...)
```

## Arguments

- f:

  A function to decorate.

- ...:

  Decorators — each a unary function taking `f` and returning a wrapped
  function.

## Value

The decorated function.

## See also

Other decorators:
[`cache_clear()`](https://fabiandistler.github.io/fmisc/reference/cache_clear.md),
[`fmisc_decorators`](https://fabiandistler.github.io/fmisc/reference/fmisc_decorators.md),
[`is_decorated()`](https://fabiandistler.github.io/fmisc/reference/is_decorated.md),
[`print.fmisc_decorated()`](https://fabiandistler.github.io/fmisc/reference/print.fmisc_decorated.md),
[`undecorate()`](https://fabiandistler.github.io/fmisc/reference/undecorate.md),
[`with_cache()`](https://fabiandistler.github.io/fmisc/reference/with_cache.md),
[`with_logging()`](https://fabiandistler.github.io/fmisc/reference/with_logging.md),
[`with_rate_limit()`](https://fabiandistler.github.io/fmisc/reference/with_rate_limit.md),
[`with_retry()`](https://fabiandistler.github.io/fmisc/reference/with_retry.md),
[`with_timing()`](https://fabiandistler.github.io/fmisc/reference/with_timing.md)

## Examples

``` r
# \donttest{
add1 <- function(x) x + 1
g <- decorate(
  add1,
  function(fn) with_retry(fn, max_tries = 2, backoff = 0),
  function(fn) with_timing(fn, .threshold = Inf)
)
g(41)
#> [1] 42
# }
```
