#' Data Science and Software Development Helper Functions for R
#'
#' This file contains a collection of useful helper functions for common
#' data science and software development tasks in R.

# ==============================================================================
# DATA EXPLORATION HELPERS
# ==============================================================================

#' Quick summary statistics for numeric columns
#'
#' @param df A data frame
#' @param round_digits Number of decimal places (default: 2)
#' @return A data frame with summary statistics
#' @examples
#' quick_summary(mtcars)
quick_summary <- function(df, round_digits = 2) {
  numeric_cols <- sapply(df, is.numeric)
  if (sum(numeric_cols) == 0) {
    stop("No numeric columns found in the data frame")
  }

  stats <- data.frame(
    variable = names(df)[numeric_cols],
    mean = sapply(df[, numeric_cols, drop = FALSE], mean, na.rm = TRUE),
    median = sapply(df[, numeric_cols, drop = FALSE], median, na.rm = TRUE),
    sd = sapply(df[, numeric_cols, drop = FALSE], sd, na.rm = TRUE),
    min = sapply(df[, numeric_cols, drop = FALSE], min, na.rm = TRUE),
    max = sapply(df[, numeric_cols, drop = FALSE], max, na.rm = TRUE),
    missing = sapply(df[, numeric_cols, drop = FALSE], function(x) sum(is.na(x))),
    row.names = NULL
  )

  stats[, -1] <- round(stats[, -1], round_digits)
  return(stats)
}

#' Count missing values by column
#'
#' @param df A data frame
#' @param pct Whether to return percentages (default: TRUE)
#' @return A data frame with missing value counts
#' @examples
#' missing_summary(airquality)
missing_summary <- function(df, pct = TRUE) {
  missing_counts <- sapply(df, function(x) sum(is.na(x)))

  result <- data.frame(
    column = names(missing_counts),
    missing_count = as.numeric(missing_counts),
    row.names = NULL
  )

  if (pct) {
    result$missing_pct <- round(100 * result$missing_count / nrow(df), 2)
  }

  result <- result[order(-result$missing_count), ]
  return(result)
}

#' Identify outliers using IQR method
#'
#' @param x A numeric vector
#' @param multiplier IQR multiplier for outlier detection (default: 1.5)
#' @return Indices of outliers
#' @examples
#' outliers <- find_outliers(mtcars$mpg)
find_outliers <- function(x, multiplier = 1.5) {
  q1 <- quantile(x, 0.25, na.rm = TRUE)
  q3 <- quantile(x, 0.75, na.rm = TRUE)
  iqr <- q3 - q1

  lower_bound <- q1 - multiplier * iqr
  upper_bound <- q3 + multiplier * iqr

  which(x < lower_bound | x > upper_bound)
}

# ==============================================================================
# DATA MANIPULATION HELPERS
# ==============================================================================

