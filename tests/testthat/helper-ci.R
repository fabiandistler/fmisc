# Fake GitHub for ci_failures(): a temporary git repo on `branch` with an
# origin on github.com, and gh::gh() replaced by a function that answers the
# three endpoints ci_failures() calls from fixture logs. No network.
#
# `jobs` is a list of lists with `name`, `os`, `step` (the failed step, or
# NULL), `log` (a file in fixtures/ci-logs/) and optionally `conclusion`
# (default "failure"). `runs = list()` means the branch has no failed run.
# `raw_logs = TRUE` serves logs as raw bytes, as gh does for octet-stream.
local_ci_run <- function(
  jobs = list(),
  runs = NULL,
  branch = "feat/x",
  raw_logs = FALSE,
  env = parent.frame()
) {
  fixtures <- normalizePath(testthat::test_path("fixtures", "ci-logs"))
  repo <- withr::local_tempdir(.local_envir = env)
  gert::git_init(repo)
  writeLines("x", file.path(repo, "README"))
  gert::git_add("README", repo = repo)
  gert::git_commit(
    "init",
    author = gert::git_signature("Test", "test@example.com"),
    repo = repo
  )
  gert::git_branch_create(branch, checkout = TRUE, repo = repo)
  gert::git_remote_add(
    "https://github.com/fabiandistler/fmisc.git",
    repo = repo
  )
  withr::local_dir(repo, .local_envir = env)

  if (is.null(runs)) {
    runs <- list(list(
      id = 101,
      head_sha = "0123456789abcdef0123456789abcdef01234567",
      html_url = "https://github.com/fabiandistler/fmisc/actions/runs/101"
    ))
  }
  api_jobs <- lapply(seq_along(jobs), function(i) {
    job <- jobs[[i]]
    list(
      id = 200 + i,
      name = job$name,
      conclusion = if (is.null(job$conclusion)) "failure" else job$conclusion,
      labels = list(job$os),
      html_url = paste0(
        "https://github.com/fabiandistler/fmisc/actions/runs/101/job/",
        200 + i
      ),
      steps = list(
        list(name = "Set up job", conclusion = "success"),
        list(
          name = if (is.null(job$step)) "Run step" else job$step,
          conclusion = if (is.null(job$step)) {
            "success"
          } else if (is.null(job$conclusion)) {
            "failure"
          } else {
            job$conclusion
          }
        )
      )
    )
  })
  calls <- new.env()
  calls$endpoints <- character()

  fake_gh <- function(endpoint, ...) {
    params <- list(...)
    calls$endpoints <- c(calls$endpoints, endpoint)
    calls$params <- c(calls$params, list(params))
    switch(
      endpoint,
      "/repos/{owner}/{repo}/actions/runs" = list(workflow_runs = runs),
      "/repos/{owner}/{repo}/actions/runs/{run_id}/jobs" = list(
        jobs = api_jobs
      ),
      "/repos/{owner}/{repo}/actions/jobs/{job_id}/logs" = {
        i <- params$job_id - 200
        path <- file.path(fixtures, jobs[[i]]$log)
        text <- paste(readLines(path, encoding = "UTF-8"), collapse = "\n")
        if (raw_logs) {
          # What gh::gh() returns for an application/octet-stream body.
          structure(charToRaw(text), class = c("gh_response", "raw"))
        } else {
          list(message = text)
        }
      },
      stop("unexpected endpoint ", endpoint)
    )
  }
  testthat::local_mocked_bindings(gh = fake_gh, .package = "gh", .env = env)
  invisible(calls)
}
