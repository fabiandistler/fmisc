#' Composable Function Operators (Decorators)
#'
#' A toolkit of composable "function operators" for cross-cutting concerns:
#' retries, timing, logging, caching, and rate-limiting. Each `with_*()`
#' takes a function as its first argument and returns a wrapped function
#' with the class `"fmisc_decorated"`. Wrappers are curry-friendly and
#' compose with the native pipe (see examples).
#'
#' @family decorators
#' @keywords internal
#' @name fmisc_decorators
NULL


mark_decorated <- function(wrapper, inner) {
  attr(wrapper, "fmisc_undecorate") <- inner
  class(wrapper) <- c("fmisc_decorated", "function")
  wrapper
}


#' Retry a function with exponential backoff
#'
#' Wraps `f` so that on error the call is retried up to `max_tries` times,
#' with a delay of `backoff^attempt` seconds between attempts (optionally
#' jittered and capped).
#'
#' @param f A function to wrap.
#' @param max_tries Positive integer. Maximum number of attempts (including
#'   the first). Default `3`.
#' @param backoff Non-negative number. Base of the exponential delay in
#'   seconds; delay for attempt `k` is `backoff^k`. Default `2` (i.e. 2, 4,
#'   8, 16 s). Use `0` to disable delays.
#' @param ... Passed to the wrapped function on each call. Reserved for
#'   future extensions; currently forwarded via the wrapper's `...`.
#' @param .on_error Optional predicate `function(cnd) -> logical`. When
#'   `TRUE` the error is retried; when `FALSE` it is re-raised immediately.
#'   Default `NULL` retries all errors.
#' @param .max_delay Numeric cap on individual retry delays in seconds.
#'   Default `Inf`.
#' @param .jitter Logical. If `TRUE` (default), each delay is multiplied by
#'   a uniform random factor in `[0.5, 1.5]` to avoid synchronized retries.
#' @param .on_retry Optional callback `function(attempt, delay, cnd)`
#'   invoked before each sleep. Errors in the callback are swallowed.
#'
#' @return A function that forwards its arguments to `f`. On persistent
#'   failure raises a condition of class `"fmisc_retry_exhausted"`
#'   preserving the original condition's classes.
#' @family decorators
#' @export
#' @examples
#' \dontrun{
#' flaky <- function(x) {
#'   if (runif(1) < 0.7) stop("transient")
#'   x * 2
#' }
#' robust <- with_retry(flaky, max_tries = 5, backoff = 0.1)
#' robust(21)
#' }
with_retry <- function(f,
                       max_tries = 3L,
                       backoff = 2,
                       ...,
                       .on_error = NULL,
                       .max_delay = Inf,
                       .jitter = TRUE,
                       .on_retry = NULL) {
  if (!is.function(f)) {
    stop2("`f` must be a function", class = "fmisc_decorator_error")
  }
  if (!is.numeric(max_tries) || length(max_tries) != 1 || max_tries < 1) {
    stop2(
      sprintf("`max_tries` must be a positive integer, got: %s", format(max_tries)),
      class = "fmisc_decorator_error"
    )
  }
  max_tries <- as.integer(max_tries)
  if (!is.numeric(backoff) || length(backoff) != 1 || backoff < 0) {
    stop2(
      sprintf("`backoff` must be a non-negative number, got: %s", format(backoff)),
      class = "fmisc_decorator_error"
    )
  }
  if (!is.null(.on_error) && !is.function(.on_error)) {
    stop2("`.on_error` must be `NULL` or a predicate function", class = "fmisc_decorator_error")
  }
  if (!is.null(.on_retry) && !is.function(.on_retry)) {
    stop2("`.on_retry` must be `NULL` or a callback function", class = "fmisc_decorator_error")
  }

  wrapper <- function(...) {
    for (attempt in seq_len(max_tries)) {
      outcome <- tryCatch(
        list(ok = TRUE, value = f(...)),
        error = function(cnd) list(ok = FALSE, cnd = cnd)
      )
      if (isTRUE(outcome$ok)) {
        return(outcome$value)
      }
      cnd <- outcome$cnd
      if (!is.null(.on_error) && !isTRUE(.on_error(cnd))) {
        stop(cnd)
      }
      if (attempt == max_tries) {
        orig_classes <- setdiff(class(cnd), c("error", "condition", "simpleError"))
        stop2(
          sprintf(
            "Retry exhausted after %d attempts: %s",
            max_tries, conditionMessage(cnd)
          ),
          class = c("fmisc_retry_exhausted", orig_classes)
        )
      }
      delay <- min(backoff^attempt, .max_delay)
      if (isTRUE(.jitter)) delay <- delay * stats::runif(1, 0.5, 1.5)
      if (!is.null(.on_retry)) {
        tryCatch(.on_retry(attempt, delay, cnd), error = function(e) NULL)
      }
      if (delay > 0) Sys.sleep(delay)
    }
    invisible(NULL)
  }
  mark_decorated(wrapper, f)
}


