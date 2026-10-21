# Fixtures in fixtures/ci-logs/ are trimmed real job logs. Provenance:
# - r-lint.log: fmisc job 119051612142 (run 39548363573, PR #74).
# - style-unparsed.log: fmisc job 118820247137 (run 39478393347).
# - check-notes.log: fmisc job 119061442844 (run 39551481600, main; 6 NOTEs).
# - air-format.log: framing from fmisc job 119061442496, with the output of
#   a real local `air format . --check` (air 0.12.0) on two misformatted
#   files.
# - check-tests.log: real local `rcmdcheck::rcmdcheck()` output (R 4.3.3,
#   testthat 3.2.1) for fmisc plus a failing and an erroring test, framed
#   like the check-r-package step, rules rendered as in a UTF-8 session.
#   fmisc's own red R CMD check logs had expired (410 Gone).

test_that("lintr annotations become one lint finding per line", {
  local_ci_run(list(
    list(
      name = "r-lint",
      os = "ubuntu-latest",
      step = "lintr (.lintr)",
      log = "r-lint.log"
    )
  ))

  findings <- ci_failures()

  expect_equal(nrow(findings), 6)
  expect_equal(unique(findings$kind), "lint")
  expect_equal(findings$file[1], "R/chunking.R")
  expect_identical(findings$line[1], 186L)
  expect_equal(
    findings$message[1],
    paste(
      "[return_linter] Use implicit return behavior;",
      "explicit return() is not needed."
    )
  )
  expect_equal(findings$file[6], "R/stop2.R")
  expect_equal(unique(findings$job), "r-lint")
  expect_equal(unique(findings$os), "ubuntu-latest")
  expect_equal(unique(findings$step), "lintr (.lintr)")
})

test_that("air format-check failures name each file to reformat", {
  local_ci_run(list(
    list(
      name = "format-check",
      os = "ubuntu-latest",
      step = "Check formatting",
      log = "air-format.log"
    )
  ))

  findings <- ci_failures()

  expect_equal(findings$kind, c("format", "format"))
  expect_equal(findings$file, c("R/stop2.R", "R/zz.R"))
  expect_identical(findings$line, c(NA_integer_, NA_integer_))
  expect_equal(findings$message[1], "Would reformat: R/stop2.R")
})

test_that("R CMD check NOTEs keep their detail lines and source location", {
  local_ci_run(list(
    list(
      name = "ubuntu-latest (release)",
      os = "ubuntu-latest",
      step = "Run r-lib/actions/check-r-package@v2",
      log = "check-notes.log"
    )
  ))

  findings <- ci_failures()
  notes <- findings[findings$kind == "check_note", ]

  expect_equal(nrow(notes), 6)
  expect_equal(
    notes$message[1],
    paste(
      "checking whether package ‘fmisc’ can be installed ... [10s/11s] NOTE",
      "Found the following notes/warnings:",
      "  SystemRequirements specified C++11: support has been removed",
      paste(
        "See ‘/home/runner/work/fmisc/fmisc/check/fmisc.Rcheck/00install.out’",
        "for details."
      ),
      sep = "\n"
    )
  )
  code_note <- notes[grepl("R code for possible problems", notes$message), ]
  expect_equal(code_note$file, "R/decorators.R")
  expect_identical(code_note$line, 607L)
  expect_true(all(is.na(notes$file[-match("R/decorators.R", notes$file)])))
})

test_that("testthat failures and errors are reported once each", {
  local_ci_run(list(
    list(
      name = "ubuntu-latest (release)",
      os = "ubuntu-latest",
      step = "Run r-lib/actions/check-r-package@v2",
      log = "check-tests.log"
    )
  ))

  findings <- ci_failures()
  tests <- findings[findings$kind == "test_failure", ]

  expect_equal(nrow(tests), 2)
  expect_equal(tests$file, rep("tests/testthat/test-zz-demo.R", 2))
  expect_identical(tests$line, c(2L, 6L))
  expect_equal(
    tests$message[1],
    paste(
      "Failure: stop2 keeps the class",
      "1 + 1 (`actual`) not equal to 3 (`expected`).",
      "",
      "  `actual`: 2",
      "`expected`: 3",
      sep = "\n"
    )
  )
  expect_equal(
    tests$message[2],
    "Error: stop2 errors early\nError in `eval(code, test_env)`: boom"
  )
})

test_that("R CMD check ERRORs and WARNINGs are kept next to test failures", {
  local_ci_run(list(
    list(
      name = "ubuntu-latest (release)",
      os = "ubuntu-latest",
      step = "Run r-lib/actions/check-r-package@v2",
      log = "check-tests.log"
    )
  ))

  findings <- ci_failures()

  expect_equal(sum(findings$kind == "check_error"), 1)
  expect_match(
    findings$message[findings$kind == "check_error"],
    "^checking tests \\.\\.\\."
  )
  warnings <- findings$message[findings$kind == "check_warning"]
  expect_length(warnings, 2)
  expect_match(
    warnings[1],
    "^checking R files for syntax errors \\.\\.\\. WARNING"
  )
  expect_equal(
    warnings[2],
    "WARNING\n'qpdf' is needed for checks on size reduction of PDFs"
  )
  expect_false("unparsed" %in% findings$kind)
})

