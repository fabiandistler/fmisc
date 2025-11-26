
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
