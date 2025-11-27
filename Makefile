# Makefile for R Package Development
# =================================
# h/t to @jimhester and @yihui for this parse block:
# https://github.com/yihui/knitr/blob/dc5ead7bcfc0ebd2789fe99c527c7d91afb3de4a/Makefile#L1-L4
# Note the portability change as suggested in the manual:
# https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Writing-portable-packages

# Parse package name and version from DESCRIPTION file
PKGNAME = `sed -n "s/Package: *\([^ ]*\)/\1/p" DESCRIPTION`
PKGVERS = `sed -n "s/Version: *\([^ ]*\)/\1/p" DESCRIPTION`

# R command
R := R --quiet --no-save --no-restore

# Build directory
BUILD_DIR := .

.PHONY: help all install build check test document clean deps lint style site coverage

# Default target
all: document build check

help:
	@echo "Available targets for R package development:"
	@echo ""
	@echo "  make install      - Install the package locally"
	@echo "  make build        - Build source tarball"
	@echo "  make check        - Run R CMD check"
	@echo "  make test         - Run tests with devtools::test()"
	@echo "  make document     - Generate documentation with roxygen2"
	@echo "  make site         - Build pkgdown website"
	@echo "  make coverage     - Generate test coverage report"
	@echo "  make lint         - Lint code with lintr"
	@echo "  make style        - Auto-format code with styler"
	@echo "  make deps         - Install package dependencies"
	@echo "  make clean        - Remove generated files"
	@echo "  make all          - document + build + check"
	@echo ""

# Install package dependencies
deps:
	@echo "Installing package dependencies..."
	$(R) -e "if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes')"
	$(R) -e "remotes::install_deps(dependencies = TRUE)"

# Install development dependencies
deps-dev: deps
	@echo "Installing development dependencies..."
	$(R) -e "pkgs <- c('devtools', 'roxygen2', 'testthat', 'pkgdown', 'lintr', 'styler', 'covr'); \
	         new_pkgs <- pkgs[!(pkgs %in% installed.packages()[,'Package'])]; \
	         if(length(new_pkgs)) install.packages(new_pkgs)"

# Generate documentation with roxygen2
document:
	@echo "Generating documentation..."
	$(R) -e "devtools::document()"

# Build source package
build: document
	@echo "Building package $(PKGNAME)..."
	$(R) CMD build $(BUILD_DIR)

# Install package locally
install: document
	@echo "Installing package $(PKGNAME)..."
	$(R) -e "devtools::install()"

# Run R CMD check
check: document
	@echo "Running R CMD check..."
	$(R) CMD build $(BUILD_DIR)
	$(R) CMD check --as-cran $(PKGNAME)_$(PKGVERS).tar.gz

# Run quick check (without building vignettes)
check-quick: document
	@echo "Running quick R CMD check..."
	$(R) -e "devtools::check(vignettes = FALSE)"

# Run tests
test:
	@echo "Running tests..."
	$(R) -e "devtools::test()"

# Run tests with coverage
coverage:
	@echo "Generating test coverage report..."
	$(R) -e "covr::package_coverage()"
	$(R) -e "covr::report()"

# Build pkgdown website
site:
	@echo "Building pkgdown website..."
	$(R) -e "pkgdown::build_site()"

# Preview pkgdown website
site-preview: site
	@echo "Opening pkgdown website..."
	$(R) -e "pkgdown::preview_site()"

# Lint code
lint:
	@echo "Linting code..."
	$(R) -e "lintr::lint_package()"

# Auto-format code
style:
	@echo "Styling code..."
	$(R) -e "styler::style_pkg()"

# Load package for interactive use
load:
	@echo "Loading package..."
	$(R) -e "devtools::load_all()"

# Create a new release
release: clean all
	@echo "Package $(PKGNAME) $(PKGVERS) ready for release"
	@echo "Run 'devtools::release()' in R to submit to CRAN"

# Clean up generated files
clean:
	@echo "Cleaning up..."
	@rm -rf $(PKGNAME).Rcheck/
	@rm -f $(PKGNAME)_*.tar.gz
	@rm -rf man/*.Rd
	@rm -rf docs/
	@rm -rf src/*.o src/*.so src/*.dll
	@find . -name '.Rhistory' -delete
	@find . -name '.RData' -delete
	@echo "Clean complete"

# Create package structure (for new packages)
init:
	@echo "Initializing package structure..."
	$(R) -e "usethis::create_package('$(PKGNAME)', rstudio = TRUE, open = FALSE)"
	$(R) -e "usethis::use_testthat()"
	$(R) -e "usethis::use_roxygen_md()"
	$(R) -e "usethis::use_package_doc()"

# Add common infrastructure files
setup-ci:
	@echo "Setting up CI/CD..."
	$(R) -e "usethis::use_github_actions()"
	$(R) -e "usethis::use_readme_rmd()"
	$(R) -e "usethis::use_news_md()"
	$(R) -e "usethis::use_pkgdown()"

# Run spell check
spellcheck:
	@echo "Running spell check..."
	$(R) -e "spelling::spell_check_package()"

# Update documentation and README
readme:
	@echo "Rendering README..."
	$(R) -e "devtools::build_readme()"
