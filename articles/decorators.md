# Function Decorators and the R Ecosystem

## Introduction

`fmisc` ships a small toolkit of composable function operators
(“decorators”):
[`with_retry()`](https://fabiandistler.github.io/fmisc/reference/with_retry.md),
[`with_timing()`](https://fabiandistler.github.io/fmisc/reference/with_timing.md),
[`with_logging()`](https://fabiandistler.github.io/fmisc/reference/with_logging.md),
[`with_cache()`](https://fabiandistler.github.io/fmisc/reference/with_cache.md),
and
[`with_rate_limit()`](https://fabiandistler.github.io/fmisc/reference/with_rate_limit.md).
They cover the common cross-cutting concerns without pulling in heavy
dependencies, compose freely with the native pipe, and can be inspected
([`print()`](https://rdrr.io/r/base/print.html)), unwrapped
([`undecorate()`](https://fabiandistler.github.io/fmisc/reference/undecorate.md)),
and tested in isolation.

They intentionally stay minimal. This vignette summarises when to keep
using them and when to reach for a dedicated package instead.

## Decorators vs. the ecosystem

### Retries: `with_retry()` vs `purrr::insistently()`

Use
[`with_retry()`](https://fabiandistler.github.io/fmisc/reference/with_retry.md)
when you need exponential backoff with jitter, selective retry via
`.on_error`, and a retry callback — with no dependencies beyond `cli`.

Reach for
[`purrr::insistently()`](https://purrr.tidyverse.org/reference/insistently.html)
(or
[`purrr::quietly()`](https://purrr.tidyverse.org/reference/quietly.html)
/
[`purrr::safely()`](https://purrr.tidyverse.org/reference/safely.html))
when you are already inside a `purrr` pipeline and want retry semantics
that integrate with its adverb style. Note that `insistently()` retries
on *any* error unless combined with `rate_backoff()`, and does not offer
exponential backoff with jitter by itself.

### Caching: `with_cache()` vs `memoise` + `cachem`

There is no contest here — because
[`with_cache()`](https://fabiandistler.github.io/fmisc/reference/with_cache.md)
*is* a facade over
[`memoise::memoise()`](https://memoise.r-lib.org/reference/memoise.html)
backed by
[`cachem::cache_mem()`](https://cachem.r-lib.org/reference/cache_mem.html):

``` r

fast <- with_cache(slow, .max_size = 1024, .ttl = 3600)
```

`.max_size` maps to `cachem`’s `max_n` (LRU eviction), `.ttl` to
`max_age`. If you need more than an in-memory LRU/TTL cache — disk
persistence (`cache_disk`), shared caches, or cache pruning — use
`memoise` directly; every `cachem` backend is one argument away:

``` r

memo <- memoise::memoise(slow, cache = cachem::cache_disk("~/.cache"))
```

### Rate limiting: `with_rate_limit()` vs `ratelimitr`

[`with_rate_limit()`](https://fabiandistler.github.io/fmisc/reference/with_rate_limit.md)
enforces at most `n` calls per rolling `period` seconds, either sleeping
(`.wait = TRUE`) or raising `"fmisc_rate_limit_exceeded"`.

For multi-function rate limiting across a group of calls, token-bucket
semantics, or self-resetting rate-limited functions with finer control,
use `ratelimitr::limit_rate()`.

### HTTP-specific throttling

**Burst-tolerant rate limiting is deliberately not implemented in
fmisc.** The strict rolling window is intentional: it is predictable,
easy to reason about, and matches how most API quotas are documented. If
you need burst tolerance for HTTP traffic (allowing short spikes up to a
bucket capacity while staying under a long-run average), do not reach
for this decorator — use
[`httr2::req_throttle()`](https://httr2.r-lib.org/reference/req_throttle.html),
which implements a proper token-bucket scheme and integrates with
httr2’s request pipeline:

``` r

request("https://api.example.com") |>
  req_throttle(rate = 10 / 1) |>
  req_perform()
```

## Inspecting and unwrapping

Decorators record what was applied, so decorated functions explain
themselves:

``` r

f <- function(x) x + 1
g <- f |>
  fmisc::with_retry(max_tries = 3L, backoff = 0) |>
  fmisc::with_timing(.report = "attribute")
print(g)
#> <fmisc_decorated>
#>   with_timing(.report = "attribute")
#>   with_retry(max_tries = 3L, backoff = 0)
#> -> structure(function (...) {    for (attempt in seq_len(max...
```

Peel layers off with
[`undecorate()`](https://fabiandistler.github.io/fmisc/reference/undecorate.md):
one layer by default, or all of them with `depth = Inf`.

``` r

identical(fmisc::undecorate(g, depth = Inf), f)
#> [1] TRUE
```
