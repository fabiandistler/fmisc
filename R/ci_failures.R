#' Findings from the latest failed CI run of the current branch
#'
#' Fetches the most recent failed GitHub Actions run of the branch checked
#' out in the working directory, downloads the log of each failed job and
#' turns it into one row per finding.
#'
#' @details
#' The repository comes from the `origin` remote of the working directory and
#' the branch from its `HEAD`. Requests go through [gh::gh()], so the token
#' is read from `GITHUB_PAT`, `GITHUB_TOKEN` or the git credential store
#' (see [gh::gh_token()]); it is never an argument.
#'
#' A job log can produce these kinds of finding:
#' * `check_error`, `check_warning`, `check_note`: an `R CMD check` entry.
#' * `test_failure`: a testthat failure or error, with the test file and line.
#' * `lint`: a lintr annotation.
#' * `format`: a file `air format --check` would reformat.
#' * `unparsed`: a failed job none of the above explains. `message` holds the
#'   raw log of the failing step, so nothing is dropped silently.
#'
#' @return A data frame with one row per finding and the columns
#'   * `job`: job name, such as `"ubuntu-latest (release)"`.
#'   * `os`: runner label, such as `"ubuntu-latest"`.
#'   * `step`: name of the failed step (`NA` when GitHub names none).
#'   * `kind`: one of the kinds above.
#'   * `file`: path relative to the package root, or `NA`.
#'   * `line`: integer line in `file`, or `NA`.
#'   * `message`: full text of the finding.
#'   * `sha`: commit the run checked; `file` and `line` refer to it.
#'   * `url`: link to the job on GitHub.
#'
#'   Zero rows when the branch has no failed run. Printing shows one line per
#'   finding; the full text stays in `message`.
#'
#' @examples
#' \dontrun{
#' findings <- ci_failures()
#' findings[findings$kind == "test_failure", c("file", "line", "message")]
#' }
#' @export
ci_failures <- function() {
  remote <- gh::gh_tree_remote()
  branch <- gert::git_branch()
  # gert reports a detached HEAD as "HEAD" and an unborn one as NULL.
  if (is.null(branch) || identical(branch, "HEAD")) {
    cli::cli_abort("{.code HEAD} is not on a branch.")
  }
  runs <- gh::gh(
    "/repos/{owner}/{repo}/actions/runs",
    owner = remote$username,
    repo = remote$repo,
    branch = branch,
    status = "failure",
    per_page = 1
  )$workflow_runs
  if (length(runs) == 0) {
    return(new_ci_failures(empty_findings()))
  }
  run <- runs[[1]]
  jobs <- gh::gh(
    "/repos/{owner}/{repo}/actions/runs/{run_id}/jobs",
    owner = remote$username,
    repo = remote$repo,
    run_id = run$id,
    per_page = 100
  )$jobs
  failed <- Filter(function(job) identical(job$conclusion, "failure"), jobs)
  findings <- lapply(failed, function(job) {
    log <- gh::gh(
      "/repos/{owner}/{repo}/actions/jobs/{job_id}/logs",
      owner = remote$username,
      repo = remote$repo,
      job_id = job$id
    )$message
    job_findings(job, run, log)
  })
  new_ci_failures(do.call(rbind, c(list(empty_findings()), findings)))
}

new_ci_failures <- function(findings) {
  rownames(findings) <- NULL
  class(findings) <- c("fmisc_ci_failures", "data.frame")
  findings
}

empty_findings <- function() {
  data.frame(
    job = character(),
    os = character(),
    step = character(),
    kind = character(),
    file = character(),
    line = integer(),
    message = character(),
    sha = character(),
    url = character(),
    stringsAsFactors = FALSE
  )
}

# One job's log -> findings with the job's context columns filled in.
job_findings <- function(job, run, log) {
  lines <- clean_log_lines(log)
  found <- rbind(
    parse_check(lines),
    parse_tests(lines),
    parse_lint(lines),
    parse_format(lines)
  )
  # NOTEs do not fail check-r-package (error-on: warning), so they cannot
  # be why the job failed.
  if (all(found$kind == "check_note")) {
    found <- rbind(
      found,
      found_rows(
        "unparsed",
        NA_character_,
        NA_integer_,
        failing_step_log(lines)
      )
    )
  }
  failed_step <- Filter(
    function(step) identical(step$conclusion, "failure"),
    job$steps
  )
  data.frame(
    job = job$name,
    os = if (length(job$labels) > 0) job$labels[[1]] else NA_character_,
    step = if (length(failed_step) > 0) {
      failed_step[[1]]$name
    } else {
      NA_character_
    },
    found,
    sha = run$head_sha,
    url = job$html_url,
    stringsAsFactors = FALSE
  )
}

