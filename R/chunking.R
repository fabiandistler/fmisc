#' Process Data with Automatic Chunking and RAM Management
#'
#' Processes data in chunks while monitoring RAM usage. Automatically writes
#' chunks to disk when RAM usage exceeds the specified threshold.
#'
#' @param data A data.frame, matrix, or vector to process
#' @param process_fn A function that takes a chunk of data and returns processed results
#' @param max_ram_mb Maximum RAM usage in MB before writing to disk (default: 1000)
#' @param chunk_size Initial chunk size (default: auto-calculated)
#' @param temp_dir Directory for temporary files (default: tempdir())
#' @param combine_fn Function to combine results from chunks (default: rbind)
#' @param verbose Logical, print progress messages (default: TRUE)
#' @return Processed results, combined from all chunks
#' @export
#' @examples
#' \dontrun{
#' # Process large dataset with automatic chunking
#' large_data <- data.frame(x = 1:1e6, y = rnorm(1e6))
#' result <- process_with_chunks(
#'   data = large_data,
#'   process_fn = function(chunk) {
#'     chunk$z <- chunk$x * chunk$y
#'     return(chunk)
#'   },
#'   max_ram_mb = 500
#' )
#' }
process_with_chunks <- function(data,
                                process_fn,
                                max_ram_mb = 1000,
                                chunk_size = NULL,
                                temp_dir = tempdir(),
                                combine_fn = rbind,
                                verbose = TRUE) {
  # Calculate optimal chunk size if not provided
  if (is.null(chunk_size)) {
    data_size_mb <- as.numeric(object.size(data)) / (1024^2)
    if (is.data.frame(data) || is.matrix(data)) {
      total_rows <- nrow(data)
    } else {
      total_rows <- length(data)
    }
    # Aim for chunks that use ~10% of max RAM
    target_chunk_ram <- max_ram_mb * 0.1
    chunk_size <- max(1, floor(total_rows * target_chunk_ram / data_size_mb))
    if (verbose) {
      message(sprintf("Auto-calculated chunk size: %d rows", chunk_size))
    }
  }

  # Create chunk iterator
  iterator <- create_chunk_iterator(data, chunk_size)

  # Create temp directory for chunks if needed
  chunk_dir <- file.path(temp_dir, paste0("chunks_", format(Sys.time(), "%Y%m%d_%H%M%S")))
  dir.create(chunk_dir, showWarnings = FALSE, recursive = TRUE)

  results_list <- list()
  disk_chunks <- character()
  initial_ram <- get_ram_usage()

  if (verbose) {
    message(sprintf("Starting processing with %d chunks", iterator$total_chunks))
    message(sprintf("Initial RAM usage: %.2f MB", initial_ram))
  }

  chunk_num <- 0
  while (iterator$has_next()) {
    chunk_num <- chunk_num + 1
    chunk_data <- iterator$get_next()

    # Check RAM before processing
    current_ram <- get_ram_usage()
    if (verbose && chunk_num %% 10 == 0) {
      message(sprintf(
        "Processing chunk %d/%d (RAM: %.2f MB)",
        chunk_num, iterator$total_chunks, current_ram
      ))
    }

    # Process the chunk
    processed_chunk <- process_fn(chunk_data)

    # Check RAM after processing
    current_ram <- get_ram_usage()

    # If RAM usage is too high, write to disk
    if (current_ram > max_ram_mb || length(results_list) > 50) {
      if (verbose) {
        message(sprintf("RAM threshold reached (%.2f MB). Writing chunks to disk...", current_ram))
      }

      # Write accumulated results to disk
      if (length(results_list) > 0) {
        chunk_file <- file.path(chunk_dir, sprintf("chunk_%04d.rds", length(disk_chunks) + 1))
        if (length(results_list) == 1) {
          combined_results <- results_list[[1]]
        } else {
          combined_results <- Reduce(combine_fn, results_list)
        }
        saveRDS(combined_results, chunk_file, compress = TRUE)
        disk_chunks <- c(disk_chunks, chunk_file)
        results_list <- list()

        # Force garbage collection
        gc()

        if (verbose) {
          message(sprintf("Wrote chunk to disk. New RAM usage: %.2f MB", get_ram_usage()))
        }
      }
    }

    # Add processed chunk to results
    results_list[[length(results_list) + 1]] <- processed_chunk
  }

  if (verbose) {
    message("Processing complete. Combining results...")
  }

  # Combine all results
  final_result <- NULL

  # First, combine any remaining in-memory results
  if (length(results_list) > 0) {
    if (length(results_list) == 1) {
      in_memory_result <- results_list[[1]]
    } else {
      in_memory_result <- Reduce(combine_fn, results_list)
    }
    final_result <- in_memory_result
  }

  # Then, read and combine disk chunks
  if (length(disk_chunks) > 0) {
    for (chunk_file in disk_chunks) {
      disk_chunk <- readRDS(chunk_file)
      if (is.null(final_result)) {
        final_result <- disk_chunk
      } else {
        final_result <- combine_fn(final_result, disk_chunk)
      }
    }

    # Clean up temporary files
    unlink(chunk_dir, recursive = TRUE)
  }

  if (verbose) {
    final_ram <- get_ram_usage()
    message(sprintf("Final RAM usage: %.2f MB", final_ram))
    message("Done!")
  }

  return(final_result)
}


