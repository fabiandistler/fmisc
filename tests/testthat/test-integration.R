test_that("full workflow: process large dataset with RAM limits", {
  # Create a moderately sized dataset
  n <- 1000
  df <- data.frame(
    id = 1:n,
    x = rnorm(n),
    y = runif(n),
    category = sample(letters[1:5], n, replace = TRUE)
  )

  # Process with chunking
  result <- process_with_chunks(
    data = df,
    process_fn = function(chunk) {
      chunk$computed <- chunk$x * chunk$y
      chunk$squared <- chunk$x^2
      chunk
    },
    max_ram_mb = 100,
    chunk_size = 200,
    verbose = FALSE
  )

  # Verify results
  expect_equal(nrow(result), n)
  expect_equal(result$id, df$id)
  expect_equal(result$computed, df$x * df$y)
  expect_equal(result$squared, df$x^2)
})

test_that("full workflow: chunk processor with multiple operations", {
  processor <- chunk_processor(max_ram_mb = 100, verbose = FALSE)

  # Add multiple chunks
  for (i in 1:10) {
    chunk <- data.frame(
      batch = i,
      value = rnorm(100)
    )
    processor$add_chunk(chunk)
  }

  result <- processor$get_results()

  expect_equal(nrow(result), 1000)
  expect_equal(unique(result$batch), 1:10)

  processor$cleanup()
})

test_that("full workflow: iterator with manual processing", {
  df <- data.frame(
    x = 1:500,
    y = 501:1000
  )

  iterator <- create_chunk_iterator(df, chunk_size = 100)
  results <- list()

  while (iterator$has_next()) {
    chunk <- iterator$get_next()
    processed <- transform(chunk, z = x + y)
    results[[length(results) + 1]] <- processed
  }

  final <- do.call(rbind, results)

  expect_equal(nrow(final), 500)
  expect_equal(final$z, df$x + df$y)
})

test_that("full workflow: aggregation across chunks", {
  # Create dataset with categories
  df <- data.frame(
    category = rep(c("A", "B", "C"), length.out = 300),
    value = rnorm(300)
  )

  # Process with aggregation
  result <- process_with_chunks(
    data = df,
    process_fn = function(chunk) {
      aggregate(chunk$value, by = list(category = chunk$category), FUN = sum)
    },
    combine_fn = function(x, y) {
      combined <- rbind(x, y)
      aggregate(combined$x, by = list(category = combined$category), FUN = sum)
    },
    chunk_size = 50,
    verbose = FALSE
  )

  # Calculate expected result
  expected <- aggregate(df$value, by = list(category = df$category), FUN = sum)

  expect_equal(nrow(result), 3)
  expect_setequal(result$category, c("A", "B", "C"))

  # Values should match (with some floating point tolerance)
  for (cat in c("A", "B", "C")) {
    result_val <- result$x[result$category == cat]
    expected_val <- expected$x[expected$category == cat]
    expect_equal(result_val, expected_val, tolerance = 1e-10)
  }
})

test_that("full workflow: combining C++ and R functions", {
  skip_if_not_installed("Rcpp")

  vec <- rnorm(1000)

  # Split using C++
  chunks <- split_vector_chunks(vec, chunk_size = 100)

  # Process each chunk in R
  processed_chunks <- lapply(chunks, function(chunk) {
    chunk^2 + 1
  })

  # Combine
  result <- unlist(processed_chunks)

  expect_equal(length(result), 1000)
  expect_equal(result, vec^2 + 1)
})

test_that("full workflow: matrix processing with chunking", {
  skip_if_not_installed("Rcpp")

  mat <- matrix(rnorm(1000), nrow = 100, ncol = 10)

  # Split matrix
  chunks <- split_matrix_chunks(mat, chunk_size = 25)

  # Process chunks
  processed <- lapply(chunks, function(chunk) {
    chunk * 2
  })

  # Combine
  result <- do.call(rbind, processed)

  expect_equal(dim(result), dim(mat))
  expect_equal(result, mat * 2)
})

test_that("full workflow: optimal chunk size calculation and usage", {
  skip_if_not_installed("Rcpp")

  df <- data.frame(
    x = 1:1000,
    y = rnorm(1000)
  )

  data_size_mb <- as.numeric(utils::object.size(df)) / (1024^2)

  # Calculate optimal chunk size
  optimal_size <- calculate_optimal_chunk_size(
    data_size_mb = data_size_mb,
    total_rows = nrow(df),
    max_ram_mb = 100,
    target_fraction = 0.1
  )

  expect_true(optimal_size > 0)
  expect_true(optimal_size <= nrow(df))

  # Use it in processing
  result <- process_with_chunks(
    data = df,
    process_fn = function(chunk) {
      chunk$z <- chunk$x * 2
      chunk
    },
    chunk_size = optimal_size,
    verbose = FALSE
  )

  expect_equal(nrow(result), nrow(df))
})

test_that("full workflow: error handling in process function", {
  df <- data.frame(x = 1:100)

  # Process function that handles errors gracefully
  result <- tryCatch(
    {
      process_with_chunks(
        data = df,
        process_fn = function(chunk) {
          # This will work for most chunks
          chunk$y <- chunk$x * 2
          chunk
        },
        chunk_size = 20,
        verbose = FALSE
      )
    },
    error = function(e) {
      NULL
    }
  )

  expect_false(is.null(result))
  expect_equal(nrow(result), 100)
})

test_that("full workflow: preserving data integrity through chunking", {
  # Create dataset with various data types
  df <- data.frame(
    int_col = 1L:200L,
    num_col = rnorm(200),
    char_col = sample(letters, 200, replace = TRUE),
    factor_col = factor(sample(c("low", "med", "high"), 200, replace = TRUE)),
    logical_col = sample(c(TRUE, FALSE), 200, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- process_with_chunks(
    data = df,
    process_fn = function(chunk) {
      # Just pass through to test preservation
      chunk
    },
    chunk_size = 50,
    verbose = FALSE
  )

  expect_equal(nrow(result), nrow(df))
  expect_equal(result$int_col, df$int_col)
  expect_equal(result$num_col, df$num_col)
  expect_equal(result$char_col, df$char_col)
  expect_equal(as.character(result$factor_col), as.character(df$factor_col))
  expect_equal(result$logical_col, df$logical_col)
})

test_that("full workflow: RAM threshold management", {
  skip_if_not_installed("Rcpp")

  # Get current RAM
  initial_ram <- get_ram_usage_cpp()

  # Create moderately sized data
  df <- data.frame(
    x = 1:500,
    y = rnorm(500)
  )

  # Process with very low RAM limit to force disk writes
  result <- process_with_chunks(
    data = df,
    process_fn = function(chunk) {
      chunk$z <- chunk$x + chunk$y
      chunk
    },
    max_ram_mb = 1, # Very low to force disk writing
    chunk_size = 50,
    verbose = FALSE
  )

  # Should still get correct results despite low RAM limit
  expect_equal(nrow(result), 500)
  expect_equal(result$z, df$x + df$y)
})
