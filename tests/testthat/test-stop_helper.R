test_that("stop2() throws an error with base R", {
  expect_error(stop2("test error"), "test error")
})

test_that("stop2() accepts custom error classes when cli is available", {
  skip_if_not_installed("cli")

  expect_error(
    stop2("test error", class = "custom_error"),
    class = "custom_error"
  )
})

test_that("stop2() accepts custom error classes when rlang is available", {
  skip_if_not_installed("rlang")

  expect_error(
    stop2("test error", class = "custom_error"),
    class = "custom_error"
  )
})

test_that("stop2() handles basic error messages", {
  expect_error(stop2("Something went wrong"))
  expect_error(stop2("Invalid input"), "Invalid input")
})

test_that("stop2() works with variable interpolation when cli is available", {
  skip_if_not_installed("cli")

  x <- 5
  expect_error(stop2("Value: {x}"))
})

test_that("stop2() passes additional arguments", {
  expect_error(stop2("test", domain = NA))
})

test_that("stop2() uses correct environment for interpolation", {
  skip_if_not_installed("cli")

  test_func <- function() {
    local_var <- "test_value"
    stop2("Error: {local_var}")
  }

  expect_error(test_func(), "test_value")
})
