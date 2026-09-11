# fmisc: Miscellaneous R Utilities

Provides utility functions for R package development.

## Smart Parallel Computing

The fmisc package includes a comprehensive parallel computing framework
that automatically selects the best backend based on your operating
system and available packages.

Key function:

- [`smart_parallel_apply()`](https://fabiandistler.github.io/fmisc/reference/smart_parallel_apply.md) -
  Universal parallel apply with automatic backend detection

The framework supports multiple backends including mclapply, parLapply,
doParallel, doMC, furrr, and future, with intelligent OS-aware
selection.

## Function Decorators

A composable toolkit of "function operators" for cross-cutting concerns:
[`with_retry()`](https://fabiandistler.github.io/fmisc/reference/with_retry.md),
[`with_timing()`](https://fabiandistler.github.io/fmisc/reference/with_timing.md),
[`with_logging()`](https://fabiandistler.github.io/fmisc/reference/with_logging.md),
[`with_cache()`](https://fabiandistler.github.io/fmisc/reference/with_cache.md),
and
[`with_rate_limit()`](https://fabiandistler.github.io/fmisc/reference/with_rate_limit.md).
Wrappers stack with the native pipe or via
[`decorate()`](https://fabiandistler.github.io/fmisc/reference/decorate.md),
and can be inspected with
[`is_decorated()`](https://fabiandistler.github.io/fmisc/reference/is_decorated.md)
and
[`undecorate()`](https://fabiandistler.github.io/fmisc/reference/undecorate.md).

## Custom Linting Rules

The package provides custom flir rules available in the package
installation directory and can be accessed via
[`get_flir_rules()`](https://fabiandistler.github.io/fmisc/reference/get_flir_rules.md).

## See also

Useful links:

- <https://github.com/fabiandistler/fmisc>

- <https://fabiandistler.github.io/fmisc/>

- Report bugs at <https://github.com/fabiandistler/fmisc/issues>

## Author

**Maintainer**: Fabian Distler <fdistlermpi@gmail.com>

Authors:

- Fabian Distler <fdistlermpi@gmail.com>