#' Measure a function's elapsed wall-clock time
#'
#' Wraps `f` so each call is timed with `proc.time()`. Reports elapsed
#' time on both success and failure (via `on.exit()`), either as a cli
#' message, attached as an `"elapsed"` attribute on the return value, or
#' passed to a user callback.
#'
#' @param f A function to wrap.
#' @param ... Reserved for future extension.
#' @param .report One of `"message"` (default; cli info alert),
#'   `"attribute"` (attach `attr(result, "elapsed")`), `"callback"`
#'   (invoke `.callback(name, elapsed, ok)`).
#' @param .callback Function used when `.report = "callback"`.
#' @param .threshold Non-negative numeric. Only report when elapsed time
#'   in seconds is `>= .threshold`. Default `0`.
#'
#' @return A function that forwards its arguments to `f`.
#' @family decorators
#' @export
#' @examples
#' \donttest{
#' g <- with_timing(function(x) {
#'   Sys.sleep(0.05)
#'   x
#' }, .threshold = 0)
#' g(42)
#' }
with_timing <- function(f,
                        ...,
                        .report = c("message", "attribute", "callback"),
                        .callback = NULL,
                        .threshold = 0) {
  if (!is.function(f)) {
    stop2("`f` must be a function", class = "fmisc_decorator_error")
  }
  .report <- match.arg(.report)
  if (identical(.report, "callback") && !is.function(.callback)) {
    stop2(
      "`.callback` must be a function when `.report = 'callback'`",
      class = "fmisc_decorator_error"
    )
  }
  if (!is.numeric(.threshold) || length(.threshold) != 1 || .threshold < 0) {
    stop2(
      "`.threshold` must be a non-negative number",
      class = "fmisc_decorator_error"
    )
  }
  fn_label <- deparse(substitute(f))[1]

  wrapper <- function(...) {
    start <- proc.time()[["elapsed"]]
    status <- "pending"
    on.exit({
      elapsed <- proc.time()[["elapsed"]] - start
      if (elapsed >= .threshold && !identical(.report, "attribute")) {
        if (identical(.report, "message")) {
          if (identical(status, "ok")) {
            cli::cli_alert_info(sprintf(
              "%s took %.3fs", fn_label, elapsed
            ))
          } else {
            cli::cli_alert_warning(sprintf(
              "%s failed after %.3fs", fn_label, elapsed
            ))
          }
        } else if (identical(.report, "callback")) {
          tryCatch(
            .callback(fn_label, elapsed, identical(status, "ok")),
            error = function(e) NULL
          )
        }
      }
    })
    result <- f(...)
    status <- "ok"
    if (identical(.report, "attribute")) {
      elapsed <- proc.time()[["elapsed"]] - start
      attr(result, "elapsed") <- elapsed
    }
    result
  }
  mark_decorated(wrapper, f)
}


