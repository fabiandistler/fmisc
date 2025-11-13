test_that("detect_parallel_backend returns valid structure", {
  info <- detect_parallel_backend()

  expect_type(info, "list")
  expect_named(info, c("backend", "os_type", "available_cores", "packages"))

  expect_type(info$backend, "character")
  expect_type(info$os_type, "character")
  expect_type(info$available_cores, "integer")
  expect_type(info$packages, "list")

  # Check valid backend
  valid_backends <- c(
    "mclapply", "parLapply", "doParallel",
    "doMC", "furrr", "foreach", "sequential"
  )
  expect_true(info$backend %in% valid_backends)

  # Check OS type
  expect_true(info$os_type %in% c("unix", "windows"))

  # Check cores
  expect_true(info$available_cores >= 1)
})

test_that("detect_parallel_backend handles NA cores", {
  # Mock detectCores to return NA
  with_mocked_bindings(
    {
      info <- detect_parallel_backend()
      expect_equal(info$available_cores, 1)
    },
    detectCores = function(...) NA_integer_,
    .package = "parallel"
  )
})

test_that("setup_parallel validates n_cores parameter", {
  expect_error(
    setup_parallel(n_cores = -1),
    "n_cores must be a positive integer"
  )

  expect_error(
    setup_parallel(n_cores = "foo"),
    "n_cores must be a positive integer"
  )

  expect_error(
    setup_parallel(n_cores = c(1, 2)),
    "n_cores must be a positive integer"
  )
})

test_that("setup_parallel validates backend parameter", {
  expect_error(
    setup_parallel(backend = "invalid"),
    "Invalid backend.*Must be one of"
  )

  expect_error(
    setup_parallel(backend = "NONSENSE"),
    "Invalid backend.*Must be one of"
  )
})

test_that("setup_parallel returns valid structure", {
  setup <- setup_parallel(n_cores = 1, verbose = FALSE)

  expect_type(setup, "list")
  expect_true("backend" %in% names(setup))
  expect_true("n_cores" %in% names(setup))
  expect_true("cluster" %in% names(setup))
  expect_true("info" %in% names(setup))

  # Cleanup
  stop_parallel(setup)
})

test_that("stop_parallel validates input", {
  expect_error(
    stop_parallel(NULL),
    "setup must be a list"
  )

  expect_error(
    stop_parallel("foo"),
    "setup must be a list"
  )

  expect_error(
    stop_parallel(list()),
    "setup must have 'backend' and 'cluster' elements"
  )

  expect_error(
    stop_parallel(list(backend = "foo")),
    "setup must have 'backend' and 'cluster' elements"
  )
})

test_that("stop_parallel handles valid setup", {
  setup <- list(backend = "sequential", cluster = NULL)
  expect_silent(stop_parallel(setup))
})

test_that("smart_parallel_apply works with simple input", {
  result <- smart_parallel_apply(1:5, function(x) x^2)

  expect_type(result, "list")
  expect_length(result, 5)
  expect_equal(unlist(result), c(1, 4, 9, 16, 25))
})

test_that("smart_parallel_apply works with additional arguments", {
  result <- smart_parallel_apply(1:3, function(x, p) x^p, p = 3)

  expect_type(result, "list")
  expect_length(result, 3)
  expect_equal(unlist(result), c(1, 8, 27))
})

test_that("smart_parallel_apply cleans up on error", {
  # This should not leak resources even though it errors
  expect_warning(
    smart_parallel_apply(1:3, function(x) stop("error")),
    "Parallel execution failed"
  )
})

test_that("smart_parallel_apply works with reused setup", {
  setup <- setup_parallel(n_cores = 1, verbose = FALSE)

  result1 <- smart_parallel_apply(1:3, sqrt, setup = setup)
  result2 <- smart_parallel_apply(1:3, function(x) x^2, setup = setup)

  expect_length(result1, 3)
  expect_length(result2, 3)

  stop_parallel(setup)
})

test_that("smart_parallel_apply returns consistent type", {
  # Should always return list regardless of backend
  result <- smart_parallel_apply(1:3, function(x) x)
  expect_type(result, "list")

  # Even with complex return values
  result <- smart_parallel_apply(1:3, function(x) list(val = x, squared = x^2))
  expect_type(result, "list")
  expect_length(result, 3)
})

test_that("print_parallel_info returns info invisibly", {
  # Capture messages
  info <- suppressMessages(print_parallel_info())

  expect_type(info, "list")
  expect_named(info, c("backend", "os_type", "available_cores", "packages"))
})
