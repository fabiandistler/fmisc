test_that("split_vector_chunks works correctly", {
  skip_if_not_installed("Rcpp")

  vec <- 1:100
  chunks <- split_vector_chunks(vec, chunk_size = 25)

  expect_type(chunks, "list")
  expect_equal(length(chunks), 4)

  # Check first chunk
  expect_equal(length(chunks[[1]]), 25)
  expect_equal(chunks[[1]], 1:25)

  # Check second chunk
  expect_equal(length(chunks[[2]]), 25)
  expect_equal(chunks[[2]], 26:50)

  # Check last chunk
  expect_equal(length(chunks[[4]]), 25)
  expect_equal(chunks[[4]], 76:100)
})

test_that("split_vector_chunks handles uneven splits", {
  skip_if_not_installed("Rcpp")

  vec <- 1:97
  chunks <- split_vector_chunks(vec, chunk_size = 25)

  expect_equal(length(chunks), 4)

  # Last chunk should have remainder
  expect_equal(length(chunks[[4]]), 22)
  expect_equal(chunks[[4]], 76:97)
})

test_that("split_vector_chunks handles single chunk", {
  skip_if_not_installed("Rcpp")

  vec <- 1:10
  chunks <- split_vector_chunks(vec, chunk_size = 20)

  expect_equal(length(chunks), 1)
  expect_equal(chunks[[1]], 1:10)
})

test_that("split_vector_chunks handles exact division", {
  skip_if_not_installed("Rcpp")

  vec <- 1:100
  chunks <- split_vector_chunks(vec, chunk_size = 20)

  expect_equal(length(chunks), 5)
  expect_true(all(sapply(chunks, length) == 20))
})

test_that("split_vector_chunks preserves numeric values", {
  skip_if_not_installed("Rcpp")

  vec <- seq(0.1, 10, by = 0.1)
  chunks <- split_vector_chunks(vec, chunk_size = 10)

  # Reconstruct original vector
  reconstructed <- unlist(chunks)
  expect_equal(reconstructed, vec)
})

test_that("split_matrix_chunks works correctly", {
  skip_if_not_installed("Rcpp")

  mat <- matrix(1:100, nrow = 20, ncol = 5)
  chunks <- split_matrix_chunks(mat, chunk_size = 5)

  expect_type(chunks, "list")
  expect_equal(length(chunks), 4)

  # Check dimensions of first chunk
  expect_equal(nrow(chunks[[1]]), 5)
  expect_equal(ncol(chunks[[1]]), 5)

  # Check dimensions of last chunk
  expect_equal(nrow(chunks[[4]]), 5)
  expect_equal(ncol(chunks[[4]]), 5)
})

test_that("split_matrix_chunks handles uneven splits", {
  skip_if_not_installed("Rcpp")

  mat <- matrix(1:77, nrow = 11, ncol = 7)
  chunks <- split_matrix_chunks(mat, chunk_size = 3)

  expect_equal(length(chunks), 4)

  # Last chunk should have remainder rows
  expect_equal(nrow(chunks[[4]]), 2)
  expect_equal(ncol(chunks[[4]]), 7)
})

test_that("split_matrix_chunks preserves values", {
  skip_if_not_installed("Rcpp")

  mat <- matrix(rnorm(100), nrow = 20, ncol = 5)
  chunks <- split_matrix_chunks(mat, chunk_size = 5)

  # Reconstruct original matrix
  reconstructed <- do.call(rbind, chunks)
  expect_equal(reconstructed, mat)
})

test_that("split_matrix_chunks handles single row matrix", {
  skip_if_not_installed("Rcpp")

  mat <- matrix(1:5, nrow = 1, ncol = 5)
  chunks <- split_matrix_chunks(mat, chunk_size = 10)

  expect_equal(length(chunks), 1)
  expect_equal(nrow(chunks[[1]]), 1)
  expect_equal(ncol(chunks[[1]]), 5)
})