test_that("a failed job with no known finding keeps its failing step raw", {
  local_ci_run(list(
    list(
      name = "style",
      os = "ubuntu-latest",
      step = "Commit and push changes",
      log = "style-unparsed.log"
    )
  ))

  findings <- ci_failures()

  expect_equal(nrow(findings), 1)
  expect_equal(findings$kind, "unparsed")
  expect_equal(findings$step, "Commit and push changes")
  expect_identical(findings$file, NA_character_)
  expect_identical(findings$line, NA_integer_)
  expect_match(findings$message, "^##\\[group\\]Run if FILES_TO_COMMIT")
  expect_match(findings$message, "fatal: Not possible to fast-forward")
  expect_match(
    findings$message,
    "##\\[error\\]Process completed with exit code 128\\.$"
  )
})

test_that("NOTEs alone do not explain a failed job", {
  local_ci_run(list(
    list(
      name = "ubuntu-latest (release)",
      os = "ubuntu-latest",
      step = "Run r-lib/actions/check-r-package@v2",
      log = "check-notes.log"
    )
  ))

  findings <- ci_failures()

  expect_equal(findings$kind, c(rep("check_note", 6), "unparsed"))
  expect_match(findings$message[7], "Status: 6 NOTEs")
})

test_that("the latest failed run of the current branch is asked for", {
  calls <- local_ci_run(
    list(
      list(name = "r-lint", os = "ubuntu-latest", log = "r-lint.log"),
      list(
        name = "macos-latest (release)",
        os = "macos-latest",
        log = "check-tests.log",
        conclusion = "cancelled"
      )
    ),
    branch = "feat/ci"
  )

  findings <- ci_failures()

  runs_query <- calls$params[[1]]
  expect_equal(runs_query$owner, "fabiandistler")
  expect_equal(runs_query$repo, "fmisc")
  expect_equal(runs_query$branch, "feat/ci")
  expect_equal(runs_query$status, "failure")
  expect_equal(runs_query$per_page, 1)
  # The cancelled job's log is never fetched.
  expect_equal(
    sum(calls$endpoints == "/repos/{owner}/{repo}/actions/jobs/{job_id}/logs"),
    1
  )
  expect_equal(unique(findings$job), c("r-lint", "macos-latest (release)"))
  expect_equal(
    unique(findings$sha),
    "0123456789abcdef0123456789abcdef01234567"
  )
  expect_equal(
    unique(findings$url),
    paste0(
      "https://github.com/fabiandistler/fmisc/actions/runs/101/job/",
      c("201", "202")
    )
  )
})

test_that("a branch without a failed run gives zero typed rows", {
  local_ci_run(runs = list())

  findings <- ci_failures()

  expect_equal(nrow(findings), 0)
  expect_equal(
    names(findings),
    c("job", "os", "step", "kind", "file", "line", "message", "sha", "url")
  )
  expect_type(findings$line, "integer")
  expect_type(findings$message, "character")
})

test_that("a detached HEAD is an error", {
  local_ci_run()
  writeLines(gert::git_info()$commit, file.path(".git", "HEAD"))

  expect_error(ci_failures(), "not on a branch")
})

test_that("printing shows one line per finding", {
  local_ci_run(list(
    list(name = "style", os = "ubuntu-latest", log = "style-unparsed.log"),
    list(name = "r-lint", os = "ubuntu-latest", log = "r-lint.log")
  ))

  findings <- ci_failures()

  expect_snapshot(print(findings))
  expect_snapshot(print(findings[0, ]))
})

test_that("job logs served as raw bytes are parsed like text", {
  local_ci_run(
    list(
      list(
        name = "r-lint",
        os = "ubuntu-latest",
        step = "lintr (.lintr)",
        log = "r-lint.log"
      )
    ),
    raw_logs = TRUE
  )

  findings <- ci_failures()

  expect_equal(nrow(findings), 6)
  expect_equal(unique(findings$kind), "lint")
  expect_equal(findings$file[1], "R/chunking.R")
})

test_that("timed-out and cancelled jobs get one row each", {
  calls <- local_ci_run(list(
    list(
      name = "windows-latest (release)",
      os = "windows-latest",
      step = "Run r-lib/actions/check-r-package@v2",
      log = "check-tests.log",
      conclusion = "timed_out"
    ),
    list(
      name = "macos-latest (release)",
      os = "macos-latest",
      step = "Run r-lib/actions/setup-r-dependencies@v2",
      log = "check-tests.log",
      conclusion = "cancelled"
    ),
    list(
      name = "ubuntu-latest (release)",
      os = "ubuntu-latest",
      log = "check-tests.log",
      conclusion = "success"
    )
  ))

  findings <- ci_failures()

  expect_equal(findings$kind, c("timed_out", "cancelled"))
  expect_equal(
    findings$job,
    c("windows-latest (release)", "macos-latest (release)")
  )
  expect_equal(findings$os, c("windows-latest", "macos-latest"))
  expect_equal(
    findings$step,
    c(
      "Run r-lib/actions/check-r-package@v2",
      "Run r-lib/actions/setup-r-dependencies@v2"
    )
  )
  expect_equal(findings$message, c("timed_out", "cancelled"))
  expect_identical(findings$file, c(NA_character_, NA_character_))
  expect_identical(findings$line, c(NA_integer_, NA_integer_))
  expect_false(
    "/repos/{owner}/{repo}/actions/jobs/{job_id}/logs" %in% calls$endpoints
  )
})
