test_that("with_retry succeeds on first try without retrying", {
  counter <- 0
  f <- function(x) {
    counter <<- counter + 1
    x * 2
  }
  g <- with_retry(f, max_tries = 3, backoff = 0)
  expect_equal(g(21), 42)
  expect_equal(counter, 1)
  expect_true(is_decorated(g))
})

test_that("with_retry retries then succeeds", {
  counter <- 0
  f <- function() {
    counter <<- counter + 1
    if (counter < 3) stop("transient failure")
    "ok"
  }
  g <- with_retry(f, max_tries = 5, backoff = 0, .jitter = FALSE)
  expect_equal(g(), "ok")
  expect_equal(counter, 3)
})

test_that("with_retry exhausts max_tries and raises fmisc_retry_exhausted", {
  counter <- 0
  f <- function() {
    counter <<- counter + 1
    stop("boom")
  }
  g <- with_retry(f, max_tries = 3, backoff = 0)
  expect_error(g(), class = "fmisc_retry_exhausted")
  expect_equal(counter, 3)
})

test_that("with_retry .on_error predicate short-circuits non-matching errors", {
  counter <- 0
  f <- function() {
    counter <<- counter + 1
    stop("boom")
  }
  # Predicate returns FALSE -> re-raise immediately without retry
  g <- with_retry(f,
    max_tries = 3, backoff = 0,
    .on_error = function(cnd) FALSE
  )
  expect_error(g(), "boom")
  expect_equal(counter, 1)
})

test_that("with_retry .on_retry callback receives attempt, delay, cnd", {
  counter <- 0
  f <- function() {
    counter <<- counter + 1
    if (counter < 3) stop("transient")
    "done"
  }
  records <- list()
  g <- with_retry(f,
    max_tries = 5, backoff = 0, .jitter = FALSE,
    .on_retry = function(attempt, delay, cnd) {
      records[[length(records) + 1]] <<- list(
        attempt = attempt, delay = delay, msg = conditionMessage(cnd)
      )
    }
  )
  expect_equal(g(), "done")
  expect_length(records, 2L)
  expect_equal(records[[1]]$attempt, 1L)
  expect_equal(records[[2]]$attempt, 2L)
  expect_equal(records[[1]]$msg, "transient")
})

test_that("with_retry validation errors on bad inputs", {
  expect_error(with_retry("not a function"), class = "fmisc_decorator_error")
  expect_error(with_retry(identity, max_tries = 0), class = "fmisc_decorator_error")
  expect_error(with_retry(identity, backoff = -1), class = "fmisc_decorator_error")
  expect_error(with_retry(identity, .on_error = "nope"), class = "fmisc_decorator_error")
})

test_that("with_timing attribute mode attaches elapsed and does not print", {
  f <- function(x) x + 1
  g <- with_timing(f, .report = "attribute")
  res <- suppressMessages(g(41))
  expect_equal(as.numeric(res), 42)
  expect_true(!is.null(attr(res, "elapsed")))
  expect_gte(attr(res, "elapsed"), 0)
})

test_that("with_timing callback fires on success and failure", {
  events <- list()
  cb <- function(name, elapsed, ok) {
    events[[length(events) + 1]] <<- list(name = name, ok = ok, elapsed = elapsed)
  }
  g <- with_timing(function(x) x, .report = "callback", .callback = cb)
  expect_equal(g(1), 1)
  boom <- with_timing(function() stop("no"), .report = "callback", .callback = cb)
  expect_error(boom())
  expect_length(events, 2L)
  expect_true(events[[1]]$ok)
  expect_false(events[[2]]$ok)
})

test_that("with_timing threshold suppresses reporting below cutoff", {
  events <- list()
  cb <- function(name, elapsed, ok) {
    events[[length(events) + 1]] <<- list()
  }
  g <- with_timing(function() 1,
    .report = "callback", .callback = cb, .threshold = Inf
  )
  g()
  expect_length(events, 0L)
})

test_that("with_logging invokes custom logger with call/success/error events", {
  events <- list()
  logger <- function(event, data) {
    events[[length(events) + 1]] <<- list(event = event, data = data)
  }
  g <- with_logging(function(x, y) x + y, .logger = logger, .log_result = TRUE)
  expect_equal(g(1, 2), 3)
  event_names <- vapply(events, `[[`, character(1), "event")
  expect_true("call" %in% event_names)
  expect_true("success" %in% event_names)

  events2 <- list()
  logger2 <- function(event, data) {
    events2[[length(events2) + 1]] <<- event
  }
  boom <- with_logging(function() stop("oops"), .logger = logger2)
  expect_error(boom(), "oops")
  expect_true("error" %in% events2)
})

