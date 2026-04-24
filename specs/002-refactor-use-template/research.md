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
| File already exists | `cli_abort` — hard error | `write_over()` prompts interactively; silently no-ops in non-interactive mode | Remove — delegate to usethis per FR-004 |

Although `usethis::use_template()`'s `write_over()` only prompts / no-ops rather than raising a hard error, FR-004 (updated 2026-04-24) explicitly requires that the file-exists check "MUST NOT be duplicated with a custom pre-check." Delegating to usethis is the chosen behavior.

**Alternatives considered**:

- Keep the hard file-exists check — rejected: preserves stricter CI behavior but contradicts FR-004 as written and the general clarification to rely on usethis error propagation.
- Remove all three checks and rely entirely on usethis — **accepted**: DESCRIPTION, R/, and file-exists checks all removed; usethis owns all precondition errors.

### FR-008: Name validation

**Decision**: After stripping the `.R` extension, validate that `name` contains only characters valid in an R identifier and no path separators. If invalid, `cli_abort` before calling `usethis::use_template()`.

**Rationale**: usethis does not validate `save_as` for identifier safety — it would pass a path like `R/../../etc/foo.R` to `file.create()`. This check is not redundant; it is new behavior explicitly required by FR-008.

**Validation rule**: `name` must match `^[a-zA-Z.][a-zA-Z0-9_.]*$` and must not contain `/` or `\`. This accepts all valid R identifiers and rejects path traversal sequences and names beginning with digits.

**Alternatives considered**:

- Rely on usethis to reject bad paths — rejected: usethis does not validate `save_as`; path-traversal inputs would silently create files outside `R/`.
- Use `make.names()` for sanitization — rejected: auto-coercing an invalid name would hide user mistakes; failing fast with a clear error is safer.

### `.R` extension stripping

**Decision**: Keep the `sub("\\.R$", "", name)` line. `usethis::use_template()` does not strip the `.R` extension from `save_as`; passing `"my_func.R"` as `name` without stripping would produce `R/my_func.R.R`.

### Success / failure message after `usethis::use_template()`

**Decision**: Keep the `cli_alert_success` and `cli_bullets` after the call. `usethis::use_template()` does emit its own "Writing" bullet, but the additional context lines ("Delete sections you don't need", "Customize to your requirements") are specific to this template and are not redundant.

### Return value

**Decision**: `usethis::use_template()` returns invisibly. The current `invisible(result)` is correct and should remain.
