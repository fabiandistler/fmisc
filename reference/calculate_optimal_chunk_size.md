# Calculate Optimal Chunk Size

Calculates optimal chunk size based on data size and RAM limits.

## Usage

``` r
calculate_optimal_chunk_size(
  data_size_mb,
  total_rows,
  max_ram_mb,
  target_fraction = 0.1
)
```

## Arguments

- data_size_mb:

  Size of data in MB

- total_rows:

  Total number of rows

- max_ram_mb:

  Maximum RAM in MB

- target_fraction:

  Fraction of max RAM to use per chunk (default 0.1)

## Value

Optimal chunk size (number of rows)
