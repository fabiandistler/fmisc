#' Lightweight Dependency-Injection Container
#'
#' A closure-based dependency-injection container for R. Services are
#' registered by name with a provider (a value or a factory function) and
#' resolved on demand. Factories are auto-wired by formal argument name,
#' with support for singletons, transient services, plain values, child
#' scopes, and test-time overrides.
#'
#' @family di
#' @keywords internal
#' @name fmisc_di
NULL


#' Create a dependency-injection container
#'
#' @param parent Optional parent container. When set, unresolved names
#'   fall through to the parent (used by [child()][fmisc_di]).
#'
#' @return An object of class `"fmisc_di_container"` — a list of
#'   closures with the following elements:
#'   \describe{
#'     \item{`register(name, provider, ..., .lifecycle = NULL, .deps = NULL)`}{
#'       Register a service. `provider` is either a value or a factory
#'       function. `.lifecycle` is one of `"singleton"` (factory called
#'       once, result cached; default when provider is a function),
#'       `"transient"` (factory called every resolve), or `"value"`
#'       (provider stored as-is; default when provider is not a
#'       function). `.deps` optionally maps factory formal names to
#'       registered service names (defaults to formal-name auto-wiring).}
#'     \item{`resolve(name)`}{Resolve a service by name.}
#'     \item{`has(name)`}{Test whether a service is registered
#'       (locally or in a parent scope).}
#'     \item{`names()`}{Character vector of registered service names.}
#'     \item{`unregister(name)`}{Remove a local registration and its
#'       cached singleton.}
#'     \item{`override(name, provider, ..., .lifecycle = NULL, .deps = NULL)`}{
#'       Replace an existing registration and return an invisible
#'       `restore()` closure that reinstates the prior registration and
#'       clears any cached singleton. See also [with_di_overrides()].}
#'     \item{`child()`}{Create a new container whose lookups fall
#'       through to this one; local registrations shadow the parent
#'       without mutating it.}
#'     \item{`inject(fn, ...)`}{Return a wrapper of `fn` whose formals
#'       matching registered service names are pre-bound at call time.
#'       Named `...` arguments explicitly pin dependencies.}
#'   }
#'   Factories may declare a formal named `.container` to receive the
#'   owning container.
#'
#' @family di
#' @seealso [with_di_overrides()]
#' @export
#' @examples
#' \donttest{
#' con <- di_container()
#' con$register("greeting", "hello")
#' con$register("service", function(greeting) {
#'   function(who) {
#'     paste(greeting, who)
#'   }
#' })
#' svc <- con$resolve("service")
#' svc("world")
#' }
di_container <- function(parent = NULL) {
  if (!is.null(parent) && !inherits(parent, "fmisc_di_container")) {
    stop2("`parent` must be `NULL` or an `fmisc_di_container`",
      class = "fmisc_di_error"
    )
  }

  registry <- new.env(parent = emptyenv())
  cache <- new.env(parent = emptyenv())

  parent_internals <- if (is.null(parent)) NULL else attr(parent, ".fmisc_di_internals")

  self <- NULL # bound below; captured by closures

  .has <- function(name) {
    if (exists(name, envir = registry, inherits = FALSE)) {
      return(TRUE)
    }
    if (!is.null(parent_internals)) {
      return(parent_internals$has(name))
    }
    FALSE
  }

  .resolve <- function(name, stack) {
    if (name %in% stack) {
      cycle <- paste(c(stack, name), collapse = " -> ")
      stop2(sprintf("Circular dependency: %s", cycle),
        class = "fmisc_di_cycle"
      )
    }
    if (exists(name, envir = registry, inherits = FALSE)) {
      reg <- get(name, envir = registry, inherits = FALSE)
      if (identical(reg$lifecycle, "value")) {
        return(reg$provider)
      }
      if (identical(reg$lifecycle, "singleton") &&
        exists(name, envir = cache, inherits = FALSE)) {
        return(get(name, envir = cache, inherits = FALSE))
      }
      instance <- .instantiate(name, reg, stack)
      if (identical(reg$lifecycle, "singleton")) {
        assign(name, instance, envir = cache)
      }
      return(instance)
    }
    if (!is.null(parent_internals)) {
      return(parent_internals$resolve(name, stack))
    }
    stop2(sprintf("Service '%s' is not registered", name),
      class = "fmisc_di_missing"
    )
  }

  .instantiate <- function(name, reg, stack) {
    fmls <- formals(reg$provider)
    if (is.null(fmls)) fmls <- list()
    fml_names <- names(fmls)
    deps <- reg$deps
    resolved_args <- list()
    child_stack <- c(stack, name)
    for (nm in fml_names) {
      if (identical(nm, "...")) next
      if (identical(nm, ".container")) {
        resolved_args[[nm]] <- self
        next
      }
      target_name <- if (!is.null(deps) && nm %in% names(deps)) {
        as.character(deps[[nm]])
      } else {
        nm
      }
      has_default <- !identical(fmls[[nm]], quote(expr = ))
      if (.has(target_name)) {
        resolved_args[[nm]] <- .resolve(target_name, child_stack)
      } else if (!has_default) {
        stop2(sprintf(
          "Cannot resolve '%s': dependency '%s' (formal `%s`) not registered",
          name, target_name, nm
        ), class = "fmisc_di_missing")
      }
    }
    do.call(reg$provider, resolved_args)
  }

  self <- structure(list(
    register = function(name, provider, ...,
                        .lifecycle = NULL,
                        .deps = NULL) {
      if (!is.character(name) || length(name) != 1 || !nzchar(name)) {
        stop2("`name` must be a non-empty string", class = "fmisc_di_error")
      }
      if (exists(name, envir = registry, inherits = FALSE)) {
        stop2(
          sprintf("Service '%s' is already registered; use $override() to replace it", name),
          class = "fmisc_di_duplicate"
        )
      }
      lifecycle <- if (is.null(.lifecycle)) {
        if (is.function(provider)) "singleton" else "value"
      } else {
        match.arg(.lifecycle, c("singleton", "transient", "value"))
      }
      if (lifecycle != "value" && !is.function(provider)) {
        stop2(
          sprintf("Provider for lifecycle '%s' must be a function", lifecycle),
          class = "fmisc_di_error"
        )
      }
      if (!is.null(.deps)) {
        if (!is.character(.deps) || is.null(names(.deps)) ||
          any(!nzchar(names(.deps)))) {
          stop2("`.deps` must be a named character vector",
            class = "fmisc_di_error"
          )
        }
      }
      assign(name, list(
        provider = provider,
        lifecycle = lifecycle,
        deps = .deps
      ), envir = registry)
      invisible(self)
    },
    resolve = function(name) {
      if (!is.character(name) || length(name) != 1 || !nzchar(name)) {
        stop2("`name` must be a non-empty string", class = "fmisc_di_error")
      }
      .resolve(name, character(0))
    },
    has = function(name) {
      .has(name)
    },
    names = function() {
      local_names <- ls(envir = registry)
      if (!is.null(parent)) {
        parent_names <- parent$names()
        unique(c(parent_names, local_names))
      } else {
        local_names
      }
    },
    unregister = function(name) {
      if (exists(name, envir = registry, inherits = FALSE)) {
        rm(list = name, envir = registry)
      }
      if (exists(name, envir = cache, inherits = FALSE)) {
        rm(list = name, envir = cache)
      }
      invisible(self)
    },
    override = function(name, provider, ...,
                        .lifecycle = NULL,
                        .deps = NULL) {
      if (!is.character(name) || length(name) != 1 || !nzchar(name)) {
        stop2("`name` must be a non-empty string", class = "fmisc_di_error")
      }
      had_local <- exists(name, envir = registry, inherits = FALSE)
      prior_reg <- if (had_local) {
        get(name, envir = registry, inherits = FALSE)
      } else {
        NULL
      }
      had_cache <- exists(name, envir = cache, inherits = FALSE)
      prior_cache <- if (had_cache) {
        get(name, envir = cache, inherits = FALSE)
      } else {
        NULL
      }

      lifecycle <- if (is.null(.lifecycle)) {
        if (is.function(provider)) "singleton" else "value"
      } else {
        match.arg(.lifecycle, c("singleton", "transient", "value"))
      }
      if (lifecycle != "value" && !is.function(provider)) {
        stop2(
          sprintf("Provider for lifecycle '%s' must be a function", lifecycle),
          class = "fmisc_di_error"
        )
      }

      assign(name, list(
        provider = provider,
        lifecycle = lifecycle,
        deps = .deps
      ), envir = registry)
      if (had_cache) rm(list = name, envir = cache)

      restore <- function() {
        if (had_local) {
          assign(name, prior_reg, envir = registry)
        } else if (exists(name, envir = registry, inherits = FALSE)) {
          rm(list = name, envir = registry)
        }
        if (exists(name, envir = cache, inherits = FALSE)) {
          rm(list = name, envir = cache)
        }
        if (had_cache) {
          assign(name, prior_cache, envir = cache)
        }
        invisible(NULL)
      }
      invisible(restore)
    },
    child = function() {
      di_container(parent = self)
    },
    inject = function(fn, ...) {
      if (!is.function(fn)) {
        stop2("`fn` must be a function", class = "fmisc_di_error")
      }
      pinned <- list(...)
      fmls <- formals(fn)
      if (is.null(fmls)) fmls <- list()
      fml_names <- names(fmls)

      function(...) {
        user_args <- list(...)
        call_args <- pinned
        for (nm in names(user_args)) {
          call_args[[nm]] <- user_args[[nm]]
        }
        for (nm in fml_names) {
          if (identical(nm, "...")) next
          if (nm %in% names(call_args)) next
          if (.has(nm)) {
            call_args[[nm]] <- .resolve(nm, character(0))
          }
        }
        do.call(fn, call_args)
      }
    }
  ), class = "fmisc_di_container")

  attr(self, ".fmisc_di_internals") <- list(
    resolve = .resolve,
    has = .has,
    registry = registry,
    cache = cache
  )

  self
}


