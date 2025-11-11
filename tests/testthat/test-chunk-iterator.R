test_that("create_chunk_iterator works with data.frames", {
  df <- data.frame(x = 1:100, y = 101:200)
  iterator <- create_chunk_iterator(df, chunk_size = 25)

  expect_equal(iterator$total_chunks, 4)
  expect_equal(iterator$chunk_size, 25)
  expect_true(iterator$has_next())
  expect_equal(iterator$current_chunk(), 0)
})

test_that("chunk_iterator iterates correctly through data.frame", {
  df <- data.frame(x = 1:100, y = 101:200)
  iterator <- create_chunk_iterator(df, chunk_size = 25)

  # Get first chunk
  chunk1 <- iterator$get_next()
  expect_equal(nrow(chunk1), 25)
  expect_equal(chunk1$x, 1:25)
  expect_equal(iterator$current_chunk(), 1)

  # Get second chunk
  chunk2 <- iterator$get_next()
  expect_equal(nrow(chunk2), 25)
  expect_equal(chunk2$x, 26:50)
  expect_equal(iterator$current_chunk(), 2)

  # Skip to last chunk
  chunk3 <- iterator$get_next()
  chunk4 <- iterator$get_next()
  expect_equal(nrow(chunk4), 25)
  expect_equal(chunk4$x, 76:100)
  expect_false(iterator$has_next())

  # Try to get another chunk (should return NULL)
  chunk5 <- iterator$get_next()
  expect_null(chunk5)
})

test_that("chunk_iterator works with vectors", {
  vec <- 1:100
  iterator <- create_chunk_iterator(vec, chunk_size = 30)

  expect_equal(iterator$total_chunks, 4)
  chunk1 <- iterator$get_next()
  expect_equal(length(chunk1), 30)
  expect_equal(chunk1, 1:30)

  # Skip to last chunk
  iterator$get_next()
  iterator$get_next()
  chunk4 <- iterator$get_next()
  expect_equal(length(chunk4), 10)  # Last chunk has remainder
  expect_equal(chunk4, 91:100)
})

test_that("chunk_iterator works with matrices", {
  mat <- matrix(1:100, ncol = 5)
  iterator <- create_chunk_iterator(mat, chunk_size = 5)

  expect_equal(iterator$total_chunks, 4)
  chunk1 <- iterator$get_next()
  expect_equal(nrow(chunk1), 5)
  expect_equal(ncol(chunk1), 5)
})

test_that("chunk_iterator handles uneven chunk sizes", {
  df <- data.frame(x = 1:97)
  iterator <- create_chunk_iterator(df, chunk_size = 25)

  expect_equal(iterator$total_chunks, 4)

  # Get all chunks
  chunks <- list()
  while (iterator$has_next()) {
    chunks[[length(chunks) + 1]] <- iterator$get_next()
  }

  expect_equal(length(chunks), 4)
  expect_equal(nrow(chunks[[1]]), 25)
  expect_equal(nrow(chunks[[2]]), 25)
  expect_equal(nrow(chunks[[3]]), 25)
  expect_equal(nrow(chunks[[4]]), 22)  # Remainder
})

test_that("chunk_iterator reset works", {
  df <- data.frame(x = 1:50)
  iterator <- create_chunk_iterator(df, chunk_size = 10)

  # Iterate through some chunks
  iterator$get_next()
  iterator$get_next()
  expect_equal(iterator$current_chunk(), 2)

  # Reset
  iterator$reset()
  expect_equal(iterator$current_chunk(), 0)
  expect_true(iterator$has_next())

  # Should start from beginning again
  chunk1 <- iterator$get_next()
  expect_equal(chunk1$x, 1:10)
})

test_that("chunk_iterator validates input", {
  expect_error(
    create_chunk_iterator(list(a = 1, b = 2), chunk_size = 10),
    "Data must be a data.frame, matrix, or vector"
  )
})

test_that("chunk_iterator handles single chunk", {
  df <- data.frame(x = 1:10)
  iterator <- create_chunk_iterator(df, chunk_size = 20)

  expect_equal(iterator$total_chunks, 1)
  chunk <- iterator$get_next()
  expect_equal(nrow(chunk), 10)
  expect_false(iterator$has_next())
})

test_that("chunk_iterator preserves column names", {
  df <- data.frame(alpha = 1:50, beta = 51:100, gamma = 101:150)
  iterator <- create_chunk_iterator(df, chunk_size = 10)

  chunk <- iterator$get_next()
  expect_equal(names(chunk), c("alpha", "beta", "gamma"))
})