#' Log calls, results, and errors of a function
#'
#' Wraps `f` with a lightweight logger emitting `"call"`, `"success"`,
#' and `"error"` events. The default logger uses cli alerts. Errors are
#' logged and re-raised unchanged.
#'
#' @param f A function to wrap.
#' @param ... Reserved for future extension.
#' @param .logger Optional user function `function(event, data)`; `event`
#'   is one of `"call"`, `"success"`, `"error"`; `data` is a list with
#'   at least `name`, plus event-specific fields. Default `NULL` uses cli.
#' @param .log_args Logical. Whether to include a short deparse of the
#'   arguments in the `"call"` event. Default `TRUE`.
#' @param .log_result Logical. Whether to include a short deparse of the
#'   return value in the `"success"` event. Default `FALSE`.
#' @param .name Optional character name to display for the function.
#'   Defaults to the deparsed `f` symbol.
#'
#' @return A function that forwards its arguments to `f`.
#' @family decorators
#' @export
#' @examples
#' \donttest{
#' g <- with_logging(function(x, y) x + y, .log_result = TRUE)
#' g(1, 2)
#' }
with_logging <- function(f,
                         ...,
                         .logger = NULL,
                         .log_args = TRUE,
                         .log_result = FALSE,
                         .name = NULL) {
  if (!is.function(f)) {
    stop2("`f` must be a function", class = "fmisc_decorator_error")
  }
  if (!is.null(.logger) && !is.function(.logger)) {
    stop2("`.logger` must be `NULL` or a function", class = "fmisc_decorator_error")
  }
  fn_label <- if (!is.null(.name)) .name else deparse(substitute(f))[1]

  default_logger <- function(event, data) {
    if (identical(event, "call")) {
      if (nzchar(data$args_str)) {
        cli::cli_alert_info(sprintf(
          "call %s(%s)", data$name, data$args_str
        ))
      } else {
        cli::cli_alert_info(sprintf("call %s()", data$name))
      }
    } else if (identical(event, "success")) {
      if (nzchar(data$result_str)) {
        cli::cli_alert_success(sprintf(
          "%s -> %s", data$name, data$result_str
        ))
      } else {
        cli::cli_alert_success(sprintf("%s ok", data$name))
      }
    } else if (identical(event, "error")) {
      cli::cli_alert_danger(sprintf(
        "%s failed: %s", data$name, data$message
      ))
    }
  }
  logger <- if (is.null(.logger)) default_logger else .logger

  safe_deparse <- function(x) {
    tryCatch(
      {
        s <- deparse(x, control = c("keepInteger", "keepNA"), nlines = 1L)
        if (length(s) == 0) "?" else s[1]
      },
      error = function(e) "?"
    )
  }

  wrapper <- function(...) {
    args_str <- if (isTRUE(.log_args)) {
      parts <- vapply(list(...), safe_deparse, character(1))
      paste(parts, collapse = ", ")
    } else {
      ""
    }
    tryCatch(
      logger("call", list(name = fn_label, args_str = args_str)),
      error = function(e) NULL
    )
    result <- tryCatch(
      f(...),
      error = function(cnd) {
        tryCatch(
          logger("error", list(
            name = fn_label,
            message = conditionMessage(cnd),
            cnd = cnd
          )),
          error = function(e) NULL
        )
        stop(cnd)
      }
    )
    result_str <- if (isTRUE(.log_result)) safe_deparse(result) else ""
    tryCatch(
      logger("success", list(
        name = fn_label,
        result = result,
        result_str = result_str
      )),
      error = function(e) NULL
    )
    result
  }
  mark_decorated(wrapper, f)
}


