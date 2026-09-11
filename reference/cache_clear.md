# Clear or inspect a cached function's cache

Clear or inspect a cached function's cache

## Usage

``` r
cache_clear(f)

cache_info(f)
```

## Arguments

- f:

  A function previously wrapped with
  [`with_cache()`](https://fabiandistler.github.io/fmisc/reference/with_cache.md).

## Value

`cache_clear()` returns `NULL` invisibly. `cache_info()` returns a list
with `backend` (`"cachem"`), `size`, `max_n`, and `max_age`.

## See also

Other decorators:
[`decorate()`](https://fabiandistler.github.io/fmisc/reference/decorate.md),
[`fmisc_decorators`](https://fabiandistler.github.io/fmisc/reference/fmisc_decorators.md),
[`is_decorated()`](https://fabiandistler.github.io/fmisc/reference/is_decorated.md),
[`print.fmisc_decorated()`](https://fabiandistler.github.io/fmisc/reference/print.fmisc_decorated.md),
[`undecorate()`](https://fabiandistler.github.io/fmisc/reference/undecorate.md),
[`with_cache()`](https://fabiandistler.github.io/fmisc/reference/with_cache.md),
[`with_logging()`](https://fabiandistler.github.io/fmisc/reference/with_logging.md),
[`with_rate_limit()`](https://fabiandistler.github.io/fmisc/reference/with_rate_limit.md),
[`with_retry()`](https://fabiandistler.github.io/fmisc/reference/with_retry.md),
[`with_timing()`](https://fabiandistler.github.io/fmisc/reference/with_timing.md)
