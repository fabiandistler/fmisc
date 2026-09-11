# Stop with Better Error Messages

A helper function that uses the best available error handling method.
Tries to use
[`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html) for
rich formatting, falls back to
[`rlang::abort()`](https://rlang.r-lib.org/reference/abort.html) for
better error handling, and ultimately uses base
[`stop()`](https://rdrr.io/r/base/stop.html) if neither is available.

## Usage

``` r
stop2(message, ..., .envir = parent.frame(), class = NULL)
```

## Arguments

- message:

  An error message string. Can include string interpolation using
  `{variable}` syntax which will be evaluated in `.envir`.

- ...:

  Additional arguments passed to the error function.

- .envir:

  Environment for string interpolation. Defaults to parent frame.

- class:

  Character vector of error classes (for cli and rlang).

## Value

This function does not return; it stops execution with an error.

## Details

This function implements a fallback mechanism for error handling:

- If cli is available, uses
  [`cli_abort`](https://cli.r-lib.org/reference/cli_abort.html) for
  rich, formatted error messages with color, styling support, and native
  string interpolation.

- If cli is not available but rlang is, uses
  [`abort`](https://rlang.r-lib.org/reference/abort.html) for structured
  error objects with better error handling capabilities.

- If neither package is available, falls back to base R's
  [`stop`](https://rdrr.io/r/base/stop.html) with `call. = FALSE` to
  follow tidyverse style conventions.

String interpolation with `{variable}` syntax is always supported:

- If cli is available, full cli interpolation and formatting features
  are used (including `{.val}`, `{.field}`, etc.).

- If cli is not available but glue is, glue's interpolation engine is
  used, supporting `{{{literal}}}` escaping.

- If neither package is available, a simple fallback interpolation
  handles basic `{expression}` syntax. This fallback does not support
  advanced features like `{{{literal}}}` escaping for literal braces, or
  cli's special formatting syntax.

## See also

[`cli_abort`](https://cli.r-lib.org/reference/cli_abort.html),
[`abort`](https://rlang.r-lib.org/reference/abort.html),
[`stop`](https://rdrr.io/r/base/stop.html)

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage
stop2("Something went wrong")

# With variable interpolation (works regardless of installed packages)
x <- 5
stop2("Expected value < 3, got {x}")

# With expression interpolation
df <- data.frame(a = 1:3)
stop2("Expected 5 rows, got {nrow(df)}")

# With multiple interpolations
expected <- 10
actual <- 5
stop2("Expected {expected}, got {actual}")

# With custom error class
stop2("Invalid input", class = "invalid_input_error")
} # }
```
