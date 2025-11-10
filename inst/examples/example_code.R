# Example R code demonstrating issues that fmisc can detect and fix

# ============================================================================
# Issues detected by lintr linters
# ============================================================================

# TODO comments (detected by todo_fixme_linter)
# TODO: implement error handling here
calculate_mean <- function(x) {
  # FIXME: this doesn't handle NA values correctly
  sum(x) / length(x)
}

# XXX: this is a questionable approach
# HACK: temporary workaround

# Deprecated functions (detected by deprecated_function_linter)
result <- sapply(1:10, function(x) x^2)
require(dplyr)

# ============================================================================
# Issues fixed by flir rules
# ============================================================================

# T/F instead of TRUE/FALSE (replace-t-with-true, replace-f-with-false)
is_valid <- T
is_complete <- F
flags <- c(T, F, T, T, F)

# Deprecated dplyr functions (deprecated-sample-n, deprecated-sample-frac)
library(dplyr)
sampled_rows <- sample_n(mtcars, 10)
sampled_frac <- sample_frac(mtcars, 0.1)

# Unsafe sequence generation (use-seq-along)
my_vector <- c(1, 2, 3, 4, 5)
for (i in 1:length(my_vector)) {
  print(my_vector[i])
}

# Empty vector case - this is especially problematic
empty_vec <- numeric(0)
for (i in 1:length(empty_vec)) {
  # This will iterate with i = 1, then i = 0, causing errors!
  print(paste("Index:", i))
}

# ============================================================================
# Corrected versions
# ============================================================================

# Corrected: proper TRUE/FALSE
is_valid_fixed <- TRUE
is_complete_fixed <- FALSE
flags_fixed <- c(TRUE, FALSE, TRUE, TRUE, FALSE)

# Corrected: modern dplyr
sampled_rows_fixed <- slice_sample(mtcars, n = 10)
sampled_frac_fixed <- slice_sample(mtcars, prop = 0.1)

# Corrected: safe sequence generation
for (i in seq_along(my_vector)) {
  print(my_vector[i])
}

# Corrected: safe with empty vectors
for (i in seq_along(empty_vec)) {
  # This will not iterate at all, as expected
  print(paste("Index:", i))
}

# Corrected: type-stable iteration instead of sapply
result_fixed <- vapply(1:10, function(x) x^2, numeric(1))