#' Memoise a function's results
#'
#' Wraps `f` so that repeated calls with the same arguments return a cached
#' value. When `.max_size = Inf` and `.ttl = Inf` and the `memoise` package
#' is available, delegates to [memoise::memoise()]. Otherwise uses a built-
#' in environment-backed cache supporting LRU eviction and time-to-live.
#'
#' @param f A function to wrap.
#' @param ... Reserved for future extension.
#' @param .key Optional function `function(args_list) -> character(1)`
#'   producing a cache key from the argument list. Default `NULL` uses a
#'   `deparse()`-based key over all arguments.
#' @param .max_size Maximum number of cached entries. `Inf` (default) for
#'   unbounded. When exceeded, oldest entries are evicted (LRU).
#' @param .ttl Time-to-live in seconds for cached entries. `Inf` (default)
#'   never expires.
#'
#' @return A function that forwards its arguments to `f`. Attach
#'   `cache_clear()` and `cache_info()` helpers via [cache_clear()] and
#'   [cache_info()].
#' @family decorators
#' @seealso [cache_clear()], [cache_info()]
#' @export
#' @examples
#' \donttest{
#' calls <- 0
#' slow <- function(x) {
#'   calls <<- calls + 1
#'   x * 2
#' }
#' fast <- with_cache(slow)
#' fast(21)
#' fast(21)
#' calls
#' }
with_cache <- function(f,
                       ...,
                       .key = NULL,
                       .max_size = Inf,
                       .ttl = Inf) {
  if (!is.function(f)) {
    stop2("`f` must be a function", class = "fmisc_decorator_error")
  }
  if (!is.null(.key) && !is.function(.key)) {
    stop2("`.key` must be `NULL` or a function", class = "fmisc_decorator_error")
  }
  if (!is.numeric(.max_size) || length(.max_size) != 1 || .max_size <= 0) {
    stop2("`.max_size` must be a positive number or `Inf`", class = "fmisc_decorator_error")
  }
  if (!is.numeric(.ttl) || length(.ttl) != 1 || .ttl <= 0) {
    stop2("`.ttl` must be a positive number or `Inf`", class = "fmisc_decorator_error")
  }

  use_memoise <- is.infinite(.max_size) &&
    is.infinite(.ttl) &&
    is.null(.key) &&
    requireNamespace("memoise", quietly = TRUE)

  if (use_memoise) {
    memo <- memoise::memoise(f)
    wrapper <- function(...) memo(...)
    clear_fn <- function() {
      memoise::forget(memo)
      invisible(NULL)
    }
    info_fn <- function() {
      list(backend = "memoise", size = NA_integer_)
    }
  } else {
    state <- new.env(parent = emptyenv())
    state$store <- list()
    state$keys <- character(0)

    make_key <- function(args_list) {
      raw <- if (!is.null(.key)) {
        as.character(.key(args_list))[1]
      } else {
        parts <- vapply(args_list, function(x) {
          tryCatch(
            paste(deparse(x, control = c("keepInteger", "keepNA")), collapse = ""),
            error = function(e) "?"
          )
        }, character(1))
        paste(parts, collapse = "\x1f")
      }
      # Prefix guarantees a non-empty key so `list[[key]] <- value` works
      # even for zero-argument functions (paste(character(0)) is "").
      paste0(".k.", raw)
    }

    wrapper <- function(...) {
      args_list <- list(...)
      key <- make_key(args_list)
      hit <- isTRUE(key %in% state$keys)
      if (hit) {
        entry <- state$store[[key]]
        if (is.finite(.ttl)) {
          age <- as.numeric(Sys.time()) - entry$time
          if (isTRUE(age > .ttl)) {
            state$store[[key]] <- NULL
            state$keys <- setdiff(state$keys, key)
            hit <- FALSE
          }
        }
      }
      if (hit) {
        state$keys <- c(setdiff(state$keys, key), key)
        return(entry$value)
      }
      value <- f(...)
      state$store[[key]] <- list(value = value, time = as.numeric(Sys.time()))
      state$keys <- c(setdiff(state$keys, key), key)
      if (is.finite(.max_size) && length(state$keys) > .max_size) {
        evict_n <- length(state$keys) - as.integer(.max_size)
        to_evict <- state$keys[seq_len(evict_n)]
        state$store[to_evict] <- NULL
        state$keys <- state$keys[-seq_len(evict_n)]
      }
      value
    }
    clear_fn <- function() {
      state$store <- list()
      state$keys <- character(0)
      invisible(NULL)
    }
    info_fn <- function() {
      list(
        backend = "env",
        size = length(state$keys),
        keys = state$keys
      )
    }
  }

  attr(wrapper, "cache_clear") <- clear_fn
  attr(wrapper, "cache_info") <- info_fn
  mark_decorated(wrapper, f)
}


#' Clear or inspect a cached function's cache
#'
#' @param f A function previously wrapped with [with_cache()].
#' @return `cache_clear()` returns `NULL` invisibly. `cache_info()` returns
#'   a list with `backend` (`"memoise"` or `"env"`), `size`, and (for
#'   `"env"`) the character vector of stored keys.
#' @family decorators
#' @export
cache_clear <- function(f) {
  clear <- attr(f, "cache_clear")
  if (is.null(clear)) {
    stop2("`f` is not a cached function (wrap it with `with_cache()` first)",
      class = "fmisc_decorator_error"
    )
  }
  clear()
}

#' @rdname cache_clear
#' @export
cache_info <- function(f) {
  info <- attr(f, "cache_info")
  if (is.null(info)) {
    stop2("`f` is not a cached function (wrap it with `with_cache()` first)",
      class = "fmisc_decorator_error"
    )
  }
  info()
}


