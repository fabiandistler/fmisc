test_that("agent_run() raises a classed error when claude is missing", {
  skip_if_no_fake_claude_support()
  empty_dir <- tempfile("no-claude-")
  dir.create(empty_dir)
  with_env_var("PATH", empty_dir, {
    expect_error(
      agent_run("Hi", schema_answer, workdir = tempdir()),
      class = "fmisc_agent_cli_missing"
    )
  })
})

test_that("agent_run() returns the structured output and run metadata", {
  skip_if_no_fake_claude_support()
  local_fake_claude("success")

  res <- agent_run("Summarise the package", schema_answer, workdir = tempdir())

  expect_s3_class(res, "fmisc_agent_result")
  expect_identical(res$value$answer, "fmisc")
  # Arrays of objects simplify to a data frame, as jsonlite::fromJSON() does.
  expect_identical(
    res$value$files,
    data.frame(path = c("DESCRIPTION", "NAMESPACE"), lines = c(42L, 30L))
  )
  expect_identical(res$cost_usd, 0.0213)
  expect_identical(res$num_turns, 2L)
  expect_identical(res$model, "claude-sonnet-5-5")
  expect_identical(res$session_id, "4f1c2a9e-0000-4000-8000-000000000000")
  expect_length(res$permission_denials, 0)
  expect_identical(res$raw$terminal_reason, "completed")
})

test_that("agent_run() sends the prompt on stdin and read-only flags in argv", {
  skip_if_no_fake_claude_support()
  local_fake_claude("echo")
  workdir <- tempfile("agent-wd-")
  dir.create(workdir)
  prompt <- "List the R files.\nSECRET-PROMPT-MARKER"

  seen <- agent_run(prompt, schema_answer, workdir = workdir)$value

  # The exact argv from the design note (docs/adr/0001-agent-run-claude-cli.md).
  expect_identical(
    seen$argv,
    c(
      "-p",
      "--output-format",
      "json",
      "--json-schema",
      schema_answer,
      "--safe-mode",
      "--restricted",
      "--strict-mcp-config",
      "--tools",
      "Read,Glob,Grep",
      "--disallowedTools",
      "mcp__*",
      "Read(.env*)",
      "Read(.Renviron*)",
      "Read(.netrc)",
      "Read(.git-credentials)",
      "Read(*.pem)",
      "Read(*.key)",
      "Read(id_rsa*)",
      "Read(id_dsa*)",
      "Read(id_ecdsa*)",
      "Read(id_ed25519*)",
      "Read(.ssh/**)",
      "--permission-mode",
      "dontAsk",
      "--permission-prompts",
      "none",
      "--disable-slash-commands",
      "--no-session-persistence",
      "--model",
      "sonnet",
      "--max-turns",
      "20",
      "--max-budget-usd",
      "1"
    )
  )
  forbidden <- c(
    "bypassPermissions",
    "--dangerously-skip-permissions",
    "acceptEdits",
    "--allowedTools",
    "Bash",
    "Edit",
    "Write",
    "WebFetch",
    "--bare"
  )
  expect_false(any(grepl(paste(forbidden, collapse = "|"), seen$argv)))
  expect_false(any(grepl("SECRET-PROMPT-MARKER", seen$argv, fixed = TRUE)))
  expect_identical(seen$stdin, prompt)
  expect_identical(seen$wd, normalizePath(workdir))
})

test_that("agent_run() strips API and provider credentials from the child", {
  skip_if_no_fake_claude_support()
  local_fake_claude("echo")
  dummy <- c(
    ANTHROPIC_API_KEY = "test-dummy",
    ANTHROPIC_AUTH_TOKEN = "test-dummy",
    ANTHROPIC_BASE_URL = "https://gateway.invalid",
    ANTHROPIC_CUSTOM_HEADERS = "X-Test: 1",
    CLAUDE_CODE_USE_BEDROCK = "1",
    CLAUDE_CODE_USE_VERTEX = "1",
    CLAUDE_CODE_USE_FOUNDRY = "1",
    CLAUDE_CODE_USE_MANTLE = "1",
    CLAUDE_CODE_USE_ANTHROPIC_AWS = "1",
    # The subscription token from `claude setup-token` must pass through.
    CLAUDE_CODE_OAUTH_TOKEN = "test-dummy"
  )
  old <- Sys.getenv(names(dummy), unset = NA)
  names(old) <- names(dummy)
  on.exit(restore_env(old), add = TRUE)
  restore_env(dummy)

  seen <- agent_run("Hi", schema_answer, workdir = tempdir())$value

  expect_identical(unlist(seen$env_set), "CLAUDE_CODE_OAUTH_TOKEN")
})

test_that("agent_run() reports a CLI error result as fmisc_agent_failed", {
  skip_if_no_fake_claude_support()
  local_fake_claude("max_turns")

  err <- expect_error(
    agent_run("Loop forever", schema_answer, workdir = tempdir()),
    class = "fmisc_agent_failed"
  )
  expect_s3_class(err, "fmisc_agent_error")
  expect_identical(err$exit_status, 1L)
  expect_identical(err$subtype, "error_max_turns")
  expect_match(conditionMessage(err), "status 1")
  expect_match(conditionMessage(err), "error_max_turns")
})

