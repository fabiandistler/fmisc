# Implementation Plan: Refactor use_function_template()

**Branch**: `002-refactor-use-template` | **Date**: 2026-04-24 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `specs/002-refactor-use-template/spec.md`

## Summary

`use_function_template()` already delegates file creation to `usethis::use_template()` but wraps it with three manual pre-validation checks. Research confirms that two of these checks (DESCRIPTION present, R/ directory exists) duplicate validation that usethis performs internally. The third (file already exists) provides intentionally stricter behavior (hard error vs. interactive prompt) and must stay. The refactor removes the two redundant checks and their associated error messages, shrinking the function body by ~20 lines with no change to the public contract.

## Technical Context

**Language/Version**: R >= 3.5.0  
**Primary Dependencies**: usethis (already in Imports), cli (already in Imports)  
**Storage**: N/A  
**Testing**: testthat edition 3; `tests/testthat/`  
**Target Platform**: R package environment  
**Project Type**: R package library  
**Performance Goals**: N/A  
**Constraints**: Public contract must remain unchanged; no behavior change visible to callers in the happy path or the file-exists error path  
**Scale/Scope**: Single function (~40-line diff)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|---|---|---|
| I. Tidyverse Design & data.table | ✅ PASS | Delegating to usethis is idiomatic; cli retained for output |
| II. Test-First Development | ✅ PASS | Tests written before implementation (see tasks) |
| III. Code Quality & Linting | ✅ PASS | Fewer lines = fewer lint targets; devtools::check() required |
| IV. Feature Scope & Clarity | ✅ PASS | Single function, one well-defined responsibility, no scope creep |
| V. Development Workflow | ✅ PASS | Feature branch exists; PR will be linked to issue |

No violations. Complexity Tracking section not needed.

## Project Structure

### Documentation (this feature)

```text
specs/002-refactor-use-template/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── contracts/
│   └── use_function_template.md   # Public API contract
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code

```text
R/
└── use_function_template.R    # Only file modified

tests/testthat/
└── test-use_function_template.R   # New test file
```

## Implementation Approach

### Changes to `R/use_function_template.R`

**Remove** the DESCRIPTION-file check block (lines 43–51):

```r
if (!file.exists("DESCRIPTION")) {
  cli::cli_abort(...)
}
```

**Remove** the R/ directory check block (lines 54–60):

```r
if (!dir.exists("R")) {
  cli::cli_abort(...)
}
```

**Keep** the `.R` extension stripping (line 64): `name <- sub("\\.R$", "", name)`

**Keep** the file-existence check (lines 69–74) — this provides a hard error that differs from usethis's interactive-prompt behavior.

**Keep** the `usethis::use_template()` call, success message, and `invisible(result)`.

The resulting function is ~55 lines → ~35 lines.

### New Tests (`tests/testthat/test-use_function_template.R`)

Tests must use `withr::local_tempdir()` and create a minimal package structure to satisfy usethis's active-project requirement.

| Test | Description |
|---|---|
| Happy path | Creates `R/my_func.R` in a temp package |
| `.R` extension stripping | `"my_func.R"` creates `R/my_func.R`, not `R/my_func.R.R` |
| File exists → error | Second call with same name errors |
| `open = FALSE` default | Does not open file when called with `open = FALSE` |

## Phase 0 Research Summary

See [research.md](research.md) for full findings. Key decisions:

- DESCRIPTION check removed (usethis handles project context)
- R/ directory check removed (usethis handles parent directory creation)
- File-exists check kept (hard error vs. usethis's interactive prompt)
- `.R` stripping kept (usethis does not strip extensions from `save_as`)

## Phase 1 Design

### Contracts

See [contracts/use_function_template.md](contracts/use_function_template.md).

The public signature and return value are **unchanged**. The only change in observable behavior is that callers outside an R package now see usethis's error message instead of fmisc's custom message.

### Data Model

Not applicable — no data entities involved.

### Quickstart

Not applicable — caller usage is unchanged; the existing roxygen2 examples remain valid.
