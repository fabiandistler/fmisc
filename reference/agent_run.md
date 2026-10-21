# Run a read-only Claude Code agent and get structured output back

Runs the Claude Code CLI (`claude -p`) once in `workdir` and returns its
answer as an R object that matches a JSON Schema. The agent can read the
files under `workdir` but cannot change them, run commands or reach the
web.

## Usage

``` r
agent_run(prompt, schema, workdir = ".", timeout = 600)
```

## Arguments

- prompt:

  The task, as a single string.

- schema:

  A JSON Schema, as a single JSON string, that the answer must match.
  Write it as JSON text, not as an R list: converting a list with
  `jsonlite::toJSON(auto_unbox = TRUE)` turns one-element arrays such as
  `required` into scalars and silently breaks the schema.

- workdir:

  Path of an existing directory the agent works in. Its files are read
  in place, not copied.

- timeout:

  Wall-clock limit for the whole run, in seconds. When it runs out, the
  CLI and all its child processes are killed.

## Value

An object of class `fmisc_agent_result`, a list with:

- `value`:

  The structured output, parsed by
  [`jsonlite::fromJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)
  with default simplification (arrays of objects become data frames).

- `cost_usd`:

  The CLI's estimated cost. Under a subscription this is not what you
  pay.

- `num_turns`:

  Number of agent turns.

- `model`:

  The model(s) the CLI actually used.

- `session_id`:

  For correlation only; the session cannot be resumed.

- `permission_denials`:

  Tool calls the CLI refused, which show when the agent tried to step
  outside read-only mode.

- `raw`:

  The full parsed CLI result, for debugging. Not part of the stable
  contract.

## Authentication and billing

`agent_run()` uses whatever login the `claude` CLI already has, meant to
be the owner's Claude subscription (OAuth). It never reads, stores or
passes tokens. These variables are **removed** from the child process's
environment, so nothing set in the R session can switch the run to API
billing, a gateway or a cloud provider: `ANTHROPIC_API_KEY`,
`ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`,
`ANTHROPIC_CUSTOM_HEADERS`, `CLAUDE_CODE_USE_BEDROCK`,
`CLAUDE_CODE_USE_VERTEX`, `CLAUDE_CODE_USE_FOUNDRY`,
`CLAUDE_CODE_USE_MANTLE` and `CLAUDE_CODE_USE_ANTHROPIC_AWS`.
`CLAUDE_CODE_OAUTH_TOKEN` (a subscription token from
`claude setup-token`) passes through. `cost_usd` is the CLI's
client-side estimate, not a bill. Use it for occasional, attended calls;
it is not made for batch runs over many rows.

## Isolation

The CLI runs with `--safe-mode --restricted --strict-mcp-config`, so
CLAUDE.md, skills, plugins, hooks, MCP servers and settings files are
not loaded. Only the `Read`, `Glob` and `Grep` tools are available, and
any call that would need a permission prompt is denied (`dontAsk`,
`--permission-prompts none`). The model (`sonnet`), the turn cap (20)
and the budget cap (USD 1) are fixed. The prompt goes on stdin, never on
the command line, and no session transcript is kept.

A fixed list of Read deny rules blocks common secret files at any depth:
`.env*`, `.Renviron*`, `.netrc`, `.git-credentials`, `*.pem`, `*.key`,
SSH keys (`id_rsa*`, `id_dsa*`, `id_ecdsa*`, `id_ed25519*`) and `.ssh/`.
Claude Code applies these best-effort to Glob and Grep as well. This is
defense in depth, **not a sandbox**: the agent can read every other file
in `workdir` and send it to the model, including secrets under other
names. Point `workdir` at a directory that holds only what the agent
should see. Managed (policy) settings still apply.

Needs Claude Code CLI 2.1.259 or later on PATH. Not supported on Windows
yet.

## Errors

Every error inherits from `fmisc_agent_error`:

- `fmisc_agent_invalid_argument`:

  A bad argument, including a `schema` that is not valid JSON. Raised
  before the CLI starts.

- `fmisc_agent_missing_package`:

  processx or jsonlite is not installed.

- `fmisc_agent_cli_missing`:

  `claude` is not on PATH.

- `fmisc_agent_timeout`:

  The run hit `timeout`. Fields: `timeout`, `stderr`.

- `fmisc_agent_failed`:

  The CLI exited non-zero, reported `is_error`, or printed output that
  is not JSON. Fields: `exit_status`, `subtype` (such as
  `"error_max_turns"`), `stderr`.

- `fmisc_agent_no_output`:

  The run succeeded but returned no structured output, typically a
  refusal. Fields: `subtype`, `permission_denials`.

Messages never contain the prompt, the model's text or file contents.

## Examples

``` r
if (FALSE) { # \dontrun{
schema <- paste0(
  '{"type": "object", "required": ["functions"], "properties": ',
  '{"functions": {"type": "array", "items": {"type": "string"}}}}'
)
res <- agent_run(
  "Which exported functions in this package have no examples?",
  schema = schema,
  workdir = "."
)
res$value$functions
res
} # }
```