# The log of the step that failed: from its "##[group]Run" header to the
# first "##[error]" line. The whole log when there is no "##[error]" line.
failing_step_log <- function(lines) {
  error <- grep("^##\\[error\\]", lines)
  if (length(error) == 0) {
    return(paste(lines, collapse = "\n"))
  }
  starts <- grep("^##\\[group\\]Run ", lines[seq_len(error[1])])
  start <- if (length(starts) > 0) starts[length(starts)] else 1
  paste(lines[start:error[1]], collapse = "\n")
}

# Split a raw Actions log into lines without timestamps or ANSI styling.
clean_log_lines <- function(log) {
  lines <- strsplit(log, "\r?\n")[[1]]
  lines <- sub("^\ufeff", "", lines)
  lines <- sub("^\\d{4}-\\d{2}-\\d{2}T[0-9:.]+Z ?", "", lines, perl = TRUE)
  gsub("\033\\[[0-9;]*m", "", lines)
}

found_rows <- function(
  kind = character(),
  file = character(),
  line = integer(),
  message = character()
) {
  data.frame(
    kind = kind,
    file = file,
    line = as.integer(line),
    message = message,
    stringsAsFactors = FALSE
  )
}

# lintr prints GitHub annotations when it runs on Actions, such as
# `##[warning]file=R/x.R,line=12,col=3,[linter_name] message`.
parse_lint <- function(lines) {
  pattern <- paste0(
    "^##\\[(?:warning|error|notice)\\]",
    "file=([^,]+),line=(\\d+),col=\\d+,(.*)$"
  )
  hits <- regmatches(lines, regexec(pattern, lines, perl = TRUE))
  hits <- hits[lengths(hits) > 0]
  found_rows(
    kind = rep("lint", length(hits)),
    file = vapply(hits, `[`, "", 2),
    line = vapply(hits, `[`, "", 3),
    message = vapply(hits, `[`, "", 4)
  )
}

# `air format . --check` prints one line per file it would change.
parse_format <- function(lines) {
  hits <- grep("^Would reformat: ", lines, value = TRUE)
  found_rows(
    kind = rep("format", length(hits)),
    file = sub("^Would reformat: ", "", hits),
    line = rep(NA_integer_, length(hits)),
    message = hits
  )
}

# R CMD check output, between its "R CMD check" rule and "Status:". Each
# "* checking ..." line opens an entry; its status ends that line or stands
# on a later line of its own ("checking tests ...", then " [7s/14s] ERROR").
# A status line after an entry that already has one opens an entry without
# a "* " line, which R CMD check prints for some WARNINGs.
parse_check <- function(lines) {
  start <- grep("^(\u2500\u2500|--) R CMD check ", lines)
  if (length(start) == 0) {
    return(found_rows())
  }
  lines <- lines[-seq_len(start[1])]
  end <- grep("^Status: ", lines)
  if (length(end) > 0) {
    lines <- lines[seq_len(end[1] - 1)]
  }
  inline_status <- " \\.\\.\\. (?:\\[[^]]*\\] )?(OK|NOTE|WARNING|ERROR)$"
  own_status <- "^\\s*(?:\\[[^]]*\\]\\s*)?(OK|NOTE|WARNING|ERROR)$"
  status <- character()
  text <- list()
  for (line in lines) {
    if (startsWith(line, "* ")) {
      status <- c(status, regmatches_first(line, inline_status))
      text <- c(text, list(sub("^\\* ", "", line)))
    } else if (grepl(own_status, line, perl = TRUE)) {
      line_status <- regmatches_first(line, own_status)
      n <- length(status)
      if (n > 0 && is.na(status[n])) {
        status[n] <- line_status
        text[[n]] <- c(text[[n]], line)
      } else {
        status <- c(status, line_status)
        text <- c(text, list(trimws(line)))
      }
    } else if (length(text) > 0) {
      text[[length(text)]] <- c(text[[length(text)]], line)
    }
  }
  keep <- status %in% c("NOTE", "WARNING", "ERROR")
  message <- vapply(
    text[keep],
    function(entry) {
      trimws(paste(entry, collapse = "\n"), which = "right")
    },
    ""
  )
  location <- regmatches(
    message,
    regexec("00_pkg_src/[^/]+/([^:()[:space:]]+):(\\d+)", message)
  )
  found_rows(
    kind = paste0("check_", tolower(status[keep])),
    file = vapply(location, `[`, "", 2),
    line = vapply(location, `[`, "", 3),
    message = message
  )
}

