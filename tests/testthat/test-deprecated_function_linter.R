test_that("deprecated_function_linter detects sapply", {
  linter <- deprecated_function_linter()

  expect_lint(
    "x <- sapply(1:10, sqrt)",
    "Avoid sapply",
    linter
  )

  expect_lint(
    "result <- sapply(data, function(x) mean(x))",
    "vapply",
    linter
  )
})

test_that("deprecated_function_linter detects require", {
  linter <- deprecated_function_linter()

  expect_lint(
    "require(dplyr)",
    "Use library() instead of require()",
    linter
  )
})

test_that("deprecated_function_linter ignores appropriate functions", {
  linter <- deprecated_function_linter()

  expect_lint(
    "x <- vapply(1:10, sqrt, numeric(1))",
    NULL,
    linter
  )

  expect_lint(
    "x <- lapply(1:10, sqrt)",
    NULL,
    linter
  )

  expect_lint(
    "x <- Map(sum, list(1:5), list(6:10))",
    NULL,
    linter
  )
})
