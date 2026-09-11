# Add a comprehensive Makefile for R package development

Creates a feature-rich Makefile in your package root directory with
targets for common R package development tasks including building,
checking, testing, documentation, code quality, and more.

## Usage

``` r
use_make2(open = interactive(), overwrite = FALSE)
```

## Arguments

- open:

  Whether to open the newly created Makefile for editing. Default is
  `TRUE` in interactive sessions.

- overwrite:

  Whether to overwrite an existing Makefile. If `FALSE` (the default)
  and a Makefile already exists, you are asked for confirmation in
  interactive sessions; non-interactive sessions error instead of
  silently replacing the file.

## Value

Invisibly returns the path to the created Makefile.

## Details

Run `make help` to see available targets Quick start: `make all` -
document, build, and check package `make test` - run tests
`make deps-dev` - install development dependencies

## Examples

``` r
if (FALSE) { # \dontrun{
# Create Makefile in current package
use_make2()

# Create without opening
use_make2(open = FALSE)

# Replace an existing Makefile without prompting
use_make2(overwrite = TRUE)
} # }
```
