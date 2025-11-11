test_that("process_with_chunks processes data correctly", {
  df <- data.frame(x = 1:100, y = 101:200)

  result <- process_with_chunks(
    data = df,
    process_fn = function(chunk) {
      chunk$z <- chunk$x + chunk$y
      chunk
    },
    chunk_size = 25,
    verbose = FALSE
  )

  expect_equal(nrow(result), 100)
  expect_equal(ncol(result), 3)
  expect_equal(result$z, df$x + df$y)
})

test_that("process_with_chunks handles custom combine function", {
  df <- data.frame(
    category = rep(c("A", "B", "C"), length.out = 90),
    value = 1:90
  )

  result <- process_with_chunks(
    data = df,
    process_fn = function(chunk) {
      aggregate(chunk$value, by = list(category = chunk$category), FUN = sum)
    },
    combine_fn = function(x, y) {
      combined <- rbind(x, y)
      aggregate(combined$x, by = list(category = combined$category), FUN = sum)
    },
    chunk_size = 20,
    verbose = FALSE
  )

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 3)
  expect_true("category" %in% names(result))
})

test_that("process_with_chunks auto-calculates chunk size", {
  df <- data.frame(x = 1:100, y = 101:200)

  # Should work without specifying chunk_size
  result <- process_with_chunks(
    data = df,
    process_fn = function(chunk) {
      chunk$z <- chunk$x * 2
      chunk
    },
    max_ram_mb = 1000,
    verbose = FALSE
  )

  expect_equal(nrow(result), 100)
  expect_equal(result$z, df$x * 2)
})

test_that("process_with_chunks works with vectors", {
  vec <- 1:100

  result <- process_with_chunks(
    data = vec,
    process_fn = function(chunk) {
      chunk * 2
    },
    combine_fn = c,
    chunk_size = 25,
    verbose = FALSE
  )

  expect_equal(length(result), 100)
  expect_equal(result, vec * 2)
})

test_that("process_with_chunks handles transformations", {
  df <- data.frame(x = 1:50, y = 51:100)

  result <- process_with_chunks(
    data = df,
    process_fn = function(chunk) {
      data.frame(
        sum = chunk$x + chunk$y,
        product = chunk$x * chunk$y
      )
    },
    chunk_size = 10,
    verbose = FALSE
  )

  expect_equal(nrow(result), 50)
  expect_equal(result$sum, df$x + df$y)
  expect_equal(result$product, df$x * df$y)
})

test_that("process_with_chunks preserves order", {
  df <- data.frame(id = 1:100, value = runif(100))

  result <- process_with_chunks(
    data = df,
    process_fn = function(chunk) {
      chunk$squared <- chunk$value^2
      chunk
    },
    chunk_size = 15,
    verbose = FALSE
  )

  expect_equal(result$id, 1:100)
  expect_equal(result$value, df$value)
})

test_that("process_with_chunks handles single row", {
  df <- data.frame(x = 1, y = 2)

  result <- process_with_chunks(
    data = df,
    process_fn = function(chunk) {
      chunk$z <- chunk$x + chunk$y
      chunk
    },
    chunk_size = 10,
    verbose = FALSE
  )

  expect_equal(nrow(result), 1)
  expect_equal(result$z, 3)
})

test_that("process_with_chunks verbose mode works", {
  df <- data.frame(x = 1:50)

  # Capture messages
  expect_message(
    process_with_chunks(
      data = df,
      process_fn = function(chunk) chunk,
      chunk_size = 10,
      verbose = TRUE
    ),
    "Starting processing"
  )
})

test_that("process_with_chunks handles empty results gracefully", {
  df <- data.frame(x = 1:100, y = 101:200)

  result <- process_with_chunks(
    data = df,
    process_fn = function(chunk) {
      # Filter that might return empty chunks
      chunk[chunk$x > 1000, ]  # Always empty
    },
    chunk_size = 25,
    verbose = FALSE
  )

  # Result should exist even if empty
  expect_true(is.data.frame(result))
})
