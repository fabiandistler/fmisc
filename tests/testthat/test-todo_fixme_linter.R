test_that("todo_fixme_linter detects TODO comments", {
  linter <- todo_fixme_linter()

  expect_lint(
    "# TODO: implement this",
    "TODO/FIXME/XXX/HACK comments found",
    linter
  )

  expect_lint(
    "# FIXME: this is broken",
    "TODO/FIXME/XXX/HACK comments found",
    linter
  )

  expect_lint(
    "# XXX: questionable code",
    "TODO/FIXME/XXX/HACK comments found",
    linter
  )

  expect_lint(
    "# HACK: temporary workaround",
    "TODO/FIXME/XXX/HACK comments found",
    linter
  )
})

test_that("todo_fixme_linter ignores regular comments", {
  linter <- todo_fixme_linter()

  expect_lint(
    "# This is a normal comment",
    NULL,
    linter
  )

  expect_lint(
    "# Calculate the total",
    NULL,
    linter
  )
})

test_that("todo_fixme_linter is case sensitive", {
  linter <- todo_fixme_linter()

  # These should be detected (uppercase)
  expect_lint(
    "# TODO: fix",
    "TODO/FIXME/XXX/HACK comments found",
    linter
  )

  # These should not be detected (lowercase)
  expect_lint(
    "# todo: fix",
    NULL,
    linter
  )
})