test_that("with_cache caches subsequent calls with the same arguments", {
  counter <- 0
  f <- function(x) {
    counter <<- counter + 1
    x * 10
  }
  # Force env-cache path by setting a finite .max_size
  g <- with_cache(f, .max_size = 100)
  expect_equal(g(2), 20)
  expect_equal(g(2), 20)
  expect_equal(counter, 1L)
  expect_equal(g(3), 30)
  expect_equal(counter, 2L)
})

test_that("cache_clear forces recompute; cache_info reports env size", {
  counter <- 0
  f <- function(x) {
    counter <<- counter + 1
    x
  }
  g <- with_cache(f, .max_size = 100)
  g(1)
  g(2)
  info <- cache_info(g)
  expect_equal(info$backend, "env")
  expect_equal(info$size, 2L)
  cache_clear(g)
  g(1)
  expect_equal(counter, 3L)
  info2 <- cache_info(g)
  expect_equal(info2$size, 1L)
})

test_that("with_cache .ttl expiry recomputes after window", {
  counter <- 0
  f <- function() {
    counter <<- counter + 1
    counter
  }
  g <- with_cache(f, .ttl = 0.05)
  expect_equal(g(), 1L)
  expect_equal(g(), 1L)
  Sys.sleep(0.1)
  expect_equal(g(), 2L)
})

test_that("with_cache .max_size evicts oldest (LRU)", {
  counter <- 0
  f <- function(x) {
    counter <<- counter + 1
    x
  }
  g <- with_cache(f, .max_size = 2)
  g(1)
  g(2)
  g(3) # evicts key for 1
  expect_equal(cache_info(g)$size, 2L)
  # 1 was evicted, so calling again recomputes
  g(1)
  expect_equal(counter, 4L)
})

test_that("with_rate_limit errors when limit exceeded and .wait=FALSE", {
  g <- with_rate_limit(function() "ok", n = 2, period = 60, .wait = FALSE)
  expect_equal(g(), "ok")
  expect_equal(g(), "ok")
  expect_error(g(), class = "fmisc_rate_limit_exceeded")
})

test_that("with_rate_limit sleeps to obey window when .wait=TRUE", {
  g <- with_rate_limit(function() "ok", n = 1, period = 0.1, .wait = TRUE)
  t0 <- Sys.time()
  g()
  g()
  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  expect_gte(elapsed, 0.05) # slack for scheduling jitter
})

test_that("with_rate_limit validates inputs", {
  expect_error(with_rate_limit(identity, n = 0), class = "fmisc_decorator_error")
  expect_error(with_rate_limit(identity, n = 1, period = 0), class = "fmisc_decorator_error")
})

test_that("decorate composes decorators left-to-right", {
  add1 <- function(x) x + 1
  g <- decorate(
    add1,
    function(fn) with_retry(fn, max_tries = 2, backoff = 0),
    function(fn) with_timing(fn, .report = "attribute")
  )
  res <- g(41)
  expect_equal(as.numeric(res), 42)
  expect_true(is_decorated(g))
})

test_that("is_decorated and undecorate roundtrip through one layer", {
  f <- function(x) x
  g <- with_timing(f, .report = "attribute")
  expect_true(is_decorated(g))
  expect_false(is_decorated(f))
  expect_identical(undecorate(g), f)
  expect_identical(undecorate(f), f)
})

test_that("undecorate(depth =) unwraps multiple layers", {
  f <- function(x) x
  g1 <- with_timing(f, .report = "attribute")
  g2 <- with_logging(g1, .name = "x")
  expect_identical(undecorate(g2), g1)
  expect_identical(undecorate(g2, depth = 2), f)
  expect_identical(undecorate(g2, depth = Inf), f)
  expect_identical(undecorate(g2, depth = 99), f)
  expect_error(undecorate(g2, depth = 0), class = "fmisc_decorator_error")
  expect_error(undecorate(g2, depth = -1), class = "fmisc_decorator_error")
  expect_error(undecorate(g2, depth = "two"), class = "fmisc_decorator_error")
})

test_that("pipe composition preserves is_decorated", {
  f <- function(x) x
  g <- f |>
    with_retry(max_tries = 1, backoff = 0) |>
    with_timing(.report = "attribute")
  expect_true(is_decorated(g))
})
