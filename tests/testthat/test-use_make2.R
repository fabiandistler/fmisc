# The Makefile template sends pkgdown output to _site/ and leaves docs/ to
# hand-written documentation.

local_make_package <- function(env = parent.frame()) {
  skip_if_not_installed("withr")
  skip_if(!nzchar(Sys.which("make")), "make is not available")

  pkg_dir <- withr::local_tempdir(.local_envir = env)
  writeLines(
    c("Package: mkpkg", "Version: 0.0.1"),
    file.path(pkg_dir, "DESCRIPTION")
  )
  withr::local_dir(pkg_dir, .local_envir = env)
  suppressMessages(use_make2(open = FALSE))
  pkg_dir
}

run_make <- function(...) {
  suppressWarnings(system2("make", c(...), stdout = TRUE, stderr = TRUE))
}

test_that("make clean removes the pkgdown site and keeps docs/", {
  pkg_dir <- local_make_package()
  dir.create(file.path(pkg_dir, "docs", "adr"), recursive = TRUE)
  writeLines("# ADR", file.path(pkg_dir, "docs", "adr", "0001-decision.md"))
  dir.create(file.path(pkg_dir, "_site"))
  writeLines("<html></html>", file.path(pkg_dir, "_site", "index.html"))

  run_make("clean")

  expect_true(file.exists(file.path(
    pkg_dir,
    "docs",
    "adr",
    "0001-decision.md"
  )))
  expect_false(dir.exists(file.path(pkg_dir, "_site")))
})

test_that("the pkgdown targets build into _site/", {
  local_make_package()

  # -n prints the recipes without running R.
  recipes <- run_make("-n", "site-preview", "setup-ci")
  pkgdown_calls <- grep(
    "pkgdown::build_site|pkgdown::preview_site|use_pkgdown",
    recipes,
    value = TRUE
  )

  expect_length(pkgdown_calls, 3)
  expect_match(pkgdown_calls, "destination = '_site'|destdir = '_site'")
})
