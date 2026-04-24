# Implementation Plan: Refactor use_*_template Functions

**Branch**: `002-refactor-use-template` | **Date**: 2026-04-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/002-refactor-use-template/spec.md`

## Summary

Refactor `use_function_template()` to remove all three custom precondition checks (DESCRIPTION-present, R/-directory, file-exists) that duplicate or conflict with `usethis::use_template()` internals, and add a new name-validation guard (FR-008) for path separators and non-identifier characters. Net change: ~30 lines removed, ~8 lines added.

## Technical Context

**Language/Version**: R >= 3.5.0  
**Primary Dependencies**: `usethis`, `cli` (both already in `Imports`)  
**Storage**: N/A — creates files in the active project directory  
**Testing**: `testthat` edition 3  
**Target Platform**: R package ecosystem  
**Project Type**: R library  
**Performance Goals**: N/A — file-creation utility  
**Constraints**: Must not break existing behavior for valid inputs; FR-004 requires delegating file-exists handling to usethis  
**Scale/Scope**: Single function in one source file

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Requirement | Status |
|---|---|---|
| 1. Test Suite | All 272+ tests pass with `devtools::test()` | ✅ TDD enforced — new tests written before implementation (T002, T004) |
| 2. Check | `devtools::check()` 0 errors, ≤ 3 pre-existing warnings | ✅ Covered by T007 post-implementation |
| 3. Style | Tidyverse style guide | ✅ Refactor removes code; no new anti-patterns introduced |
| 4. Documentation | All exported functions fully documented | ✅ Existing roxygen2 docs unchanged; return value doc remains accurate |
| 5. Linting | No new lintr violations | ✅ Covered by T008 post-implementation |

**Constitution Check**: PASS — all five gates satisfied. No violations to justify.

**Post-design re-check**: PASS — design removes code, adds a single validation block using `cli::cli_abort()` already used in the codebase. No new dependencies, no new patterns.

## Project Structure

### Documentation (this feature)

```text
specs/002-refactor-use-template/
├── plan.md                          # This file
├── research.md                      # Phase 0 output
├── contracts/
│   └── use_function_template.md    # Phase 1 output
└── tasks.md                        # /speckit-tasks output (stale — re-run after plan)
```

### Source Code (repository root)

```text
R/
└── use_function_template.R    # Modified — three blocks removed, one block added

tests/
└── testthat/
    └── test-use_function_template.R    # Created (new)
```

**Structure Decision**: Single-project R package. Only `R/use_function_template.R` is modified; a new test file `tests/testthat/test-use_function_template.R` is created.

## Implementation Notes

### Blocks to Remove (from `R/use_function_template.R`)

Three contiguous check blocks are deleted entirely:

```r
# REMOVE — lines 42-51: DESCRIPTION-file check
if (!file.exists("DESCRIPTION")) {
  cli::cli_abort(...)
}

# REMOVE — lines 53-61: R/-directory check
if (!dir.exists("R")) {
  cli::cli_abort(...)
}

# REMOVE — lines 68-77: file-exists check
if (file.exists(save_as)) {
  cli::cli_abort(...)
}
```

### Block to Add (FR-008 — name validation)

Insert after the `.R` extension stripping (`name <- sub(...)`), before `save_as` is constructed:

```r
if (!grepl("^[a-zA-Z.][a-zA-Z0-9_.]*$", name) || grepl("[/\\\\]", name)) {
  cli::cli_abort(
    c(
      "{.arg name} must be a valid R identifier.",
      "x" = "{.val {name}} contains invalid characters.",
      "i" = "Use only letters, digits, dots, and underscores; no path separators."
    )
  )
}
```

### Resulting function skeleton (after refactor)

```r
use_function_template <- function(name, open = interactive()) {
  name <- sub("\\.R$", "", name)

  # FR-008: validate name
  if (!grepl("^[a-zA-Z.][a-zA-Z0-9_.]*$", name) || grepl("[/\\\\]", name)) {
    cli::cli_abort(...)
  }

  save_as <- file.path("R", paste0(name, ".R"))

  result <- usethis::use_template(
    template = "function_template.R",
    save_as = save_as,
    data = list(),
    ignore = FALSE,
    open = open,
    package = "fmisc"
  )

  cli::cli_alert_success("Created {.file {save_as}} from function template")
  cli::cli_bullets(c(...))

  invisible(result)
}
```

### Behavior Changes Summary

| Scenario | Before | After |
|---|---|---|
| Called outside an R package | Custom `cli_abort` (DESCRIPTION missing) | usethis error propagated |
| Called when `R/` dir missing | Custom `cli_abort` | usethis error propagated |
| File already exists | Custom `cli_abort` (hard error) | usethis `write_over()` — prompts interactively, no-ops non-interactively |
| `name` contains `/` or invalid chars | No check (path traversal possible) | `cli_abort` before usethis call |

## Tasks Staleness Note

`tasks.md` was generated before FR-008 was added to the spec and before the file-exists decision was reversed. Re-run `/speckit-tasks` after this plan to regenerate tasks that include the FR-008 implementation and updated error path tests.
