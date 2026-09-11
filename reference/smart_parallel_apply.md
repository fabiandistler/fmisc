# Smart Parallel Framework Selector

This module provides intelligent selection and setup of R
parallelization frameworks based on OS capabilities and available
packages.

## Usage

``` r
smart_parallel_apply(X, FUN, n_cores = NULL, ..., setup = NULL)
```

## Arguments

- X:

  A vector or list to iterate over

- FUN:

  Function to apply to each element

- n_cores:

  Number of cores to use (NULL for auto-detection)

- ...:

  Additional arguments passed to FUN

- setup:

  Advanced: Optional pre-configured setup object from
  [`setup_parallel()`](https://fabiandistler.github.io/fmisc/reference/setup_parallel.md).
  If provided, n_cores is ignored. Most users should omit this
  parameter. Reusing setup is more efficient for multiple operations.

## Value

A list of results

## See also

[`setup_parallel()`](https://fabiandistler.github.io/fmisc/reference/setup_parallel.md),
[`detect_parallel_backend()`](https://fabiandistler.github.io/fmisc/reference/detect_parallel_backend.md)

Other parallel:
[`detect_parallel_backend()`](https://fabiandistler.github.io/fmisc/reference/detect_parallel_backend.md),
[`print_parallel_info()`](https://fabiandistler.github.io/fmisc/reference/print_parallel_info.md),
[`setup_parallel()`](https://fabiandistler.github.io/fmisc/reference/setup_parallel.md),
[`stop_parallel()`](https://fabiandistler.github.io/fmisc/reference/stop_parallel.md)

## Examples

``` r
# \donttest{
# Simple parallel computation
result <- smart_parallel_apply(1:10, function(x) x^2)

# With additional arguments
result <- smart_parallel_apply(1:10, function(x, p) x^p, p = 3)
# }
```
