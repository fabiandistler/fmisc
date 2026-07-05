# Example R code demonstrating issues that fmisc's flir rules detect and fix

# ============================================================================
# Issues fixed by fmisc flir rules
# ============================================================================

# Deprecated dplyr functions (deprecated-sample-n, deprecated-sample-frac)
library(dplyr)
sampled_rows <- sample_n(mtcars, 10)
sampled_frac <- sample_frac(mtcars, 0.1)

# ============================================================================
# Corrected versions
# ============================================================================

# Corrected: modern dplyr
sampled_rows_fixed <- slice_sample(mtcars, n = 10)
sampled_frac_fixed <- slice_sample(mtcars, prop = 0.1)