test_that("agent_run() reports an auth failure with stderr attached", {
  skip_if_no_fake_claude_support()
  local_fake_claude("auth_error")

  err <- expect_error(
    agent_run("Hi", schema_answer, workdir = tempdir()),
    class = "fmisc_agent_failed"
  )
  expect_identical(err$exit_status, 1L)
  expect_match(err$stderr, "authentication failed")
  # The model text stays out of the message.
  expect_no_match(conditionMessage(err), "Invalid API key")
})

test_that("agent_run() reports non-JSON stdout as fmisc_agent_failed", {
  skip_if_no_fake_claude_support()
  local_fake_claude("garbage")

  err <- expect_error(
    agent_run("Hi", schema_answer, workdir = tempdir()),
    class = "fmisc_agent_failed"
  )
  expect_identical(err$exit_status, 0L)
  expect_identical(err$subtype, NA_character_)
  expect_match(conditionMessage(err), "non-JSON output")
})

test_that("agent_run() reports a refusal as fmisc_agent_no_output", {
  skip_if_no_fake_claude_support()
  local_fake_claude("refusal")

  err <- expect_error(
    agent_run("Do something bad", schema_answer, workdir = tempdir()),
    class = "fmisc_agent_no_output"
  )
  expect_s3_class(err, "fmisc_agent_error")
  expect_identical(err$subtype, "success")
  expect_length(err$permission_denials, 0)
  expect_no_match(conditionMessage(err), "can't help")
})

test_that("agent_run() rejects invalid input before starting claude", {
  skip_if_no_fake_claude_support()
  # The hang scenario would block for 30 s, so a spawn would show as a timeout.
  local_fake_claude("hang")
  missing_dir <- tempfile("missing-")

  expect_error(
    agent_run("Hi", '{"type": "object",', workdir = tempdir(), timeout = 5),
    class = "fmisc_agent_invalid_argument"
  )
  expect_error(
    agent_run(c("a", "b"), schema_answer, workdir = tempdir(), timeout = 5),
    class = "fmisc_agent_invalid_argument"
  )
  expect_error(
    agent_run("Hi", schema_answer, workdir = missing_dir, timeout = 5),
    class = "fmisc_agent_invalid_argument"
  )
  expect_error(
    agent_run("Hi", schema_answer, workdir = tempdir(), timeout = -1),
    class = "fmisc_agent_invalid_argument"
  )
})

test_that("agent_run() stops at the wall-clock timeout and kills the tree", {
  skip_if_no_fake_claude_support()
  skip_if_not(dir.exists("/proc"), "needs /proc to inspect processes")
  local_fake_claude("hang")
  pidfile <- tempfile("fake-claude-pids-")

  started <- Sys.time()
  with_env_var("FAKE_CLAUDE_PIDFILE", pidfile, {
    err <- expect_error(
      agent_run("Hang", schema_answer, workdir = tempdir(), timeout = 3),
      class = "fmisc_agent_timeout"
    )
  })
  expect_s3_class(err, "fmisc_agent_error")
  expect_identical(err$timeout, 3)
  expect_lt(as.numeric(difftime(Sys.time(), started, units = "secs")), 15)

  pids <- as.integer(readLines(pidfile))
  # The fake claude itself and the `sleep` grandchild it started.
  expect_length(pids, 2)
  alive <- function(pid) {
    stat <- file.path("/proc", pid, "stat")
    file.exists(stat) &&
      !grepl("^\\d+ \\(.*\\) Z", readLines(stat, warn = FALSE))
  }
  deadline <- Sys.time() + 5
  while (any(vapply(pids, alive, logical(1))) && Sys.time() < deadline) {
    Sys.sleep(0.1)
  }
  expect_false(any(vapply(pids, alive, logical(1))))
})

test_that("print() shows model, turns, cost and the value's structure", {
  skip_if_no_fake_claude_support()
  local_fake_claude("success")
  res <- agent_run("Summarise the package", schema_answer, workdir = tempdir())

  out <- capture.output(returned <- print(res))
  expect_identical(returned, res)
  expect_identical(
    out[1],
    "<fmisc_agent_result> claude-sonnet-5-5, 2 turns, est. cost USD 0.0213"
  )
  expect_identical(out[-1], capture.output(utils::str(res$value)))
})

test_that("agent_run() works against the real claude CLI (opt-in smoke test)", {
  # Spends the owner's Claude subscription quota, so it never runs by default.
  skip_on_cran()
  skip_on_ci()
  skip_if_not(
    identical(Sys.getenv("FMISC_REAL_CLAUDE"), "true"),
    "set FMISC_REAL_CLAUDE=true to call the real claude CLI"
  )
  skip_if(!nzchar(Sys.which("claude")), "claude CLI not on PATH")
  workdir <- tempfile("agent-smoke-")
  dir.create(workdir)
  writeLines("The secret word is pumpernickel.", file.path(workdir, "note.txt"))

  res <- agent_run(
    "Read note.txt and answer with the secret word only.",
    schema_answer,
    workdir = workdir,
    timeout = 180
  )

  expect_s3_class(res, "fmisc_agent_result")
  expect_type(res$value$answer, "character")
  expect_length(res$permission_denials, 0)
})