#' Normalize numeric columns to 0-1 range
#'
#' @param x A numeric vector or data frame
#' @return Normalized vector or data frame
#' @examples
#' normalize(mtcars$mpg)
normalize <- function(x) {
  if (is.data.frame(x)) {
    numeric_cols <- sapply(x, is.numeric)
    x[, numeric_cols] <- lapply(x[, numeric_cols, drop = FALSE], normalize)
    return(x)
  } else {
    (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
  }
}

#' Standardize numeric columns (z-score)
#'
#' @param x A numeric vector or data frame
#' @return Standardized vector or data frame
#' @examples
#' standardize(mtcars$mpg)
standardize <- function(x) {
  if (is.data.frame(x)) {
    numeric_cols <- sapply(x, is.numeric)
    x[, numeric_cols] <- lapply(x[, numeric_cols, drop = FALSE], standardize)
    return(x)
  } else {
    (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
  }
}

#' Convert multiple columns to factors
#'
#' @param df A data frame
#' @param cols Column names to convert
#' @return Data frame with specified columns as factors
#' @examples
#' to_factors(mtcars, c("cyl", "gear"))
to_factors <- function(df, cols) {
  df[cols] <- lapply(df[cols], as.factor)
  return(df)
}

#' Split data into train/test sets
#'
#' @param df A data frame
#' @param train_pct Training set percentage (default: 0.8)
#' @param seed Random seed for reproducibility
#' @return List with train and test data frames
#' @examples
#' split_data(mtcars, train_pct = 0.7, seed = 123)
split_data <- function(df, train_pct = 0.8, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)

  train_idx <- sample(seq_len(nrow(df)), size = floor(train_pct * nrow(df)))

  list(
    train = df[train_idx, ],
    test = df[-train_idx, ]
  )
}

# ==============================================================================
# PLOTTING HELPERS
# ==============================================================================

#' Create correlation heatmap data
#'
#' @param df A data frame with numeric columns
#' @param method Correlation method ("pearson", "spearman", "kendall")
#' @return Correlation matrix
#' @examples
#' cor_matrix(mtcars)
cor_matrix <- function(df, method = "pearson") {
  numeric_cols <- sapply(df, is.numeric)
  cor(df[, numeric_cols], use = "pairwise.complete.obs", method = method)
}

#' Plot histogram for all numeric columns
#'
#' @param df A data frame
#' @param bins Number of bins (default: 30)
#' @examples
#' plot_histograms(mtcars)
plot_histograms <- function(df, bins = 30) {
  numeric_cols <- names(df)[sapply(df, is.numeric)]

  if (length(numeric_cols) == 0) {
    stop("No numeric columns found")
  }

  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par))

  n_cols <- length(numeric_cols)
  n_row <- ceiling(sqrt(n_cols))
  n_col <- ceiling(n_cols / n_row)

  par(mfrow = c(n_row, n_col))

  for (col in numeric_cols) {
    hist(df[[col]], breaks = bins, main = col, xlab = col, col = "steelblue")
  }
}

# ==============================================================================
# MODEL EVALUATION HELPERS
# ==============================================================================

#' Calculate Mean Absolute Error
#'
#' @param actual Actual values
#' @param predicted Predicted values
#' @return MAE value
#' @examples
#' mae(c(1, 2, 3), c(1.1, 2.2, 2.9))
mae <- function(actual, predicted) {
  mean(abs(actual - predicted))
}

#' Calculate Root Mean Squared Error
#'
#' @param actual Actual values
#' @param predicted Predicted values
#' @return RMSE value
#' @examples
#' rmse(c(1, 2, 3), c(1.1, 2.2, 2.9))
rmse <- function(actual, predicted) {
  sqrt(mean((actual - predicted)^2))
}

#' Calculate R-squared
#'
#' @param actual Actual values
#' @param predicted Predicted values
#' @return R-squared value
#' @examples
#' r_squared(c(1, 2, 3, 4, 5), c(1.1, 2.2, 2.9, 4.1, 5.2))
r_squared <- function(actual, predicted) {
  ss_res <- sum((actual - predicted)^2)
  ss_tot <- sum((actual - mean(actual))^2)
  1 - (ss_res / ss_tot)
}

#' Confusion matrix for binary classification
#'
#' @param actual Actual binary labels
#' @param predicted Predicted binary labels
#' @return List with confusion matrix and metrics
#' @examples
#' confusion_matrix(c(0, 1, 1, 0), c(0, 1, 0, 0))
confusion_matrix <- function(actual, predicted) {
  cm <- table(Actual = actual, Predicted = predicted)

  tp <- cm[2, 2]
  tn <- cm[1, 1]
  fp <- cm[1, 2]
  fn <- cm[2, 1]

  accuracy <- (tp + tn) / sum(cm)
  precision <- tp / (tp + fp)
  recall <- tp / (tp + fn)
  f1 <- 2 * (precision * recall) / (precision + recall)

  list(
    confusion_matrix = cm,
    accuracy = accuracy,
    precision = precision,
    recall = recall,
    f1_score = f1
  )
}

# ==============================================================================
# FILE I/O HELPERS
# ==============================================================================

#' Read CSV with automatic encoding detection
#'
#' @param filepath Path to CSV file
#' @param ... Additional arguments passed to read.csv
#' @return Data frame
#' @examples
#' read_csv_smart("data.csv")
read_csv_smart <- function(filepath, ...) {
  if (!file.exists(filepath)) {
    stop(paste("File not found:", filepath))
  }

  tryCatch({
    read.csv(filepath, ...)
  }, error = function(e) {
    message("Trying different encoding...")
    read.csv(filepath, fileEncoding = "UTF-8", ...)
  })
}

