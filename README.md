# fmisc - Custom Linting Rules for R Code

[![R-CMD-check](https://github.com/fabiandistler/fmisc/workflows/R-CMD-check/badge.svg)](https://github.com/fabiandistler/fmisc/actions)

`fmisc` provides custom linting rules for both **lintr** and **flir** packages, enabling standardized code quality checks and automatic refactoring patterns across R projects.

## Features

- **lintr custom linters**: Ready-to-use linter functions that integrate seamlessly with lintr
- **flir custom rules**: YAML-based rules for automatic code detection and fixing
- **Easy integration**: Simple setup for both linting systems

## Installation

```r
# Install from GitHub
# install.packages("remotes")
remotes::install_github("fabiandistler/fmisc")
```

## Usage

### Using lintr Custom Linters

```r
library(lintr)
library(fmisc)

# Use individual linters
lint("my_script.R", linters = todo_fixme_linter())

# Combine with default linters
lint("my_script.R", linters = c(
  linters_with_defaults(),
  todo_fixme_linter(),
  deprecated_function_linter()
))

# In your project's .lintr file:
# linters: linters_with_defaults(
#   todo_fixme_linter = todo_fixme_linter(),
#   deprecated_function_linter = deprecated_function_linter()
# )
```

### Using flir Custom Rules

```r
library(flir)

# Set up flir in your project
setup_flir()

# Edit flir/config.yml and add fmisc to from-package:
# from-package:
#   - fmisc

# Check your code
lint_dir()

# Apply automatic fixes
fix_dir()
```

Alternatively, you can manually get the rules path:

```r
library(fmisc)
get_flir_rules()
```

## Available Linters (lintr)

### `todo_fixme_linter()`

Identifies TODO, FIXME, XXX, and HACK comments in your code. Helps track tasks that need attention.

**Example:**
```r
# This will trigger the linter
# TODO: implement this feature
x <- 1
```

### `deprecated_function_linter()`

Detects usage of deprecated R functions and suggests modern alternatives:
- `sapply()` → use `vapply()` or `purrr::map_*()`
- `require()` in packages → use `library()`

**Example:**
```r
# This will trigger the linter
result <- sapply(1:10, sqrt)  # Use vapply() instead
```

## Available Rules (flir)

### `replace-t-with-true`
Replaces `T` with `TRUE` for better code clarity.

### `replace-f-with-false`
Replaces `F` with `FALSE` for better code clarity.

### `deprecated-sample-n`
Updates deprecated `sample_n()` to modern `slice_sample()`.

**Before:**
```r
sample_n(mtcars, 10)
```

**After:**
```r
slice_sample(mtcars, n = 10)
```

### `deprecated-sample-frac`
Updates deprecated `sample_frac()` to modern `slice_sample()`.

### `use-seq-along`
Replaces `1:length(x)` with safer `seq_along(x)`.

**Before:**
```r
for (i in 1:length(x)) { ... }
```

**After:**
```r
for (i in seq_along(x)) { ... }
```

## Creating Your Own Rules

### Adding lintr Linters

Create a new R file in `R/` directory:

```r
#' My custom linter
#'
#' @export
my_custom_linter <- function() {
  xpath <- "//SYMBOL[text() = 'bad_pattern']"

  lintr::make_linter_from_xpath(
    xpath = xpath,
    lint_message = "Found bad pattern",
    type = "warning"
  )
}
```

### Adding flir Rules

Create a new YAML file in `inst/flir/rules/`:

```yaml
id: my-custom-rule
language: r
severity: warning
rule:
  pattern: old_function($ARG)
message: "Use new_function instead"
fix: new_function(~~ARG)
```

## Documentation

- [lintr documentation](https://lintr.r-lib.org/)
- [lintr - Creating custom linters](https://lintr.r-lib.org/articles/creating_linters.html)
- [flir documentation](https://flir.etiennebacher.com/)
- [flir - Adding new rules](https://flir.etiennebacher.com/articles/adding_rules.html)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details.
