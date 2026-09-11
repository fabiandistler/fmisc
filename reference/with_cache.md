# Memoise a function's results

Wraps `f` so that repeated calls with the same arguments return a cached
value. This is a thin facade over
[`memoise::memoise()`](https://memoise.r-lib.org/reference/memoise.html)
backed by
[`cachem::cache_mem()`](https://cachem.r-lib.org/reference/cache_mem.html):
`memoise` hashes arguments internally, and `cache_mem` provides LRU
eviction (`.max_size`) and time-to-live (`.ttl`).

## Usage

``` r
with_cache(f, ..., .max_size = Inf, .ttl = Inf)
```

## Arguments

- f:

  A function to wrap.

- ...:

  Reserved for future extension.

- .max_size:

  Maximum number of cached entries. `Inf` (default) for unbounded; when
  exceeded, least-recently-used entries are evicted.

- .ttl:

  Time-to-live in seconds for cached entries. `Inf` (default) never
  expires.

## Value

A function that forwards its arguments to `f`. Attach
[`cache_clear()`](https://fabiandistler.github.io/fmisc/reference/cache_clear.md)
and
[`cache_info()`](https://fabiandistler.github.io/fmisc/reference/cache_clear.md)
helpers via
[`cache_clear()`](https://fabiandistler.github.io/fmisc/reference/cache_clear.md)
and
[`cache_info()`](https://fabiandistler.github.io/fmisc/reference/cache_clear.md).

## See also

[`cache_clear()`](https://fabiandistler.github.io/fmisc/reference/cache_clear.md),
[`cache_info()`](https://fabiandistler.github.io/fmisc/reference/cache_clear.md)

Other decorators:
[`cache_clear()`](https://fabiandistler.github.io/fmisc/reference/cache_clear.md),
[`decorate()`](https://fabiandistler.github.io/fmisc/reference/decorate.md),
[`fmisc_decorators`](https://fabiandistler.github.io/fmisc/reference/fmisc_decorators.md),
[`is_decorated()`](https://fabiandistler.github.io/fmisc/reference/is_decorated.md),
[`print.fmisc_decorated()`](https://fabiandistler.github.io/fmisc/reference/print.fmisc_decorated.md),
[`undecorate()`](https://fabiandistler.github.io/fmisc/reference/undecorate.md),
[`with_logging()`](https://fabiandistler.github.io/fmisc/reference/with_logging.md),
[`with_rate_limit()`](https://fabiandistler.github.io/fmisc/reference/with_rate_limit.md),
[`with_retry()`](https://fabiandistler.github.io/fmisc/reference/with_retry.md),
[`with_timing()`](https://fabiandistler.github.io/fmisc/reference/with_timing.md)

## Examples

``` r
# \donttest{
calls <- 0
slow <- function(x) {
  calls <<- calls + 1
  x * 2
}
fast <- with_cache(slow)
fast(21)
#> [1] 42
fast(21)
#> [1] 42
calls
#> [1] 1
# }
```
