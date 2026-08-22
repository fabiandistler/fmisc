
<!-- README.md is generated from README.Rmd. Please edit that file -->

# fmisc

<!-- badges: start -->

[![R-CMD-check](https://github.com/fabiandistler/fmisc/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/fabiandistler/fmisc/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Various utilities for software development in R: composable function
decorators, memory-aware chunked processing, smart parallel apply, rich
error messages, and package-development helpers.

## Features

- **Function decorators**: stackable function operators — retry with
  exponential backoff (`with_retry()`), timing (`with_timing()`),
  logging (`with_logging()`), memoisation (`with_cache()`), and rate
  limiting (`with_rate_limit()`). Compose with `decorate()`, inspect
  with `is_decorated()`, unwrap with `undecorate()`.
- **Chunking & RAM management**: process data larger than memory via
  `process_with_chunks()`, with automatic chunk sizing, cross-platform
  RAM monitoring (Rcpp-accelerated), and disk spillover.
- **Smart parallel computing**: `smart_parallel_apply()` picks an
  OS-appropriate backend automatically and falls back to sequential
  processing when no backend is available.
- **Better errors**: `stop2()` produces rich, `{interpolated}` error
  messages via cli/rlang with a base-R fallback.
- **Development tools**: a best-practices function template
  (`use_function_template()`), a package Makefile (`use_make2()`), and
  custom [flir](https://flir.etiennebacher.com/) lint rules
  (`get_flir_rules()`).

## Installation

You can install the development version of fmisc from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("fabiandistler/fmisc")
```

## Function Decorators

``` r
library(fmisc)

flaky <- function(x) {
  if (runif(1) < 0.7) stop2("transient failure")
  x * 2
}

robust <- flaky |>
  with_retry(max_tries = 5, backoff = 0.1) |>
  with_logging()

robust(21)
```

## Chunking & RAM Management

``` r
big_df <- data.frame(x = rnorm(1e7), y = runif(1e7))

result <- process_with_chunks(
  big_df,
  process_fn = function(chunk) colMeans(chunk),
  combine_fn = function(parts) rowMeans(do.call(rbind, parts)),
  max_ram_mb = 512,
  verbose = FALSE
)
```

## Smart Parallel Computing

``` r
results <- smart_parallel_apply(1:1000, function(i) sqrt(i))
```

## Development Tools

### Function Template

Create new R functions from a comprehensive best-practices template:

``` r
library(fmisc)

# Create a new function file with tidyverse-style template
use_function_template("my_function")
```

The template includes:

- Roxygen2 documentation patterns
- Argument ordering checklist (data → descriptors → … → details)
- Multiple validation options (stopifnot, cli, rlang, checkmate)
- Dots handling patterns
- Error handling with custom error constructors
- Design principles checklist

### Makefile for R Packages

Add a comprehensive Makefile for package development:

``` r
# Add Makefile with common targets
use_make2()

# Then use make commands in your terminal
# make all      - document, build, and check
# make test     - run tests
# make help     - see all available targets
```

## Linting

### flir Custom Rules

fmisc bundles custom rules for [flir](https://flir.etiennebacher.com/).
To use them, add fmisc to the `from-package` field in your project’s
`flir/config.yml`:

``` yaml
from-package:
  - fmisc
```

You can also get the path to the bundled rules directly:

``` r
get_flir_rules()
```

Available rules:

- `deprecated-sample-n`: replaces dplyr’s deprecated `sample_n()` with
  `slice_sample(n = )`
- `deprecated-sample-frac`: replaces dplyr’s deprecated `sample_frac()`
  with `slice_sample(prop = )`

See `vignette("using-fmisc")` for details, including how to write your
own rules.
