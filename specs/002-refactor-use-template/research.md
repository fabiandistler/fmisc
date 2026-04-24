# Research: Refactor use_*_template Functions

**Feature**: 002-refactor-use-template  
**Phase**: 0 — Research  
**Date**: 2026-04-24

## Findings

### What `usethis::use_template()` validates internally

**Decision**: Remove the DESCRIPTION-file check and the R/ directory check from `use_function_template()`; keep the file-existence check.

**Rationale**:

| Check | In current code | In `usethis::use_template()` | Verdict |
|---|---|---|---|
| DESCRIPTION present | `cli_abort` with custom message | Implicit — usethis requires an active project and raises its own error | Redundant — remove |
| `R/` directory exists | `cli_abort` with custom message | usethis creates parent directories as needed | Redundant — remove |
| File already exists | `cli_abort` — hard error | `write_over()` prompts interactively; silently no-ops in non-interactive mode | Different behavior — keep the hard error |

The file-existence check is intentionally stricter than usethis: silently skipping or prompting is wrong for a developer scaffolding tool where the user should never be surprised by an overwrite. Keeping the explicit `cli_abort` preserves that intent.

**Alternatives considered**:

- Remove all three checks and rely entirely on usethis — rejected because the file-existence behavior would change from a hard error to a quiet no-op in non-interactive contexts (e.g., CI, batch scripts).
- Keep all three checks — rejected because the DESCRIPTION and R/ checks duplicate usethis error handling with no user-visible benefit; they add lines that need maintenance.

### `.R` extension stripping

**Decision**: Keep the `sub("\\.R$", "", name)` line. `usethis::use_template()` does not strip the `.R` extension from `save_as`; passing `"my_func.R"` as `name` without stripping would produce `R/my_func.R.R`.

### Success / failure message after `usethis::use_template()`

**Decision**: Keep the `cli_alert_success` and `cli_bullets` after the call. `usethis::use_template()` does emit its own "Writing" bullet, but the additional context lines ("Delete sections you don't need", "Customize to your requirements") are specific to this template and are not redundant.

### Return value

**Decision**: `usethis::use_template()` returns invisibly. The current `invisible(result)` is correct and should remain.
