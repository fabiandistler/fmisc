# Chunk Processor Class

An R6-style processor that manages chunked data processing with RAM
limits.

## Usage

``` r
chunk_processor(max_ram_mb = 1000, temp_dir = tempdir(), verbose = TRUE)
```

## Arguments

- max_ram_mb:

  Maximum RAM usage in MB

- temp_dir:

  Directory for temporary files

- verbose:

  Print progress messages

## Value

A list with methods for chunk processing

## Examples

``` r
if (FALSE) { # \dontrun{
processor <- chunk_processor(max_ram_mb = 500)
processor$add_chunk(data.frame(x = 1:100))
result <- processor$get_results()
} # }
```
