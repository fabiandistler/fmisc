# Body of the fake `claude`; local_fake_claude() prepends the shebang.
args <- commandArgs(trailingOnly = TRUE)
scenario <- Sys.getenv("FAKE_CLAUDE_SCENARIO", "success")
stdin_text <- paste(readLines(file("stdin"), warn = FALSE), collapse = "\n")

result <- function(...) {
  base <- list(
    type = "result",
    subtype = "success",
    is_error = FALSE,
    duration_ms = 4210,
    num_turns = 2,
    result = "",
    session_id = "4f1c2a9e-0000-4000-8000-000000000000",
    total_cost_usd = 0.0213,
    permission_denials = list(),
    terminal_reason = "completed",
    modelUsage = list(
      `claude-sonnet-5-5` = list(inputTokens = 12, outputTokens = 40)
    )
  )
  utils::modifyList(base, list(...))
}
emit <- function(x) {
  cat(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null"), "\n", sep = "")
}

switch(
  scenario,
  success = emit(result(
    structured_output = list(
      answer = "fmisc",
      files = list(
        list(path = "DESCRIPTION", lines = 42),
        list(path = "NAMESPACE", lines = 30)
      )
    )
  )),
  echo = emit(result(
    structured_output = list(
      argv = args,
      stdin = stdin_text,
      wd = normalizePath(getwd()),
      # Names only, never values: which auth/provider variables reached us.
      env_set = I(intersect(
        c(
          "ANTHROPIC_API_KEY",
          "ANTHROPIC_AUTH_TOKEN",
          "ANTHROPIC_BASE_URL",
          "ANTHROPIC_CUSTOM_HEADERS",
          "CLAUDE_CODE_USE_BEDROCK",
          "CLAUDE_CODE_USE_VERTEX",
          "CLAUDE_CODE_USE_FOUNDRY",
          "CLAUDE_CODE_USE_MANTLE",
          "CLAUDE_CODE_USE_ANTHROPIC_AWS",
          "CLAUDE_CODE_OAUTH_TOKEN"
        ),
        names(Sys.getenv())
      ))
    )
  )),
  refusal = emit(result(result = "I can't help with that.")),
  max_turns = {
    emit(result(subtype = "error_max_turns", is_error = TRUE))
    quit(status = 1)
  },
  auth_error = {
    emit(result(
      subtype = "success",
      is_error = TRUE,
      result = "Invalid API key - Please run /login",
      total_cost_usd = 0,
      num_turns = 0
    ))
    cat("authentication failed\n", file = stderr())
    quit(status = 1)
  },
  garbage = cat("Error: something went sideways\n<html>not json</html>\n"),
  hang = {
    pidfile <- Sys.getenv("FAKE_CLAUDE_PIDFILE")
    system(paste("sleep 30 & echo $! >", shQuote(pidfile)))
    cat(Sys.getpid(), "\n", file = pidfile, append = TRUE)
    Sys.sleep(30)
  },
  stop("unknown FAKE_CLAUDE_SCENARIO")
)
