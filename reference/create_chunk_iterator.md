# Create Chunk Iterator

Creates an iterator that splits data into chunks based on a maximum
chunk size. Uses fast C++ implementations for numeric matrices and
vectors, standard R subsetting for data frames to preserve row indices
and ordering.

## Usage

``` r
create_chunk_iterator(data, chunk_size)
```

## Arguments

- data:

  A data.frame, data.table, matrix, or vector to chunk

- chunk_size:

  Integer specifying the number of rows/elements per chunk

## Value

A list containing chunk information and an iterator function

## Examples

``` r
if (FALSE) { # \dontrun{
data <- data.frame(x = 1:1000, y = rnorm(1000))
iterator <- create_chunk_iterator(data, chunk_size = 100)
chunk <- iterator$get_next()
} # }
```
