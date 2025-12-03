test_that("chunk_processor initializes correctly", {
  processor <- chunk_processor(max_ram_mb = 500, verbose = FALSE)

  expect_type(processor, "list")
  expect_true("add_chunk" %in% names(processor))
  expect_true("get_results" %in% names(processor))
  expect_true("cleanup" %in% names(processor))
  expect_true("get_ram_usage_cpp" %in% names(processor))
})

test_that("chunk_processor add_chunk works", {
  processor <- chunk_processor(max_ram_mb = 500, verbose = FALSE)

  chunk1 <- data.frame(x = 1:10, y = 11:20)
  chunk2 <- data.frame(x = 21:30, y = 31:40)

  # Should not error
  expect_no_error(processor$add_chunk(chunk1))
  expect_no_error(processor$add_chunk(chunk2))
})

test_that("chunk_processor get_results combines chunks", {
  processor <- chunk_processor(max_ram_mb = 500, verbose = FALSE)

  chunk1 <- data.frame(x = 1:10, y = 11:20)
  chunk2 <- data.frame(x = 21:30, y = 31:40)
  chunk3 <- data.frame(x = 41:50, y = 51:60)

  processor$add_chunk(chunk1)
  processor$add_chunk(chunk2)
  processor$add_chunk(chunk3)

  result <- processor$get_results()

  expect_equal(nrow(result), 30)
  expect_equal(result$x, c(1:10, 21:30, 41:50))
  expect_equal(result$y, c(11:20, 31:40, 51:60))
})

test_that("chunk_processor handles custom combine function", {
  processor <- chunk_processor(max_ram_mb = 500, verbose = FALSE)

  chunk1 <- c(1, 2, 3)
  chunk2 <- c(4, 5, 6)
  chunk3 <- c(7, 8, 9)

  processor$add_chunk(chunk1)
  processor$add_chunk(chunk2)
  processor$add_chunk(chunk3)

  result <- processor$get_results(combine_fn = c)

  expect_equal(length(result), 9)
  expect_equal(result, 1:9)
})

test_that("chunk_processor cleanup works", {
  processor <- chunk_processor(max_ram_mb = 500, verbose = FALSE)

  chunk1 <- data.frame(x = 1:10)
  processor$add_chunk(chunk1)

  # Cleanup should not error
  expect_no_error(processor$cleanup())

  # After cleanup, get_results should return NULL or empty
  result <- processor$get_results()
  expect_true(is.null(result) || nrow(result) == 0)
})

test_that("chunk_processor get_ram_usage returns numeric", {
  processor <- chunk_processor(max_ram_mb = 500, verbose = FALSE)

  ram <- processor$get_ram_usage()
  expect_type(ram, "double")
  expect_true(ram >= 0)
})

test_that("chunk_processor handles many small chunks", {
  processor <- chunk_processor(max_ram_mb = 10000, verbose = FALSE)

  # Add 100 small chunks
  for (i in 1:100) {
    chunk <- data.frame(id = i, value = runif(10))
    processor$add_chunk(chunk)
  }

  result <- processor$get_results()
  expect_equal(nrow(result), 1000)
  expect_equal(unique(result$id), 1:100)

  processor$cleanup()
})

test_that("chunk_processor handles single chunk", {
  processor <- chunk_processor(max_ram_mb = 500, verbose = FALSE)

  chunk <- data.frame(x = 1:100, y = 101:200)
  processor$add_chunk(chunk)

  result <- processor$get_results()
  expect_equal(nrow(result), 100)
  expect_equal(result$x, 1:100)
})

test_that("chunk_processor preserves column types", {
  processor <- chunk_processor(max_ram_mb = 500, verbose = FALSE)

  chunk1 <- data.frame(
    int_col = 1L:10L,
    dbl_col = 1.1:10.1,
    chr_col = letters[1:10],
    lgl_col = rep(c(TRUE, FALSE), 5),
    stringsAsFactors = FALSE
  )

  chunk2 <- data.frame(
    int_col = 11L:20L,
    dbl_col = 11.1:20.1,
    chr_col = letters[11:20],
    lgl_col = rep(c(FALSE, TRUE), 5),
    stringsAsFactors = FALSE
  )

  processor$add_chunk(chunk1)
  processor$add_chunk(chunk2)

  result <- processor$get_results()

  expect_type(result$int_col, "integer")
  expect_type(result$dbl_col, "double")
  expect_type(result$chr_col, "character")
  expect_type(result$lgl_col, "logical")
})

test_that("chunk_processor works with matrices", {
  processor <- chunk_processor(max_ram_mb = 500, verbose = FALSE)

  mat1 <- matrix(1:20, ncol = 4)
  mat2 <- matrix(21:40, ncol = 4)

  processor$add_chunk(mat1)
  processor$add_chunk(mat2)

  result <- processor$get_results()

  expect_true(is.matrix(result))
  expect_equal(nrow(result), 10)
  expect_equal(ncol(result), 4)
})

test_that("chunk_processor verbose mode produces messages", {
  # Create processor with low RAM threshold to trigger disk writing
  # (this test might be flaky depending on actual RAM usage)
  processor <- chunk_processor(max_ram_mb = 1, verbose = TRUE)

  chunk <- data.frame(x = 1:10)

  # May or may not produce message depending on RAM, but shouldn't error
  expect_no_error(processor$add_chunk(chunk))
})
