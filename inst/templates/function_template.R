# ==============================================================================
# R Function Template - Best Practices (Tidyverse Style & Design)
# ==============================================================================
#
# This template contains best practices that are NOT automatically detected by
# lintr/styler. Delete what you don't need.
#
# Sources:
#   - https://style.tidyverse.org/
#   - https://design.tidyverse.org/
#
# ==============================================================================

# --- ROXYGEN DOCUMENTATION ----------------------------------------------------
# Tip: Title and description don't need @title/@description tags
# Tip: Backticks for code: `na.rm`, `TRUE`, `NULL`
# Tip: Cross-reference with [function_name()] for links
# Tip: With {sinew} you can automatically create the roxygen2 skeleton.

#' Short title (one line, no period at the end)
#'
#' Longer description in one or more paragraphs.
#' Explains WHAT the function does, not HOW (that belongs in Details).
#'
#' @details
#' Technical details about the implementation.
#' Use for lists:
#' * Item 1
#' * Item 2
#'
#' @section Special Notes:
#' For longer thematic sections.
#'
#' @param x [DATA argument] Description. Data arguments come FIRST.
#'   Multi-line description indented with 2 additional spaces. Should not have
#'   a name to avoid partial matching.
#' @param pattern [DESCRIPTOR argument] Description. Descriptors are usually
#'   required and describe essential details of the operation.
#' @param ... Place dots between data/descriptors and details.
#'   Forces users to name detail arguments with full names.
#' @param na.rm [DETAIL argument] Description. Details are optional,
#'   have defaults and control fine points. Default: `FALSE`.
#' @param verbose [DETAIL argument] Description. Default: `TRUE`.
#'
#' @return Describe the return type and structure.
#'   - For transformations: "A [type] of the same length as `x`"
#'   - For side-effects: "Returns `x` invisibly (for pipe usage)"
#'
#' @export
#' @examples
#' # Simple example
#' my_function(1:10)
#'
#' # With optional arguments
#' my_function(1:10, na.rm = TRUE)
#'
#' @seealso [related_function()], [other_function()]
#' @family family_name
my_function <- function(x,
                        pattern,
                        ...,
                        na.rm = FALSE,
                        verbose = TRUE) {
  # --- ARGUMENT ORDERING CHECKLIST (design.tidyverse.org) -----------------------
  # [ ] 1. DATA arguments first (x, y, data) - required, determine output shape
  # [ ] 2. DESCRIPTOR arguments (pattern, by) - describe the operation
  # [ ] 3. ... (if used) - between required and optional
  # [ ] 4. DETAIL arguments at the end (na.rm, verbose) - optional with defaults
  #
  # Rule of thumb: Required without default -> Optional with default
  # Importance: Descending from left to right
  #
  # NOTE: lintr's function_argument_linter() only checks if args without default
  # come before args with default - NOT the data/descriptor/details categorization!

  # --- ARGUMENT VALIDATION ------------------------------------------------------
  # Tip: cli::cli_abort() instead of stop() for better error messages
  # Tip: Error messages: "must be" when cause is clear, "can't" when unclear
  # Tip: Argument name in backticks: `x`

  # Option A: Simple validation with stopifnot (for internal functions)
  stopifnot(
    is.numeric(x),
    length(na.rm) == 1L,
    is.logical(na.rm)
  )

  # Option B: Informative error messages with cli (for exported functions)
  # Structure: Problem statement + Context (x) + Hint (i)
  if (!is.numeric(x)) {
    cli::cli_abort(
      c(
        # Problem statement: "must be" when clear, "can't" when unclear
        "{.arg x} must be a numeric vector.",
        # Context with x-bullet
        "x" = "You provided a {.cls {class(x)}} vector.",
        # Optional: Hint with i-bullet
        "i" = "Convert with {.fn as.numeric} if needed."
      ),
      call = rlang::caller_env()
    )
  }

  # Option C: rlang type checks (compact)
  rlang::check_required(x)
  x <- rlang::arg_match(x, c("option1", "option2"))

  # Option D: {checkmate}

  # --- DOTS HANDLING ------------------------------------------------------------
  # When ... is used: ALWAYS check if all dots were used
  # This prevents silent errors from typos in argument names

  rlang::check_dots_used()
  # OR for functions that should not use ... at all:
  rlang::check_dots_empty()
  # OR when ... should only have unnamed values (like sum()):
  rlang::check_dots_unnamed()

  # --- NULL PATTERN FOR OPTIONAL ARGUMENTS --------------------------------------
  # Use NULL as default for complex calculations
  # NOT: function(x, n = nrow(x)) - this is a "magical default"
  # BETTER: function(x, n = NULL) with calculation in body
  # %||% is the null-coalescing operator from rlang

  # Complex default calculation
  computed_default <- na.rm %||% determine_na_handling(x)

  # AVOID "magical defaults" - Defaults that behave differently when
  # explicitly passed vs. omitted:
  # - No defaults that depend on internal variables
  # - Don't use missing()
  # - No unexported functions as default

  # --- PROGRESS/MESSAGES FOR IMPORTANT DEFAULTS ---------------------------------
  # If a default is "guessed", inform the user
  # Important for descriptor arguments with defaults (e.g. by in left_join)

  if (verbose && is.null(pattern)) {
    pattern <- detect_pattern(x)
    cli::cli_inform(
      "Using detected pattern: {.val {pattern}}"
    )
  }

  # --- FUNCTION BODY ------------------------------------------------------------
  # Tip: Comments explain WHY, not WHAT
  # Tip: return() only for early returns, not at the end
  # Tip: Use tryCatch() for robustness

  # Early return example - return() is appropriate here
  if (length(x) == 0L) {
    return(x)
  }

  # Normal calculation
  result <- x + 1

  # Last expression is automatically returned - NO return() needed
  result
}

