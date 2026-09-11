# Print a decorated function's wrapper stack

Shows the decorators applied to `f`, outermost first, followed by the
innermost wrapped function.

## Usage

``` r
# S3 method for class 'fmisc_decorated'
print(x, ...)
```

## Arguments

- x:

  A function with class `"fmisc_decorated"`.

- ...:

  Unused.

## Value

`x`, invisibly.

## See also

Other decorators:
[`cache_clear()`](https://fabiandistler.github.io/fmisc/reference/cache_clear.md),
[`decorate()`](https://fabiandistler.github.io/fmisc/reference/decorate.md),
[`fmisc_decorators`](https://fabiandistler.github.io/fmisc/reference/fmisc_decorators.md),
[`is_decorated()`](https://fabiandistler.github.io/fmisc/reference/is_decorated.md),
[`undecorate()`](https://fabiandistler.github.io/fmisc/reference/undecorate.md),
[`with_cache()`](https://fabiandistler.github.io/fmisc/reference/with_cache.md),
[`with_logging()`](https://fabiandistler.github.io/fmisc/reference/with_logging.md),
[`with_rate_limit()`](https://fabiandistler.github.io/fmisc/reference/with_rate_limit.md),
[`with_retry()`](https://fabiandistler.github.io/fmisc/reference/with_retry.md),
[`with_timing()`](https://fabiandistler.github.io/fmisc/reference/with_timing.md)
