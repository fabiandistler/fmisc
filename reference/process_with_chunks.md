# Process Data with Automatic Chunking and RAM Management

Processes data in chunks while monitoring RAM usage. Automatically
writes chunks to disk when RAM usage exceeds the specified threshold.

## Usage

``` r
process_with_chunks(
  data,
  process_fn,
  max_ram_mb = 1000,
  chunk_size = NULL,
  temp_dir = tempdir(),
  combine_fn = rbind,
  verbose = TRUE
)
```

## Arguments

- data:

  A data.frame, matrix, or vector to process

- process_fn:

  A function that takes a chunk of data and returns processed results

- max_ram_mb:

  Maximum RAM usage in MB before writing to disk (default: 1000)

- chunk_size:

  Initial chunk size (default: auto-calculated)

- temp_dir:

  Directory for temporary files (default: tempdir())

- combine_fn:

  Function to combine results from chunks (default: rbind)

- verbose:

  Logical, print progress messages (default: TRUE)

## Value

Processed results, combined from all chunks

## Examples

``` r
if (FALSE) { # \dontrun{
# Process large dataset with automatic chunking
large_data <- data.frame(x = 1:1e6, y = rnorm(1e6))
result <- process_with_chunks(
  data = large_data,
  process_fn = function(chunk) {
    chunk$z <- chunk$x * chunk$y
    return(chunk)
  },
  max_ram_mb = 500
)
} # }
```