test_that("calculate_optimal_chunk_size returns sensible values", {
  skip_if_not_installed("Rcpp")

  chunk_size <- calculate_optimal_chunk_size(
    data_size_mb = 100,
    total_rows = 1000000,
    max_ram_mb = 1000,
    target_fraction = 0.1
  )

  expect_type(chunk_size, "integer")
  expect_true(chunk_size > 0)
  expect_true(chunk_size <= 1000000)
})

test_that("calculate_optimal_chunk_size handles small data", {
  skip_if_not_installed("Rcpp")

  chunk_size <- calculate_optimal_chunk_size(
    data_size_mb = 1,
    total_rows = 100,
    max_ram_mb = 1000,
    target_fraction = 0.1
  )

  expect_true(chunk_size > 0)
  expect_true(chunk_size <= 100)
})

test_that("calculate_optimal_chunk_size handles different target fractions", {
  skip_if_not_installed("Rcpp")

  chunk_size_10 <- calculate_optimal_chunk_size(
    data_size_mb = 100,
    total_rows = 1000000,
    max_ram_mb = 1000,
    target_fraction = 0.1
  )

  chunk_size_20 <- calculate_optimal_chunk_size(
    data_size_mb = 100,
    total_rows = 1000000,
    max_ram_mb = 1000,
    target_fraction = 0.2
  )

  # Higher fraction should give larger chunks
  expect_true(chunk_size_20 > chunk_size_10)
})

test_that("calculate_optimal_chunk_size minimum is 1", {
  skip_if_not_installed("Rcpp")

  # Even with very large data and small RAM, should return at least 1
  chunk_size <- calculate_optimal_chunk_size(
    data_size_mb = 10000,
    total_rows = 1000000,
    max_ram_mb = 1,
    target_fraction = 0.001
  )

  expect_true(chunk_size >= 1)
})

test_that("calculate_optimal_chunk_size caps at total rows", {
  skip_if_not_installed("Rcpp")

  chunk_size <- calculate_optimal_chunk_size(
    data_size_mb = 1,
    total_rows = 100,
    max_ram_mb = 10000,
    target_fraction = 0.5
  )

  # Should not exceed total rows
  expect_true(chunk_size <= 100)
})

test_that("split_vector_chunks handles large vectors efficiently", {
  skip_if_not_installed("Rcpp")

  # Test with a larger vector
  vec <- 1:10000
  chunks <- split_vector_chunks(vec, chunk_size = 1000)

  expect_equal(length(chunks), 10)
  expect_true(all(sapply(chunks, length) == 1000))

  # Verify reconstruction
  reconstructed <- unlist(chunks)
  expect_equal(reconstructed, vec)
})

test_that("split_matrix_chunks handles different matrix shapes", {
  skip_if_not_installed("Rcpp")

  # Wide matrix
  mat_wide <- matrix(1:1000, nrow = 10, ncol = 100)
  chunks_wide <- split_matrix_chunks(mat_wide, chunk_size = 3)

  expect_equal(length(chunks_wide), 4)
  expect_equal(ncol(chunks_wide[[1]]), 100)

  # Tall matrix
  mat_tall <- matrix(1:1000, nrow = 100, ncol = 10)
  chunks_tall <- split_matrix_chunks(mat_tall, chunk_size = 25)

  expect_equal(length(chunks_tall), 4)
  expect_equal(ncol(chunks_tall[[1]]), 10)
})

test_that("split_vector_chunks handles negative numbers", {
  skip_if_not_installed("Rcpp")

  vec <- seq(-50, 49)
  chunks <- split_vector_chunks(vec, chunk_size = 20)

  reconstructed <- unlist(chunks)
  expect_equal(reconstructed, vec)
})

test_that("split_matrix_chunks handles negative numbers", {
  skip_if_not_installed("Rcpp")

  mat <- matrix(seq(-50, 49), nrow = 10, ncol = 10)
  chunks <- split_matrix_chunks(mat, chunk_size = 3)

  reconstructed <- do.call(rbind, chunks)
  expect_equal(reconstructed, mat)
})
