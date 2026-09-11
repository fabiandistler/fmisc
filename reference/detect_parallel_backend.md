# Detect the best parallelization backend for the current environment

Detect the best parallelization backend for the current environment

## Usage

``` r
detect_parallel_backend()
```

## Value

A list containing backend information:

- backend:

  Character string identifying the backend. One of: "mclapply",
  "parLapply", "doParallel", "doMC", "future", "foreach", or
  "sequential"

- os_type:

  Operating system type (unix or windows)

- available_cores:

  Number of available CPU cores

- packages:

  List of available parallel packages

## See also

[`setup_parallel()`](https://fabiandistler.github.io/fmisc/reference/setup_parallel.md),
[`smart_parallel_apply()`](https://fabiandistler.github.io/fmisc/reference/smart_parallel_apply.md)

Other parallel:
[`print_parallel_info()`](https://fabiandistler.github.io/fmisc/reference/print_parallel_info.md),
[`setup_parallel()`](https://fabiandistler.github.io/fmisc/reference/setup_parallel.md),
[`smart_parallel_apply()`](https://fabiandistler.github.io/fmisc/reference/smart_parallel_apply.md),
[`stop_parallel()`](https://fabiandistler.github.io/fmisc/reference/stop_parallel.md)
