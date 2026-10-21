#' Run a read-only Claude Code agent and get structured output back
#'
#' Runs the Claude Code CLI (`claude -p`) once in `workdir` and returns its
#' answer as an R object that matches a JSON Schema. The agent can read the
#' files under `workdir` but cannot change them, run commands or reach the
#' web.
#'
#' @section Authentication and billing:
#' `agent_run()` uses whatever login the `claude` CLI already has, meant to
#' be the owner's Claude subscription (OAuth). It never reads, stores or
#' passes tokens. These variables are **removed** from the child process's
#' environment, so nothing set in the R session can switch the run to API
#' billing, a gateway or a cloud provider: `ANTHROPIC_API_KEY`,
#' `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_CUSTOM_HEADERS`,
#' `CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_VERTEX`,
#' `CLAUDE_CODE_USE_FOUNDRY`, `CLAUDE_CODE_USE_MANTLE` and
#' `CLAUDE_CODE_USE_ANTHROPIC_AWS`. `CLAUDE_CODE_OAUTH_TOKEN` (a subscription
#' token from `claude setup-token`) passes through. `cost_usd` is the CLI's
#' client-side estimate, not a bill. Use it for occasional, attended calls;
#' it is not made for batch runs over many rows.
#'
#' @section Isolation:
#' The CLI runs with `--safe-mode --restricted --strict-mcp-config`, so
#' CLAUDE.md, skills, plugins, hooks, MCP servers and settings files are not
#' loaded. Only the `Read`, `Glob` and `Grep` tools are available, and any
#' call that would need a permission prompt is denied (`dontAsk`,
#' `--permission-prompts none`). The model (`sonnet`), the turn cap (20) and
#' the budget cap (USD 1) are fixed. The prompt goes on stdin, never on the
#' command line, and no session transcript is kept.
#'
#' A fixed list of Read deny rules blocks common secret files at any depth:
#' `.env*`, `.Renviron*`, `.netrc`, `.git-credentials`, `*.pem`, `*.key`,
#' SSH keys (`id_rsa*`, `id_dsa*`, `id_ecdsa*`, `id_ed25519*`) and `.ssh/`.
#' Claude Code applies these best-effort to Glob and Grep as well. This is
#' defense in depth, **not a sandbox**: the agent can read every other file
#' in `workdir` and send it to the model, including secrets under other
#' names. Point `workdir` at a directory that holds only what the agent
#' should see. Managed (policy) settings still apply.
#'
#' Needs Claude Code CLI 2.1.259 or later on PATH. Not supported on Windows
#' yet.
#'
#' @param prompt The task, as a single string.
#' @param schema A JSON Schema, as a single JSON string, that the answer
#'   must match. Write it as JSON text, not as an R list: converting a list
#'   with `jsonlite::toJSON(auto_unbox = TRUE)` turns one-element arrays such
#'   as `required` into scalars and silently breaks the schema.
#' @param workdir Path of an existing directory the agent works in. Its
#'   files are read in place, not copied.
#' @param timeout Wall-clock limit for the whole run, in seconds. When it
#'   runs out, the CLI and all its child processes are killed.
#'
#' @return An object of class `fmisc_agent_result`, a list with:
#'   \describe{
#'     \item{`value`}{The structured output, parsed by
#'       [jsonlite::fromJSON()] with default simplification (arrays of
#'       objects become data frames).}
#'     \item{`cost_usd`}{The CLI's estimated cost. Under a subscription this
#'       is not what you pay.}
#'     \item{`num_turns`}{Number of agent turns.}
#'     \item{`model`}{The model(s) the CLI actually used.}
#'     \item{`session_id`}{For correlation only; the session cannot be
#'       resumed.}
#'     \item{`permission_denials`}{Tool calls the CLI refused, which show
#'       when the agent tried to step outside read-only mode.}
#'     \item{`raw`}{The full parsed CLI result, for debugging. Not part of
#'       the stable contract.}
#'   }
#'
#' @section Errors:
#' Every error inherits from `fmisc_agent_error`:
#' \describe{
#'   \item{`fmisc_agent_invalid_argument`}{A bad argument, including a
#'     `schema` that is not valid JSON. Raised before the CLI starts.}
#'   \item{`fmisc_agent_missing_package`}{\pkg{processx} or \pkg{jsonlite}
#'     is not installed.}
#'   \item{`fmisc_agent_cli_missing`}{`claude` is not on PATH.}
#'   \item{`fmisc_agent_timeout`}{The run hit `timeout`. Fields: `timeout`,
#'     `stderr`.}
#'   \item{`fmisc_agent_failed`}{The CLI exited non-zero, reported
#'     `is_error`, or printed output that is not JSON. Fields:
#'     `exit_status`, `subtype` (such as `"error_max_turns"`), `stderr`.}
#'   \item{`fmisc_agent_no_output`}{The run succeeded but returned no
#'     structured output, typically a refusal. Fields: `subtype`,
#'     `permission_denials`.}
#' }
#' Messages never contain the prompt, the model's text or file contents.
#'
#' @examples
#' \dontrun{
#' schema <- paste0(
#'   '{"type": "object", "required": ["functions"], "properties": ',
#'   '{"functions": {"type": "array", "items": {"type": "string"}}}}'
#' )
#' res <- agent_run(
#'   "Which exported functions in this package have no examples?",
#'   schema = schema,
#'   workdir = "."
#' )
#' res$value$functions
#' res
#' }
#'
#' @export
agent_run <- function(prompt, schema, workdir = ".", timeout = 600) {
  for (pkg in c("processx", "jsonlite")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop2(
        "{.fn agent_run} needs the {.pkg {pkg}} package. Install it first.",
        class = c("fmisc_agent_missing_package", "fmisc_agent_error")
      )
    }
  }
  check_agent_args(prompt, schema, workdir, timeout)

  claude <- Sys.which("claude")
  if (!nzchar(claude)) {
    stop2(
      "The {.code claude} CLI was not found on PATH.",
      class = c("fmisc_agent_cli_missing", "fmisc_agent_error")
    )
  }

  prompt_file <- tempfile("agent-prompt-")
  on.exit(unlink(prompt_file), add = TRUE)
  writeLines(prompt, prompt_file, useBytes = TRUE)

  run <- processx::run(
    claude,
    agent_cli_args(schema),
    wd = workdir,
    stdin = prompt_file,
    timeout = timeout,
    error_on_status = FALSE,
    cleanup_tree = TRUE,
    env = agent_child_env()
  )

  # With error_on_status = FALSE, processx flags a timeout instead of raising.
  # cleanup_tree = TRUE has already killed the CLI and its children.
  if (isTRUE(run$timeout)) {
    stop2(
      "claude did not finish within the {timeout} s timeout.",
      timeout = timeout,
      stderr = run$stderr,
      class = c("fmisc_agent_timeout", "fmisc_agent_error")
    )
  }

  result <- parse_agent_output(run)
  new_agent_result(result)
}