# --- SIDE-EFFECT FUNCTIONS ----------------------------------------------------
# Functions that primarily have side-effects (print, plot, write)
# should return the first argument invisibly for pipe usage

#' Print method for my_class
#' @export
print.my_class <- function(x, ...) {
  cat("My Class Object\n")
  cat("Value:", x$value, "\n")
  invisible(x)
}

# --- OPTIONS OBJECT PATTERN ---------------------------------------------------
# For many detail arguments: Extract into separate options object
# Examples: glm.control(), readr::locale(), tune::control_resamples()

#' Create options for my_function
#'
#' @param opt1 Description.
#' @param opt2 Description.
#' @return A `my_function_opts` object.
#' @export
my_function_opts <- function(opt1 = 1, opt2 = 2) {
  structure(
    list(
      opt1 = opt1,
      opt2 = opt2
    ),
    class = "mypackage_my_function_opts"
  )
}

# Usage in main function:
# my_function <- function(x, ..., opts = my_function_opts()) {
#   if (!inherits(opts, "mypackage_my_function_opts")) {
#     cli::cli_abort("{.arg opts} must be created by {.fn my_function_opts}.")
#   }
# }

# --- ERROR CONSTRUCTOR PATTERN ------------------------------------------------
# For repeated errors: Custom error classes for better testing/handling
# Enables: expect_error(..., class = "mypackage_error_not_found")

#' @noRd
stop_not_found <- function(path, call = rlang::caller_env()) {
  cli::cli_abort(
    c("File not found: {.path {path}}"),
    class = "mypackage_error_not_found",
    path = path,
    call = call
  )
}

# --- INTERNAL/PRIVATE FUNCTIONS -----------------------------------------------
# Document with @noRd to prevent .Rd generation

#' Helper function for internal use
#'
#' @param x Input.
#' @return Processed input.
#' @noRd
.my_helper <- function(x) {
  x
}

# ==============================================================================
# DESIGN PRINCIPLES CHECKLIST
# ==============================================================================
#
# ARGUMENT DESIGN (NOT checked by lintr):
# [ ] Argument order: data -> descriptors -> ... -> details
# [ ] Required args have NO default
# [ ] Optional args have a default
# [ ] Defaults are short and understandable (not: x = complex_calculation())
# [ ] NULL for complex default calculations in body
# [ ] No "magical" defaults (default != explicitly passed value)
# [ ] No missing() usage
# [ ] No internal variables in defaults
# [ ] Important auto-defaults are communicated to the user
#
# ERROR HANDLING (NOT checked by lintr):
# [ ] cli::cli_abort() instead of stop()
# [ ] Error messages: Problem + Context (x) + optional Hint (i)
# [ ] "must be" when cause is clear, "can't" when unclear
# [ ] Error constructors for repeated errors
# [ ] call = rlang::caller_env() for correct error localization
#
# DOTS HANDLING (NOT checked by lintr):
# [ ] ... between data/descriptors and details
# [ ] rlang::check_dots_used() or check_dots_empty()
#
# FUNCTION OUTPUT (NOT checked by lintr):
# [ ] return() only for early returns
# [ ] Side-effect functions: return invisible(x)
# [ ] Output shape follows input shape (for pipe compatibility)
#
# DOCUMENTATION (partially checked by lintr):
# [ ] Title: One line, no period
# [ ] @param: Type and meaning, mention default if important
# [ ] @return: Type and structure
# [ ] @examples: Runnable examples
# [ ] Backticks for code in documentation
# [ ] @inheritParams for shared parameters
#
# ==============================================================================