# First capture group of `pattern` in `x`, or NA.
regmatches_first <- function(x, pattern) {
  hit <- regmatches(x, regexec(pattern, x, perl = TRUE))[[1]]
  if (length(hit) > 1) hit[2] else NA_character_
}

# testthat issues as printed by its check reporter, both in the "Last 13
# lines of output" of R CMD check (indented) and in the full testthat.Rout
# that check-r-package shows afterwards:
# ── Failure ('test-x.R:12:3'): test name ─────
# The same issue can appear in both copies; the longest text is kept.
parse_tests <- function(lines) {
  header <- paste0(
    "^(\\s*)(?:\u2500\u2500|--) (Failure|Error) \\(['\u2018](.+):(\\d+):\\d+",
    "['\u2019]\\): (.*?) [\u2500-]+$"
  )
  stop_at <- paste0(
    "^\\s*(?:\\[ FAIL \\d|(?:\u2500\u2500|--) \\S+ \\(|(?:\u2550\u2550|==) )",
    "|^\\* |^##\\["
  )
  starts <- grep(header, lines, perl = TRUE)
  issues <- lapply(starts, function(start) {
    hit <- regmatches(lines[start], regexec(header, lines[start], perl = TRUE))
    hit <- hit[[1]]
    body <- character()
    for (line in lines[-seq_len(start)]) {
      if (grepl(stop_at, line, perl = TRUE)) {
        break
      }
      body <- c(body, line)
    }
    indent <- hit[2]
    body <- ifelse(
      startsWith(body, indent),
      substring(body, nchar(indent) + 1),
      body
    )
    message <- paste(c(paste0(hit[3], ": ", hit[6]), body), collapse = "\n")
    found_rows(
      kind = "test_failure",
      file = paste0("tests/testthat/", hit[4]),
      line = hit[5],
      message = trimws(message, which = "right")
    )
  })
  issues <- do.call(rbind, c(list(found_rows()), issues))
  # Keep the longest copy of each issue, in order of first appearance.
  key <- paste(issues$file, issues$line, sub("\n.*", "", issues$message))
  longest <- order(match(key, key), -nchar(issues$message))
  issues <- issues[longest, ]
  issues[!duplicated(key[longest]), ]
}

#' @export
print.fmisc_ci_failures <- function(x, ...) {
  if (nrow(x) == 0) {
    cat("No findings: the branch has no failed CI run.\n")
    return(invisible(x))
  }
  cat(sprintf(
    "%d findings from commit %s\n",
    nrow(x),
    paste(unique(substr(x$sha, 1, 7)), collapse = ", ")
  ))
  shown <- utils::head(x, 20)
  location <- ifelse(
    is.na(shown$file),
    "-",
    ifelse(is.na(shown$line), shown$file, paste0(shown$file, ":", shown$line))
  )
  first_line <- sub("\n.*", "", shown$message)
  first_line <- ifelse(
    nchar(first_line) > 60,
    paste0(substr(first_line, 1, 57), "..."),
    first_line
  )
  cat(
    sprintf(
      "%-13s %-24s %s [%s]",
      shown$kind,
      location,
      first_line,
      shown$job
    ),
    sep = "\n"
  )
  if (nrow(x) > nrow(shown)) {
    cat(sprintf("... and %d more.\n", nrow(x) - nrow(shown)))
  }
  cat("Full text of each finding is in `$message`.\n")
  invisible(x)
}
