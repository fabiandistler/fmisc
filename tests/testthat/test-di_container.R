test_that("di_container register/resolve roundtrips values", {
  con <- di_container()
  con$register("greeting", "hello")
  expect_true(con$has("greeting"))
  expect_equal(con$resolve("greeting"), "hello")
})

test_that("di_container has() and names() reflect registrations", {
  con <- di_container()
  expect_false(con$has("x"))
  expect_length(con$names(), 0L)
  con$register("x", 1L)
  con$register("y", 2L)
  expect_setequal(con$names(), c("x", "y"))
  expect_true(con$has("x"))
})

test_that("singleton factory is called exactly once across resolves", {
  con <- di_container()
  counter <- 0
  con$register("svc", function() {
    counter <<- counter + 1
    list(id = counter)
  })
  a <- con$resolve("svc")
  b <- con$resolve("svc")
  expect_identical(a, b)
  expect_equal(counter, 1L)
})

test_that("transient factory is called on every resolve", {
  con <- di_container()
  counter <- 0
  con$register("svc",
    function() {
      counter <<- counter + 1
      list(id = counter)
    },
    .lifecycle = "transient"
  )
  a <- con$resolve("svc")
  b <- con$resolve("svc")
  expect_equal(counter, 2L)
  expect_false(identical(a, b))
})

test_that("auto-wires dependencies by formal name", {
  con <- di_container()
  con$register("greeting", "hi")
  con$register("subject", "world")
  con$register("service", function(greeting, subject) {
    paste(greeting, subject)
  })
  expect_equal(con$resolve("service"), "hi world")
})

test_that("auto-wires nested dependencies A -> B -> C", {
  con <- di_container()
  con$register("c", "leaf")
  con$register("b", function(c) paste("B(", c, ")"))
  con$register("a", function(b) paste("A(", b, ")"))
  expect_equal(con$resolve("a"), "A( B( leaf ) )")
})

test_that(".deps explicit mapping overrides formal-name auto-wiring", {
  con <- di_container()
  con$register("db_prod", list(name = "prod"))
  con$register("service",
    function(db) db$name,
    .deps = c(db = "db_prod")
  )
  expect_equal(con$resolve("service"), "prod")
})

test_that("resolving unregistered name raises fmisc_di_missing", {
  con <- di_container()
  expect_error(con$resolve("nope"), class = "fmisc_di_missing")
})

test_that("missing auto-wired dependency raises fmisc_di_missing with names", {
  con <- di_container()
  con$register("svc", function(missing_dep) missing_dep)
  err <- tryCatch(con$resolve("svc"), fmisc_di_missing = function(e) e)
  expect_s3_class(err, "fmisc_di_missing")
  expect_match(conditionMessage(err), "svc")
  expect_match(conditionMessage(err), "missing_dep")
})

test_that("auto-wired formal with default is preserved when not registered", {
  con <- di_container()
  con$register("svc", function(x = "fallback") x)
  expect_equal(con$resolve("svc"), "fallback")
})

test_that("circular dependency raises fmisc_di_cycle with path", {
  con <- di_container()
  con$register("a", function(b) b)
  con$register("b", function(a) a)
  err <- tryCatch(con$resolve("a"), fmisc_di_cycle = function(e) e)
  expect_s3_class(err, "fmisc_di_cycle")
  expect_match(conditionMessage(err), "a -> b -> a")
})

test_that("duplicate register raises fmisc_di_duplicate", {
  con <- di_container()
  con$register("x", 1)
  expect_error(con$register("x", 2), class = "fmisc_di_duplicate")
})

test_that("override + restore clears singleton cache", {
  con <- di_container()
  con$register("svc", function() list(version = "orig"))
  first <- con$resolve("svc") # materializes singleton
  expect_equal(first$version, "orig")

  restore <- con$override("svc", list(version = "mock"))
  expect_equal(con$resolve("svc")$version, "mock")

  restore()
  # After restore, the previously cached original singleton returns
  after <- con$resolve("svc")
  expect_equal(after$version, "orig")
  expect_identical(after, first)
})

test_that("override of a fresh service can be restored to remove it", {
  con <- di_container()
  restore <- con$override("new_svc", 42)
  expect_true(con$has("new_svc"))
  restore()
  expect_false(con$has("new_svc"))
})

test_that("with_di_overrides restores after normal completion", {
  con <- di_container()
  con$register("db", list(name = "real"))
  result <- with_di_overrides(con, list(db = list(name = "mock")), {
    con$resolve("db")$name
  })
  expect_equal(result, "mock")
  expect_equal(con$resolve("db")$name, "real")
})

test_that("with_di_overrides restores even when body errors", {
  con <- di_container()
  con$register("db", list(name = "real"))
  expect_error(
    with_di_overrides(con, list(db = list(name = "mock")), {
      stop("boom")
    }),
    "boom"
  )
  expect_equal(con$resolve("db")$name, "real")
})

test_that("child scope shadows parent without mutating it", {
  parent <- di_container()
  parent$register("shared", "parent-value")
  child <- parent$child()
  child$register("shared", "child-value")

  expect_equal(child$resolve("shared"), "child-value")
  expect_equal(parent$resolve("shared"), "parent-value")
})

test_that("child scope resolves parent services via fallthrough", {
  parent <- di_container()
  parent$register("cfg", "config")
  child <- parent$child()
  expect_true(child$has("cfg"))
  expect_equal(child$resolve("cfg"), "config")
})

test_that("inject binds registered formals and leaves other args open", {
  con <- di_container()
  con$register("db", list(query = function(q) paste0("DB(", q, ")")))
  handler <- function(db, req) db$query(req)
  wired <- con$inject(handler)
  expect_equal(wired(req = "sel"), "DB(sel)")
})

test_that("inject respects explicit pinned overrides", {
  con <- di_container()
  con$register("db", list(name = "real"))
  fn <- function(db) db$name
  wired <- con$inject(fn, db = list(name = "pinned"))
  expect_equal(wired(), "pinned")
})

test_that(".container special formal receives the container itself", {
  con <- di_container()
  captured <- NULL
  con$register("svc", function(.container) {
    captured <<- .container
    "made"
  })
  expect_equal(con$resolve("svc"), "made")
  expect_true(inherits(captured, "fmisc_di_container"))
})

test_that("print.fmisc_di_container lists services with lifecycles", {
  con <- di_container()
  con$register("val", 1)
  con$register("svc", function() "s")
  out <- capture.output(print(con))
  expect_true(any(grepl("val", out)))
  expect_true(any(grepl("svc", out)))
  expect_true(any(grepl("singleton", out)))
})
