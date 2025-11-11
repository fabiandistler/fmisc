# Tests for fmisc Package

This directory contains comprehensive tests for the fmisc package using the testthat framework.

## Running Tests

### Run all tests

```r
# From R console
library(testthat)
library(fmisc)
test_check("fmisc")
```

Or using the command line:

```bash
R CMD check fmisc_*.tar.gz
```

Or using the Makefile:

```bash
make check
```

### Run specific test file

```r
library(testthat)
library(fmisc)
test_file("tests/testthat/test-chunk-iterator.R")
```

## Test Structure

The test suite is organized into the following files:

### test-chunk-iterator.R
Tests for the `create_chunk_iterator()` function:
- Iterator creation with data.frames, vectors, and matrices
- Correct iteration through chunks
- Handling uneven chunk sizes
- Reset functionality
- Input validation
- Edge cases (single chunk, preserving column names)

### test-process-with-chunks.R
Tests for the `process_with_chunks()` function:
- Basic data processing with automatic chunking
- Custom combine functions
- Auto-calculation of chunk sizes
- Vector and matrix processing
- Transformation and aggregation
- Order preservation
- Verbose mode
- Empty results handling

### test-chunk-processor.R
Tests for the `chunk_processor()` object:
- Processor initialization
- Adding chunks
- Combining results
- Cleanup functionality
- RAM usage monitoring
- Handling many small chunks
- Column type preservation
- Matrix processing
- Verbose mode

### test-ram-monitoring.R
Tests for RAM monitoring functions:
- `get_ram_usage()` - R implementation
- `get_ram_usage_cpp()` - C++ implementation
- `get_system_info()` - System memory information
- `ram_threshold_exceeded()` - Threshold checking
- Memory allocation detection
- Multiple calls handling

### test-rcpp-functions.R
Tests for high-performance C++ functions:
- `split_vector_chunks()` - Vector splitting
- `split_matrix_chunks()` - Matrix splitting
- `calculate_optimal_chunk_size()` - Chunk size calculation
- Uneven splits
- Single chunks
- Value preservation
- Edge cases (negative numbers, different shapes)
- Large data handling

### test-integration.R
End-to-end integration tests:
- Full workflow with large datasets
- Multiple operations with chunk processor
- Manual iteration with processing
- Aggregation across chunks
- Combining C++ and R functions
- Matrix processing workflows
- Optimal chunk size usage
- Error handling
- Data integrity preservation
- RAM threshold management

## Test Coverage

The test suite covers:
- ✅ Core chunking functionality
- ✅ Iterator patterns
- ✅ Processor object methods
- ✅ RAM monitoring (R and C++)
- ✅ Rcpp high-performance functions
- ✅ Integration workflows
- ✅ Edge cases and error handling
- ✅ Data type preservation
- ✅ Memory management

## Requirements

- R >= 3.5.0
- testthat >= 3.0.0
- Rcpp >= 1.0.0

## Expected Results

All tests should pass when run in a properly configured R environment with:
- Sufficient RAM (at least 500 MB recommended)
- C++ compiler for Rcpp compilation
- All package dependencies installed

## Notes

Some tests use `skip_if_not_installed("Rcpp")` to gracefully skip Rcpp-dependent tests if the package is not available.

Tests involving RAM monitoring may have slight variations depending on the system and current memory usage.
