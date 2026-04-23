
<!-- README.md is generated from README.Rmd. Please edit that file -->

# fmisc

<!-- badges: start -->

[![R-CMD-check](https://github.com/fabiandistler/fmisc/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/fabiandistler/fmisc/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Various utilities for software development in R.

## Installation

You can install the development version of fmisc from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("fabiandistler/fmisc")
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
- Argument ordering checklist (data → descriptors → ... → details)
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

### lintr Custom Linters

``` r
library(lintr)
library(fmisc)

lint("my_script.R", linters = c(
  linters_with_defaults(),
  todo_fixme_linter(),
  deprecated_function_linter()
))
```

Available linters:

- `todo_fixme_linter()`: Detects TODO/FIXME/XXX/HACK comments
- `deprecated_function_linter()`: Flags deprecated functions (e.g. `sapply()`, `require()`)

### flir Custom Rules

Rules are bundled in the package. To use them, add fmisc to the
`from-package` field in your project's `flir/config.yml`:

``` r
get_flir_rules()
```

Available rules: `replace-t-with-true`, `replace-f-with-false`,
`deprecated-sample-n`, `deprecated-sample-frac`, `use-seq-along`.