#' Save multiple objects to RDS files
#'
#' @param ... Named objects to save
#' @param dir Directory to save files (default: current directory)
#' @examples
#' save_rds(model = my_model, data = my_data, dir = "output")
save_rds <- function(..., dir = ".") {
  objects <- list(...)

  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }

  for (name in names(objects)) {
    filepath <- file.path(dir, paste0(name, ".rds"))
    saveRDS(objects[[name]], filepath)
    message(paste("Saved:", filepath))
  }
}

# ==============================================================================
# STRING MANIPULATION HELPERS
# ==============================================================================

#' Convert snake_case to camelCase
#'
#' @param x Character vector
#' @return Character vector in camelCase
#' @examples
#' to_camel_case("hello_world")
to_camel_case <- function(x) {
  gsub("_([a-z])", "\\U\\1", x, perl = TRUE)
}

#' Convert camelCase to snake_case
#'
#' @param x Character vector
#' @return Character vector in snake_case
#' @examples
#' to_snake_case("helloWorld")
to_snake_case <- function(x) {
  tolower(gsub("([a-z])([A-Z])", "\\1_\\2", x))
}

#' Clean column names (lowercase, replace spaces/dots with underscores)
#'
#' @param df A data frame
#' @return Data frame with cleaned column names
#' @examples
#' clean_names(data.frame("First Name" = 1, "Last.Name" = 2))
clean_names <- function(df) {
  names(df) <- tolower(gsub("[. ]+", "_", names(df)))
  names(df) <- gsub("_+", "_", names(df))
  names(df) <- gsub("^_|_$", "", names(df))
  return(df)
}

# ==============================================================================
# PERFORMANCE HELPERS
# ==============================================================================

#' Time a function execution
#'
#' @param expr Expression to time
#' @param times Number of times to run (default: 1)
#' @return List with elapsed time and result
#' @examples
#' time_it(mean(1:1000000))
time_it <- function(expr, times = 1) {
  expr <- substitute(expr)

  start_time <- Sys.time()

  for (i in seq_len(times)) {
    result <- eval(expr, parent.frame())
  }

  end_time <- Sys.time()
  elapsed <- end_time - start_time

  list(
    elapsed = elapsed,
    result = result,
    times = times
  )
}

#' Memory usage of an object
#'
#' @param x Any R object
#' @param units Units for size ("B", "KB", "MB", "GB")
#' @return Numeric value of memory size
#' @examples
#' mem_size(mtcars, "KB")
mem_size <- function(x, units = "MB") {
  format(object.size(x), units = units)
}

# ==============================================================================
# DEBUGGING HELPERS
# ==============================================================================

#' Print object type and structure
#'
#' @param x Any R object
#' @param name Optional name for the object
#' @examples
#' inspect(mtcars)
inspect <- function(x, name = deparse(substitute(x))) {
  cat("Object:", name, "\n")
  cat("Type:", typeof(x), "\n")
  cat("Class:", paste(class(x), collapse = ", "), "\n")
  cat("Dimensions:", paste(dim(x), collapse = " x "), "\n")
  cat("Length:", length(x), "\n")
  cat("\nStructure:\n")
  str(x)
  invisible(x)
}

#' Check if packages are installed and load them
#'
#' @param ... Package names as strings
#' @param install Whether to install missing packages (default: FALSE)
#' @examples
#' require_packages("dplyr", "ggplot2")
require_packages <- function(..., install = FALSE) {
  packages <- c(...)

  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      if (install) {
        message(paste("Installing package:", pkg))
        install.packages(pkg)
      } else {
        stop(paste("Package not found:", pkg, "\nSet install=TRUE to install"))
      }
    }
    library(pkg, character.only = TRUE)
    message(paste("Loaded:", pkg))
  }
}

# ==============================================================================
# STATISTICAL HELPERS
# ==============================================================================