#' Get Current RAM Usage
#'
#' Returns the current RAM usage in MB for the R session.
#'
#' @return Numeric value representing RAM usage in MB
#' @importFrom utils memory.size object.size
#' @export
#' @examples
#' \dontrun{
#' current_ram <- get_ram_usage()
#' print(paste("Current RAM usage:", current_ram, "MB"))
#' }
get_ram_usage <- function() {
  if (.Platform$OS.type == "windows") {
    # Windows: use memory.size()
    return(memory.size())
  } else {
    # Unix-like systems: parse /proc or use gc()
    gc_info <- gc(reset = TRUE)
    # Sum of used memory from Ncells and Vcells in MB
    used_mb <- sum(gc_info[, 2]) * 8 / (1024^2) # Convert to MB
    return(used_mb)
  }
}

#' Create Chunk Iterator
#'
#' Creates an iterator that splits data into chunks based on a maximum chunk size.
#'
#' @param data A data.frame, matrix, or vector to chunk
#' @param chunk_size Integer specifying the number of rows/elements per chunk
#' @return A list containing chunk information and an iterator function
#' @export
#' @examples
#' \dontrun{
#' data <- data.frame(x = 1:1000, y = rnorm(1000))
#' iterator <- create_chunk_iterator(data, chunk_size = 100)
#' chunk <- iterator$get_next()
#' }
create_chunk_iterator <- function(data, chunk_size) {
  if (is.data.frame(data) || is.matrix(data)) {
    total_rows <- nrow(data)
  } else if (is.vector(data) && !is.list(data)) {
    total_rows <- length(data)
  } else {
    stop("Data must be a data.frame, matrix, or vector")
  }

  num_chunks <- ceiling(total_rows / chunk_size)
  current_chunk <- 0

  list(
    total_chunks = num_chunks,
    chunk_size = chunk_size,
    current_chunk = function() current_chunk,
    has_next = function() current_chunk < num_chunks,
    get_next = function() {
      if (current_chunk >= num_chunks) {
        return(NULL)
      }
      current_chunk <<- current_chunk + 1
      start_idx <- (current_chunk - 1) * chunk_size + 1
      end_idx <- min(current_chunk * chunk_size, total_rows)

      if (is.data.frame(data) || is.matrix(data)) {
        return(data[start_idx:end_idx, , drop = FALSE])
      } else {
        return(data[start_idx:end_idx])
      }
    },
    reset = function() {
      current_chunk <<- 0
    }
  )
}


#' Chunk Processor Class
#'
#' An R6-style processor that manages chunked data processing with RAM limits.
#'
#' @param max_ram_mb Maximum RAM usage in MB
#' @param temp_dir Directory for temporary files
#' @param verbose Print progress messages
#' @return A list with methods for chunk processing
#' @export
#' @examples
#' \dontrun{
#' processor <- chunk_processor(max_ram_mb = 500)
#' processor$add_chunk(data.frame(x = 1:100))
#' result <- processor$get_results()
#' }
chunk_processor <- function(max_ram_mb = 1000, temp_dir = tempdir(), verbose = TRUE) {
  # Private state
  chunks <- list()
  disk_chunks <- character()
  chunk_dir <- file.path(temp_dir, paste0("chunks_", format(Sys.time(), "%Y%m%d_%H%M%S")))
  dir.create(chunk_dir, showWarnings = FALSE, recursive = TRUE)

  list(
    add_chunk = function(chunk_data) {
      chunks[[length(chunks) + 1]] <<- chunk_data

      # Check if we need to flush to disk
      current_ram <- get_ram_usage()
      if (current_ram > max_ram_mb || length(chunks) > 50) {
        if (verbose) {
          message(sprintf("Flushing to disk (RAM: %.2f MB)", current_ram))
        }

        chunk_file <- file.path(chunk_dir, sprintf("chunk_%04d.rds", length(disk_chunks) + 1))
        saveRDS(chunks, chunk_file, compress = TRUE)
        disk_chunks <<- c(disk_chunks, chunk_file)
        chunks <<- list()
        gc()
      }
    },
    get_results = function(combine_fn = rbind) {
      result <- NULL

      # Combine disk chunks first (they are older)
      if (length(disk_chunks) > 0) {
        for (chunk_file in disk_chunks) {
          disk_data <- readRDS(chunk_file)
          if (is.data.frame(disk_data) || is.matrix(disk_data)) {
            disk_combined <- disk_data
          } else if (!is.list(disk_data)) {
            disk_combined <- disk_data
          } else if (length(disk_data) == 1) {
            disk_combined <- disk_data[[1]]
          } else {
            disk_combined <- Reduce(combine_fn, disk_data)
          }
          if (is.null(result)) {
            result <- disk_combined
          } else {
            result <- combine_fn(result, disk_combined)
          }
        }
      }

      # Then combine in-memory chunks
      if (length(chunks) > 0) {
        if (length(chunks) == 1) {
          in_memory_result <- chunks[[1]]
        } else {
          in_memory_result <- Reduce(combine_fn, chunks)
        }
        if (is.null(result)) {
          result <- in_memory_result
        } else {
          result <- combine_fn(result, in_memory_result)
        }
      }

      return(result)
    },
    cleanup = function() {
      chunks <<- list()
      if (length(disk_chunks) > 0) {
        unlink(chunk_dir, recursive = TRUE)
        disk_chunks <<- character()
      }
    },
    get_ram_usage = function() {
      get_ram_usage()
    }
  )
}
