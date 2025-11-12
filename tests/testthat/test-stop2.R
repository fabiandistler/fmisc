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

test_that("simple_glue() helper works correctly", {
  x <- 5
  result <- simple_glue("Value: {x}")
  expect_equal(result, "Value: 5")

  y <- 10
  result <- simple_glue("{x} and {y}")
  expect_equal(result, "5 and 10")

  result <- simple_glue("No braces here")
  expect_equal(result, "No braces here")

  z <- c(1, 2, 3)
  result <- simple_glue("Vector: {z}")
  expect_equal(result, "Vector: 1, 2, 3")
})

test_that("simple_glue() handles expressions", {
  df <- data.frame(a = 1:5)
  result <- simple_glue("Rows: {nrow(df)}")
  expect_equal(result, "Rows: 5")

  x <- 10
  result <- simple_glue("Double: {x * 2}")
  expect_equal(result, "Double: 20")
})


test_that("simple_glue() respects .envir parameter", {
  x <- "outer"
  env <- new.env()
  env$x <- "inner"

  result <- simple_glue("Value: {x}", .envir = env)
  expect_equal(result, "Value: inner")
})

test_that("stop2() interpolation works consistently across backends", {
  x <- 42

  expect_error(stop2("Value: {x}"), "42")

  test_func <- function() {
    local_val <- 99
    stop2("Local: {local_val}")
  }

  expect_error(test_func(), "99")
})

test_that("stop2() handles multiple interpolations", {
  x <- 5
  y <- 10
  expect_error(stop2("Expected {x}, got {y}"), "Expected 5, got 10")
})

test_that("stop2() handles expression interpolation", {
  df <- data.frame(a = 1:3)
  expect_error(
    stop2("Expected 5 rows, got {nrow(df)}"),
    "Expected 5 rows, got 3"
  )
})

test_that("stop2() handles edge cases in interpolation", {
  x <- NULL
  expect_error(stop2("Value: {x}"), NULL)

  z <- TRUE
  expect_error(stop2("Value: {z}"), "TRUE")
})