#' Calculate confidence interval for mean
#'
#' @param x Numeric vector
#' @param confidence Confidence level (default: 0.95)
#' @return List with mean and CI
#' @examples
#' ci_mean(rnorm(100))
ci_mean <- function(x, confidence = 0.95) {
  x <- x[!is.na(x)]
  n <- length(x)
  mean_x <- mean(x)
  se <- sd(x) / sqrt(n)

  alpha <- 1 - confidence
  t_crit <- qt(1 - alpha/2, df = n - 1)

  margin <- t_crit * se

  list(
    mean = mean_x,
    lower = mean_x - margin,
    upper = mean_x + margin,
    confidence = confidence
  )
}

#' Bootstrap confidence interval
#'
#' @param x Numeric vector
#' @param statistic Function to calculate statistic (default: mean)
#' @param n_boot Number of bootstrap samples (default: 1000)
#' @param confidence Confidence level (default: 0.95)
#' @return List with statistic and CI
#' @examples
#' bootstrap_ci(rnorm(100), statistic = median)
bootstrap_ci <- function(x, statistic = mean, n_boot = 1000, confidence = 0.95) {
  x <- x[!is.na(x)]
  n <- length(x)

  boot_stats <- replicate(n_boot, {
    sample_x <- sample(x, n, replace = TRUE)
    statistic(sample_x)
  })

  alpha <- 1 - confidence
  ci <- quantile(boot_stats, c(alpha/2, 1 - alpha/2))

  list(
    statistic = statistic(x),
    lower = ci[1],
    upper = ci[2],
    confidence = confidence
  )
}

# ==============================================================================
# DATA VALIDATION HELPERS
# ==============================================================================

#' Check if values are within expected range
#'
#' @param x Numeric vector
#' @param min_val Minimum expected value
#' @param max_val Maximum expected value
#' @return Logical vector indicating which values are in range
#' @examples
#' in_range(c(1, 5, 10), 0, 8)
in_range <- function(x, min_val, max_val) {
  x >= min_val & x <= max_val
}

#' Validate data frame structure
#'
#' @param df Data frame to validate
#' @param expected_cols Expected column names
#' @param expected_types Expected column types (optional)
#' @return Logical indicating if validation passed
#' @examples
#' validate_df(mtcars, c("mpg", "cyl", "hp"))
validate_df <- function(df, expected_cols, expected_types = NULL) {
  missing_cols <- setdiff(expected_cols, names(df))

  if (length(missing_cols) > 0) {
    stop(paste("Missing columns:", paste(missing_cols, collapse = ", ")))
  }

  if (!is.null(expected_types)) {
    for (col in names(expected_types)) {
      actual_type <- class(df[[col]])[1]
      expected_type <- expected_types[[col]]

      if (actual_type != expected_type) {
        stop(paste0("Column '", col, "' has type '", actual_type,
                   "' but expected '", expected_type, "'"))
      }
    }
  }

  TRUE
}

# ==============================================================================
# UTILITY HELPERS
# ==============================================================================

#' Create a pipe-friendly assignment
#'
#' @param x Object to assign
#' @param name Name for assignment in parent environment
#' @return The object (invisibly)
#' @examples
#' mtcars %>% filter(cyl == 6) %>% assign_pipe("six_cyl")
assign_pipe <- function(x, name) {
  assign(name, x, envir = parent.frame(2))
  invisible(x)
}

#' Not in operator
#'
#' @param x Values to check
#' @param y Set to check against
#' @return Logical vector
#' @examples
#' 5 %notin% c(1, 2, 3)
`%notin%` <- function(x, y) {
  !(x %in% y)
}

#' Pipe-friendly print
#'
#' @param x Object to print
#' @param ... Additional arguments passed to print
#' @return The object (invisibly)
#' @examples
#' mtcars %>% head() %>% print_pipe()
print_pipe <- function(x, ...) {
  print(x, ...)
  invisible(x)
}

#' Get unique values sorted
#'
#' @param x Vector
#' @param decreasing Sort order (default: FALSE)
#' @return Sorted unique values
#' @examples
#' unique_sorted(c(3, 1, 2, 1, 3))
unique_sorted <- function(x, decreasing = FALSE) {
  sort(unique(x), decreasing = decreasing)
}

# ==============================================================================
# MESSAGE
# ==============================================================================

message("Data Science Helper Functions loaded successfully!")
message("Use ls() to see all available functions or ?function_name for help")