#' Rate-limit a function to N calls per period
#'
#' Wraps `f` so at most `n` calls are permitted within any rolling
#' `period`-second window. When the limit is reached, either sleeps until
#' a slot opens (`.wait = TRUE`, the default) or raises an error of class
#' `"fmisc_rate_limit_exceeded"` (`.wait = FALSE`).
#'
#' @param f A function to wrap.
#' @param n Positive integer. Maximum calls per window.
#' @param period Positive numeric. Window length in seconds.
#' @param ... Reserved for future extension.
#' @param .wait Logical. If `TRUE` sleep to obey the limit; if `FALSE`
#'   error immediately when the limit would be exceeded.
#'
#' @return A function that forwards its arguments to `f`.
#' @family decorators
#' @export
#' @examples
#' \dontrun{
#' g <- with_rate_limit(function(x) x, n = 2, period = 1)
#' g(1)
#' g(2)
#' g(3) # third call sleeps until the window rolls
#' }
with_rate_limit <- function(f, n, period = 1, ..., .wait = TRUE) {
  if (!is.function(f)) {
    stop2("`f` must be a function", class = "fmisc_decorator_error")
  }
  if (!is.numeric(n) || length(n) != 1 || n <= 0) {
    stop2("`n` must be a positive number", class = "fmisc_decorator_error")
  }
  if (!is.numeric(period) || length(period) != 1 || period <= 0) {
    stop2("`period` must be a positive number", class = "fmisc_decorator_error")
  }
  n <- as.integer(n)
  state <- new.env(parent = emptyenv())
  state$timestamps <- numeric(0)

  wrapper <- function(...) {
    now <- as.numeric(Sys.time())
    state$timestamps <- state$timestamps[state$timestamps > (now - period)]
    if (length(state$timestamps) >= n) {
      wait <- period - (now - state$timestamps[1])
      if (isTRUE(.wait)) {
        if (wait > 0) Sys.sleep(wait)
        now <- as.numeric(Sys.time())
        state$timestamps <- state$timestamps[state$timestamps > (now - period)]
      } else {
        stop2(
          sprintf("Rate limit exceeded: %d calls per %gs", n, period),
          class = "fmisc_rate_limit_exceeded"
        )
      }
    }
    state$timestamps <- c(state$timestamps, as.numeric(Sys.time()))
    f(...)
  }
  mark_decorated(wrapper, f)
}


#' Compose several decorators onto a function
#'
#' Applies decorators to `f` left-to-right so that
#' `decorate(f, d1, d2)` is equivalent to `d2(d1(f))` and reads outside-in.
#' Each decorator must be a unary function `function(g) -> function`.
#' For decorators with configuration, wrap them in a closure or use the
#' native pipe directly (which is the recommended idiom).
#'
#' @param f A function to decorate.
#' @param ... Decorators — each a unary function taking `f` and returning
#'   a wrapped function.
#'
#' @return The decorated function.
#' @family decorators
#' @export
#' @examples
#' \donttest{
#' add1 <- function(x) x + 1
#' g <- decorate(
#'   add1,
#'   function(fn) with_retry(fn, max_tries = 2, backoff = 0),
#'   function(fn) with_timing(fn, .threshold = Inf)
#' )
#' g(41)
#' }
decorate <- function(f, ...) {
  if (!is.function(f)) {
    stop2("`f` must be a function", class = "fmisc_decorator_error")
  }
  decs <- list(...)
  if (length(decs) == 0) {
    return(f)
  }
  for (d in decs) {
    if (!is.function(d)) {
      stop2("Each decorator must be a unary function taking `f`",
        class = "fmisc_decorator_error"
      )
    }
  }
  Reduce(function(g, d) d(g), decs, f)
}


#' Unwrap a decorated function by one layer
#'
#' @param f A function possibly wrapped by one of the `with_*()` decorators.
#' @return The inner function `f` wrapped, or `f` unchanged if it is not
#'   a decorated function.
#' @family decorators
#' @export
undecorate <- function(f) {
  inner <- attr(f, "fmisc_undecorate")
  if (is.null(inner)) f else inner
}


#' Test whether a function was produced by a decorator
#'
#' @param f Any object.
#' @return `TRUE` if `f` inherits from `"fmisc_decorated"`, else `FALSE`.
#' @family decorators
#' @export
is_decorated <- function(f) {
  inherits(f, "fmisc_decorated")
}
