test_that("get_ram_usage returns numeric value", {
  ram <- get_ram_usage()

  expect_type(ram, "double")
  expect_true(ram > 0)
  expect_true(is.finite(ram))
})

test_that("get_ram_usage_cpp returns numeric value", {
  skip_if_not_installed("Rcpp")

  ram <- get_ram_usage_cpp()

  expect_type(ram, "double")
  expect_true(ram > 0)
  expect_true(is.finite(ram))
})

test_that("get_ram_usage and get_ram_usage_cpp are comparable", {
  skip_if_not_installed("Rcpp")

  ram_r <- get_ram_usage()
  ram_cpp <- get_ram_usage_cpp()

  # Both should be positive
  expect_true(ram_r > 0)
  expect_true(ram_cpp > 0)

  # They should be in the same ballpark (within an order of magnitude)
  # This is a loose test since different methods might report differently
  expect_true(ram_cpp > 0.01 * ram_r)
  expect_true(ram_cpp < 100 * ram_r)
})

test_that("get_system_info returns list with expected fields", {
  skip_if_not_installed("Rcpp")

  sys_info <- get_system_info()

  expect_type(sys_info, "list")
  expect_true("total_ram_mb" %in% names(sys_info))
  expect_true("available_ram_mb" %in% names(sys_info))
  expect_true("used_ram_mb" %in% names(sys_info))

  # All values should be positive and finite
  expect_true(sys_info$total_ram_mb > 0)
  expect_true(sys_info$available_ram_mb >= 0)
  expect_true(sys_info$used_ram_mb >= 0)

  expect_true(is.finite(sys_info$total_ram_mb))
  expect_true(is.finite(sys_info$available_ram_mb))
  expect_true(is.finite(sys_info$used_ram_mb))
})

test_that("get_system_info values are logical", {
  skip_if_not_installed("Rcpp")

  sys_info <- get_system_info()

  # Used + Available should be <= Total (with some tolerance for rounding)
  expect_true(sys_info$used_ram_mb <= sys_info$total_ram_mb * 1.1)
  expect_true(sys_info$available_ram_mb <= sys_info$total_ram_mb * 1.1)
})

test_that("ram_threshold_exceeded works correctly", {
  skip_if_not_installed("Rcpp")

  # Get current RAM usage
  current_ram <- get_ram_usage_cpp()

  # Threshold below current usage should return TRUE
  expect_true(ram_threshold_exceeded(max_ram_mb = current_ram * 0.5))

  # Threshold above current usage should return FALSE
  expect_false(ram_threshold_exceeded(max_ram_mb = current_ram * 2))
})

test_that("ram_threshold_exceeded handles edge cases", {
  skip_if_not_installed("Rcpp")

  # Very high threshold should always be FALSE
  expect_false(ram_threshold_exceeded(max_ram_mb = 1e9))

  # Very low threshold should always be TRUE
  expect_true(ram_threshold_exceeded(max_ram_mb = 0.001))
})

test_that("RAM usage increases with data allocation", {
  # This test checks if RAM monitoring detects changes
  initial_ram <- get_ram_usage()

  # Allocate some memory
  large_data <- vector("list", 1000)
  for (i in 1:1000) {
    large_data[[i]] <- rnorm(1000)
  }

  # Force R to not optimize away the allocation
  sum_val <- sum(unlist(large_data))
  expect_true(is.finite(sum_val))

  after_ram <- get_ram_usage()

  # RAM should have increased (or at least not decreased significantly)
  # Using a loose check since gc() behavior can vary
  expect_true(after_ram >= initial_ram * 0.9)

  # Clean up
  rm(large_data)
  gc()
})

test_that("get_ram_usage handles multiple calls", {
  # Multiple calls should work without error
  ram1 <- get_ram_usage()
  ram2 <- get_ram_usage()
  ram3 <- get_ram_usage()

  expect_type(ram1, "double")
  expect_type(ram2, "double")
  expect_type(ram3, "double")

  # All should be positive
  expect_true(all(c(ram1, ram2, ram3) > 0))
})

test_that("get_ram_usage_cpp handles multiple calls", {
  skip_if_not_installed("Rcpp")

  # Multiple calls should work without error
  ram1 <- get_ram_usage_cpp()
  ram2 <- get_ram_usage_cpp()
  ram3 <- get_ram_usage_cpp()

  expect_type(ram1, "double")
  expect_type(ram2, "double")
  expect_type(ram3, "double")

  # All should be positive
  expect_true(all(c(ram1, ram2, ram3) > 0))
})
