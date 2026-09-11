# Log calls, results, and errors of a function

Wraps `f` with a lightweight logger emitting `"call"`, `"success"`, and
`"error"` events. The default logger uses cli alerts. Errors are logged
and re-raised unchanged.

## Usage

``` r
with_logging(
  f,
  ...,
  .logger = NULL,
  .log_args = TRUE,
  .log_result = FALSE,
  .name = NULL
)
```

## Arguments

- f:

  A function to wrap.

- ...:

  Reserved for future extension.

- .logger:

  Optional user function `function(event, data)`; `event` is one of
  `"call"`, `"success"`, `"error"`; `data` is a list with at least
  `name`, plus event-specific fields. Default `NULL` uses cli.

- .log_args:

  Logical. Whether to include a short deparse of the arguments in the
  `"call"` event. Default `TRUE`.

- .log_result:

  Logical. Whether to include a short deparse of the return value in the
  `"success"` event. Default `FALSE`.

- .name:

  Optional character name to display for the function. Defaults to the
  deparsed `f` symbol.

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
[`with_rate_limit()`](https://fabiandistler.github.io/fmisc/reference/with_rate_limit.md),
[`with_retry()`](https://fabiandistler.github.io/fmisc/reference/with_retry.md),
[`with_timing()`](https://fabiandistler.github.io/fmisc/reference/with_timing.md)

## Examples

``` r
# \donttest{
g <- with_logging(function(x, y) x + y, .log_result = TRUE)
g(1, 2)
#> ℹ call function(x, y) x + y(1, 2)
#> ✔ function(x, y) x + y -> 3
#> [1] 3
# }
```
