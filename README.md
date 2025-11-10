# fmisc

<!-- badges: start -->
<!-- badges: end -->

Miscellaneous R package development utilities. Currently provides a comprehensive Makefile template for R package development workflows.

## Installation

You can install the development version of fmisc from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("fabiandistler/fmisc")
```

## Usage

### Adding a Makefile to your R package

The main feature is `use_make2()`, which creates a comprehensive Makefile with useful targets for R package development:

``` r
library(fmisc)

# Add Makefile to your package
use_make2()
```

This creates a Makefile with the following capabilities:

**Package Management:**
- `make install` - Install the package locally
- `make build` - Build source tarball
- `make check` - Run R CMD check (CRAN-style)
- `make check-quick` - Quick check without vignettes

**Testing & Quality:**
- `make test` - Run tests with testthat
- `make coverage` - Generate test coverage report
- `make lint` - Lint code with lintr
- `make style` - Auto-format code with styler
- `make spellcheck` - Run spell check

**Documentation:**
- `make document` - Generate documentation with roxygen2
- `make site` - Build pkgdown website
- `make site-preview` - Build and open pkgdown website
- `make readme` - Render README from Rmd

**Development Workflow:**
- `make deps` - Install package dependencies
- `make deps-dev` - Install development dependencies
- `make load` - Load package for interactive use
- `make clean` - Remove generated files

**Convenience:**
- `make all` - document + build + check (default)
- `make help` - Show all available targets

### Quick Start

After adding the Makefile to your package:

```bash
# See all available targets
make help

# Install development dependencies
make deps-dev

# Run the standard workflow (document, build, check)
make all

# Run tests
make test

# Build pkgdown site
make site
```

## Credits

The package name parsing approach in the Makefile template is based on work by @jimhester and @yihui. See the [knitr Makefile](https://github.com/yihui/knitr/blob/dc5ead7bcfc0ebd2789fe99c527c7d91afb3de4a/Makefile#L1-L4) for the original implementation.

## License

MIT © Fabian Distler