# Parse the CLI's JSON result and raise a classed error for every failure
# shape: non-JSON stdout, a non-zero exit, or a result flagged `is_error`.
parse_agent_output <- function(run) {
  exit_status <- run$status
  if (!isTRUE(jsonlite::validate(run$stdout))) {
    stop2(
      "claude printed non-JSON output (exit status {exit_status}).",
      exit_status = exit_status,
      subtype = NA_character_,
      stderr = run$stderr,
      class = c("fmisc_agent_failed", "fmisc_agent_error")
    )
  }

  result <- jsonlite::fromJSON(run$stdout)
  if (exit_status != 0L || isTRUE(result$is_error)) {
    subtype <- if (is.character(result$subtype)) {
      result$subtype
    } else {
      NA_character_
    }
    stop2(
      "claude run failed with exit status {exit_status} (subtype {subtype}).",
      exit_status = exit_status,
      subtype = subtype,
      stderr = run$stderr,
      class = c("fmisc_agent_failed", "fmisc_agent_error")
    )
  }

  # The CLI leaves out structured_output when the model refuses.
  if (is.null(result$structured_output)) {
    subtype <- result$subtype
    stop2(
      "claude finished (subtype {subtype}) but returned no structured output.",
      subtype = subtype,
      permission_denials = result$permission_denials,
      class = c("fmisc_agent_no_output", "fmisc_agent_error")
    )
  }
  result
}