#' Temporarily override services in a DI container
#'
#' Applies a set of named overrides to `container`, evaluates `code`,
#' and restores the prior registrations on exit — including on error.
#'
#' @param container An `fmisc_di_container` produced by [di_container()].
#' @param overrides A named list mapping service names to override
#'   providers (values or factory functions).
#' @param code An expression to evaluate with overrides active. Evaluated
#'   lazily in the caller's environment.
#'
#' @return The value of `code`, invisibly if the code itself is invisible.
#' @family di
#' @seealso [di_container()]
#' @export
#' @examples
#' \donttest{
#' con <- di_container()
#' con$register("db", list(query = function(q) "real"))
#' with_di_overrides(con, list(db = list(query = function(q) "mock")), {
#'   con$resolve("db")$query("SELECT 1")
#' })
#' con$resolve("db")$query("SELECT 1")
#' }
with_di_overrides <- function(container, overrides, code) {
  if (!inherits(container, "fmisc_di_container")) {
    stop2("`container` must be an `fmisc_di_container`",
      class = "fmisc_di_error"
    )
  }
  if (!is.list(overrides) || (length(overrides) > 0 && is.null(names(overrides)))) {
    stop2("`overrides` must be a named list", class = "fmisc_di_error")
  }
  restores <- list()
  on.exit({
    for (r in rev(restores)) {
      tryCatch(r(), error = function(e) NULL)
    }
  })
  for (nm in names(overrides)) {
    restores[[length(restores) + 1]] <- container$override(nm, overrides[[nm]])
  }
  force(code)
}


#' Print an fmisc DI container
#'
#' @param x A container returned by [di_container()].
#' @param ... Unused.
#' @return `x`, invisibly.
#' @family di
#' @export
print.fmisc_di_container <- function(x, ...) {
  internals <- attr(x, ".fmisc_di_internals")
  local_names <- sort(ls(envir = internals$registry))
  lines <- cli::cli_fmt({
    cli::cli_h2("fmisc DI container")
    if (length(local_names) == 0) {
      cli::cli_alert_info("No local registrations")
    } else {
      bullets <- character(length(local_names))
      for (i in seq_along(local_names)) {
        nm <- local_names[i]
        reg <- get(nm, envir = internals$registry, inherits = FALSE)
        cached <- exists(nm, envir = internals$cache, inherits = FALSE)
        cache_marker <- if (cached) " (cached)" else ""
        bullets[i] <- sprintf("%s [%s]%s", nm, reg$lifecycle, cache_marker)
      }
      names(bullets) <- rep("*", length(bullets))
      cli::cli_bullets(bullets)
    }
  })
  cat(lines, sep = "\n")
  invisible(x)
}
