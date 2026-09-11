# Use the tidyverse-style function template

Creates a new R file based on the comprehensive function template that
includes best practices from the tidyverse style guide and design guide.
The template covers argument ordering, validation, error handling, dots
usage, and documentation patterns that are not automatically checked by
lintr/styler.

## Usage

``` r
use_function_template(name, open = interactive())
```

## Arguments

- name:

  Name of the R file to create (without .R extension). The file will be
  created in the R/ directory.

- open:

  Whether to open the newly created file for editing. Default is `TRUE`
  in interactive sessions.

## Value

Invisibly returns `TRUE` if the file was created, `FALSE` otherwise.

## Details

The template includes:

- Roxygen2 documentation with best practices

- Argument ordering checklist (data → descriptors → ... → details)

- Multiple validation options (stopifnot, cli, rlang, checkmate)

- Dots handling patterns

- NULL pattern for optional arguments

- Side-effect functions pattern

- Options object pattern

- Error constructor pattern

- Comprehensive design principles checklist

After creating the file, delete sections you don't need and customize
the function to your requirements.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a new function file from the template
use_function_template("my_function")

# Create without opening
use_function_template("my_function", open = FALSE)
} # }
```