check_agent_args <- function(prompt, schema, workdir, timeout) {
  invalid <- function(message) {
    stop2(
      message,
      class = c("fmisc_agent_invalid_argument", "fmisc_agent_error"),
      .envir = parent.frame()
    )
  }
  if (!is_string(prompt)) {
    invalid("{.arg prompt} must be a single non-missing string.")
  }
  if (!is_string(schema) || !isTRUE(jsonlite::validate(schema))) {
    invalid("{.arg schema} must be a single string holding valid JSON.")
  }
  if (!is_string(workdir) || !dir.exists(workdir)) {
    invalid("{.arg workdir} must be the path of an existing directory.")
  }
  if (
    !is.numeric(timeout) ||
      length(timeout) != 1L ||
      is.na(timeout) ||
      timeout <= 0
  ) {
    invalid("{.arg timeout} must be a single positive number of seconds.")
  }
}

is_string <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x)
}

agent_cli_args <- function(schema) {
  c(
    "-p",
    "--output-format",
    "json",
    "--json-schema",
    schema,
    "--safe-mode",
    "--restricted",
    "--strict-mcp-config",
    "--tools",
    "Read,Glob,Grep",
    "--disallowedTools",
    "mcp__*",
    agent_secret_deny_rules,
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
}

# Read deny rules (gitignore syntax; a pattern without a slash matches at any
# depth). Claude Code applies Read rules best-effort to Glob and Grep too; it
# never consults Glob or Grep path rules, so none are passed. Defense in
# depth, not a sandbox: a secret under any other name stays readable.
agent_secret_deny_rules <- c(
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
  "Read(.ssh/**)"
)

# Variables that make the CLI authenticate with something other than the
# subscription login, or send requests somewhere other than Anthropic.
# CLAUDE_CODE_OAUTH_TOKEN (from `claude setup-token`) is the subscription
# and passes through.
agent_unset_env <- c(
  "ANTHROPIC_API_KEY",
  "ANTHROPIC_AUTH_TOKEN",
  "ANTHROPIC_BASE_URL",
  "ANTHROPIC_CUSTOM_HEADERS",
  "CLAUDE_CODE_USE_BEDROCK",
  "CLAUDE_CODE_USE_VERTEX",
  "CLAUDE_CODE_USE_FOUNDRY",
  "CLAUDE_CODE_USE_MANTLE",
  "CLAUDE_CODE_USE_ANTHROPIC_AWS"
)

# The parent environment minus agent_unset_env, so billing always goes
# through the Claude subscription.
agent_child_env <- function() {
  env <- unclass(Sys.getenv())
  env[!names(env) %in% agent_unset_env]
}

new_agent_result <- function(result) {
  structure(
    list(
      value = result$structured_output,
      cost_usd = result$total_cost_usd,
      num_turns = result$num_turns,
      model = names(result$modelUsage),
      session_id = result$session_id,
      permission_denials = result$permission_denials,
      raw = result
    ),
    class = "fmisc_agent_result"
  )
}

#' @export
print.fmisc_agent_result <- function(x, ...) {
  cat(
    "<fmisc_agent_result> ",
    paste(x$model, collapse = ", "),
    ", ",
    x$num_turns,
    " turns, est. cost USD ",
    format(x$cost_usd),
    "\n",
    sep = ""
  )
  utils::str(x$value)
  invisible(x)
}
