# A fake `claude` executable for agent_run() tests.
#
# local_fake_claude() copies fixtures/fake-claude.R as `claude` into a fresh
# temp dir, puts that dir first on PATH and selects a scenario via
# FAKE_CLAUDE_SCENARIO.
# Both variables are restored when the calling test ends. The script is
# created at test time so its exec bit cannot get lost in the build tarball.
#
# Scenarios print the result shape `claude -p --output-format json` emits
# (fields trimmed from a live 2.1.306 run):
#   success     structured_output, exit 0
#   echo        structured_output = what the fake received (argv, stdin, wd,
#               which auth/provider variables were set, names only), exit 0
#   refusal     success without structured_output, exit 0
#   max_turns   is_error, subtype error_max_turns, exit 1
#   auth_error  is_error, authentication failure text, exit 1
#   garbage     non-JSON stdout, exit 0
#   hang        starts a grandchild `sleep`, writes both PIDs to
#               FAKE_CLAUDE_PIDFILE, then sleeps

local_fake_claude <- function(scenario = "success", envir = parent.frame()) {
  bin_dir <- tempfile("fake-claude-")
  dir.create(bin_dir)
  path <- file.path(bin_dir, "claude")
  # An absolute shebang: R CMD check --as-cran puts a guard `Rscript` on PATH
  # that refuses to run, so `#!/usr/bin/env Rscript` would fail there.
  writeLines(
    c(
      paste0("#!", file.path(R.home("bin"), "Rscript")),
      readLines(testthat::test_path("fixtures", "fake-claude.R"))
    ),
    path
  )
  Sys.chmod(path, "0755")

  old <- Sys.getenv(c("PATH", "FAKE_CLAUDE_SCENARIO", "R_TESTS"), unset = NA)
  Sys.setenv(
    PATH = paste(bin_dir, old[["PATH"]], sep = .Platform$path.sep),
    FAKE_CLAUDE_SCENARIO = scenario
  )
  # R CMD check sets R_TESTS to a startup file relative to tests/; the fake's
  # Rscript would try to source it from workdir and fail.
  Sys.unsetenv("R_TESTS")
  do.call(
    on.exit,
    list(substitute(restore_env(old)), add = TRUE),
    envir = envir
  )
  invisible(path)
}

# Set or unset environment variables from a named vector where NA means unset.
restore_env <- function(old) {
  unset <- is.na(old)
  if (any(unset)) {
    Sys.unsetenv(names(old)[unset])
  }
  if (any(!unset)) {
    do.call(Sys.setenv, as.list(old[!unset]))
  }
}

# Run `code` with an environment variable set (value) or unset (NA),
# restoring it afterwards.
with_env_var <- function(name, value, code) {
  old <- Sys.getenv(name, unset = NA)
  names(old) <- name
  on.exit(restore_env(old), add = TRUE)
  new <- stats::setNames(value, name)
  restore_env(new)
  force(code)
}

skip_if_no_fake_claude_support <- function() {
  testthat::skip_on_cran()
  testthat::skip_on_os("windows")
  testthat::skip_if_not_installed("processx")
  testthat::skip_if_not_installed("jsonlite")
}

schema_answer <- paste0(
  '{"type":"object","properties":{"answer":{"type":"string"}},',
  '"required":["answer"]}'
)
