# Setup parallel backend with automatic configuration

Setup parallel backend with automatic configuration

## Usage

``` r
setup_parallel(n_cores = NULL, backend = NULL, verbose = TRUE)
```

## Arguments

- n_cores:

  Number of cores to use. Default is NULL (auto-detect and use all but
  one core to keep system responsive)

- backend:

  Force a specific backend. Default is NULL (auto-detect). Options:
  "mclapply", "parLapply", "doParallel", "doMC", "furrr", "foreach",
  "sequential"

- verbose:

  Print setup information. Default is TRUE

## Value

A list with cluster object (if applicable) and backend information:

- cluster:

  Cluster object (or NULL if not applicable)

- backend:

  Character string of selected backend

- n_cores:

  Number of cores configured

- info:

  Backend detection information

## See also

[`detect_parallel_backend()`](https://fabiandistler.github.io/fmisc/reference/detect_parallel_backend.md),
[`stop_parallel()`](https://fabiandistler.github.io/fmisc/reference/stop_parallel.md),
[`smart_parallel_apply()`](https://fabiandistler.github.io/fmisc/reference/smart_parallel_apply.md)

Other parallel:
[`detect_parallel_backend()`](https://fabiandistler.github.io/fmisc/reference/detect_parallel_backend.md),
[`print_parallel_info()`](https://fabiandistler.github.io/fmisc/reference/print_parallel_info.md),
[`smart_parallel_apply()`](https://fabiandistler.github.io/fmisc/reference/smart_parallel_apply.md),
[`stop_parallel()`](https://fabiandistler.github.io/fmisc/reference/stop_parallel.md)
