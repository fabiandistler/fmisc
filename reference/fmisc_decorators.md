# Composable Function Operators (Decorators)

A toolkit of composable "function operators" for cross-cutting concerns:
retries, timing, logging, caching, and rate-limiting. Each `with_*()`
takes a function as its first argument and returns a wrapped function
with the class `"fmisc_decorated"`. Wrappers are curry-friendly and
compose with the native pipe (see examples).

## See also

Other decorators:
[`cache_clear()`](https://fabiandistler.github.io/fmisc/reference/cache_clear.md),
[`decorate()`](https://fabiandistler.github.io/fmisc/reference/decorate.md),
[`is_decorated()`](https://fabiandistler.github.io/fmisc/reference/is_decorated.md),
[`print.fmisc_decorated()`](https://fabiandistler.github.io/fmisc/reference/print.fmisc_decorated.md),
[`undecorate()`](https://fabiandistler.github.io/fmisc/reference/undecorate.md),
[`with_cache()`](https://fabiandistler.github.io/fmisc/reference/with_cache.md),
[`with_logging()`](https://fabiandistler.github.io/fmisc/reference/with_logging.md),
[`with_rate_limit()`](https://fabiandistler.github.io/fmisc/reference/with_rate_limit.md),
[`with_retry()`](https://fabiandistler.github.io/fmisc/reference/with_retry.md),
[`with_timing()`](https://fabiandistler.github.io/fmisc/reference/with_timing.md)
