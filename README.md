# Data Science Helper Functions for R

A comprehensive collection of useful helper functions for data science and software development tasks in R.

## Installation

Simply source the helper file in your R session:

```r
source("ds_helpers.R")
```

## Function Categories

### Data Exploration
- `quick_summary(df, round_digits = 2)` - Quick summary statistics for numeric columns
- `missing_summary(df, pct = TRUE)` - Count missing values by column
- `find_outliers(x, multiplier = 1.5)` - Identify outliers using IQR method

### Data Manipulation
- `normalize(x)` - Normalize to 0-1 range
- `standardize(x)` - Standardize using z-scores
- `to_factors(df, cols)` - Convert multiple columns to factors
- `split_data(df, train_pct = 0.8, seed = NULL)` - Split data into train/test sets

### Plotting
- `cor_matrix(df, method = "pearson")` - Create correlation matrix
- `plot_histograms(df, bins = 30)` - Plot histograms for all numeric columns

### Model Evaluation
- `mae(actual, predicted)` - Mean Absolute Error
- `rmse(actual, predicted)` - Root Mean Squared Error
- `r_squared(actual, predicted)` - R-squared metric
- `confusion_matrix(actual, predicted)` - Confusion matrix with metrics

### File I/O
- `read_csv_smart(filepath, ...)` - Read CSV with automatic encoding detection
- `save_rds(..., dir = ".")` - Save multiple objects to RDS files

### String Manipulation
- `to_camel_case(x)` - Convert snake_case to camelCase
- `to_snake_case(x)` - Convert camelCase to snake_case
- `clean_names(df)` - Clean data frame column names

### Performance
- `time_it(expr, times = 1)` - Time function execution
- `mem_size(x, units = "MB")` - Get memory usage of an object

### Debugging
- `inspect(x, name)` - Print object type and structure
- `require_packages(..., install = FALSE)` - Check and load packages

### Statistical
- `ci_mean(x, confidence = 0.95)` - Confidence interval for mean
- `bootstrap_ci(x, statistic = mean, n_boot = 1000, confidence = 0.95)` - Bootstrap CI

### Data Validation
- `in_range(x, min_val, max_val)` - Check if values are within range
- `validate_df(df, expected_cols, expected_types = NULL)` - Validate data frame structure

### Utilities
- `assign_pipe(x, name)` - Pipe-friendly assignment
- `%notin%` - Not in operator
- `print_pipe(x, ...)` - Pipe-friendly print
- `unique_sorted(x, decreasing = FALSE)` - Get sorted unique values

## Examples

```r
# Data exploration
quick_summary(mtcars)
missing_summary(airquality)

# Data manipulation
normalized_data <- normalize(mtcars)
data_split <- split_data(mtcars, train_pct = 0.7, seed = 123)

# Model evaluation
predictions <- c(1.1, 2.2, 2.9, 4.1, 5.2)
actual <- c(1, 2, 3, 4, 5)
rmse(actual, predictions)
r_squared(actual, predictions)

# String manipulation
clean_names(data.frame("First Name" = 1, "Last.Name" = 2))

# Statistical helpers
ci_mean(rnorm(100))
bootstrap_ci(rnorm(100), statistic = median)

# Utilities
5 %notin% c(1, 2, 3)  # TRUE
```

## Contributing

Feel free to add more helper functions or improve existing ones!
