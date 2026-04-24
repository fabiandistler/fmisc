# Tasks: Refactor use_*_template Functions

**Input**: Design documents from `/specs/002-refactor-use-template/`
**Prerequisites**: plan.md, spec.md, research.md, contracts/use_function_template.md

**Tests**: Included per TDD requirement (constitution gate 1 — TDD enforced: new tests written before implementation).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)
- Exact file paths included in all descriptions

---

## Phase 1: Setup

**Purpose**: Create the shared test file that both user stories will populate.

- [x] T001 Create test file `tests/testthat/test-use_function_template.R` with empty `test_that()` scaffolding

---

## Phase 2: User Story 1 — Create Function File from Template (Priority: P1) 🎯 MVP

**Goal**: Remove the redundant DESCRIPTION and R/ precondition checks so `use_function_template()` delegates all project-context validation to `usethis::use_template()`.

**Independent Test**: Call `use_function_template("test_func", open = FALSE)` inside a temporary package (via `withr::with_tempdir` + `usethis::create_package`) and verify `R/test_func.R` is created with the expected template content.

### Tests for User Story 1

> **Write these tests FIRST and ensure they FAIL before implementation**

- [x] T002 [US1] Write test: happy path — `use_function_template("my_func", open = FALSE)` in a temp package creates `R/my_func.R` in `tests/testthat/test-use_function_template.R`
- [x] T003 [US1] Write test: `.R` extension stripped — `use_function_template("my_func.R", open = FALSE)` creates `R/my_func.R` (not `R/my_func.R.R`) in `tests/testthat/test-use_function_template.R`

### Implementation for User Story 1

- [x] T004 [US1] Remove DESCRIPTION-file check block (lines 42–51) from `R/use_function_template.R`
- [x] T005 [US1] Remove R/-directory check block (lines 53–61) from `R/use_function_template.R`
- [x] T006 [US1] Run `devtools::test(filter = "use_function_template")` and confirm T002 and T003 pass

**Checkpoint**: `use_function_template("test_func", open = FALSE)` works end-to-end in a fresh temporary package.

---

## Phase 3: User Story 2 — Error on Invalid Conditions (Priority: P2)

**Goal**: Add the FR-008 name validation guard and remove the redundant file-exists check, delegating file-overwrite handling entirely to `usethis::use_template()`.

**Independent Test**: Call `use_function_template("../../etc/bad")` and `use_function_template("123bad")` and verify `cli_abort` fires with the expected message before any usethis call is made.

### Tests for User Story 2

> **Write these tests FIRST and ensure they FAIL before implementation**

- [x] T007 [US2] Write test: FR-008 — `name` with path separator (e.g., `"../../etc/bad"`) raises `cli_abort` with message matching `"must be a valid R identifier"` in `tests/testthat/test-use_function_template.R`
- [x] T008 [US2] Write test: FR-008 — `name` starting with a digit (e.g., `"123bad"`) raises `cli_abort` in `tests/testthat/test-use_function_template.R`
- [x] T009 [US2] Write test: FR-008 — `name` with a space (e.g., `"bad name"`) raises `cli_abort` in `tests/testthat/test-use_function_template.R`

### Implementation for User Story 2

- [x] T010 [US2] Remove file-exists check block (lines 68–77) from `R/use_function_template.R` (file-overwrite behavior delegated to `usethis::use_template()` per FR-004)
- [x] T011 [US2] Add FR-008 name validation block after the `sub("\\.R$", "", name)` line and before `save_as` construction in `R/use_function_template.R` using the exact regex and `cli_abort` call from plan.md implementation notes
- [x] T012 [US2] Run `devtools::test(filter = "use_function_template")` and confirm T007–T009 pass and T002–T003 still pass

**Checkpoint**: Invalid name inputs are rejected before usethis is called; valid inputs succeed; all 5 new tests pass.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Full-package quality gates required by the constitution before merging.

- [x] T013 [P] Run `devtools::check()` from package root and verify 0 errors, ≤ 3 pre-existing warnings
- [x] T014 [P] Run `lintr::lint("R/use_function_template.R")` and confirm no new violations
- [x] T015 Run `styler::style_file("R/use_function_template.R")` and verify no styling changes are needed

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **US1 (Phase 2)**: Depends on Phase 1 (test file must exist)
- **US2 (Phase 3)**: Depends on Phase 1; independent of Phase 2 — can run in parallel after T001
- **Polish (Phase 4)**: Depends on Phase 2 and Phase 3 both complete

### User Story Dependencies

- **User Story 1 (P1)**: No dependency on US2 — independently testable after Setup
- **User Story 2 (P2)**: No dependency on US1 — independently testable after Setup

### Within Each User Story

1. Write tests (ensure FAIL) → implement changes → verify tests pass

### Parallel Opportunities

- After T001: US1 (T002–T006) and US2 (T007–T012) can proceed in parallel, but both modify `R/use_function_template.R` — work sequentially per story to avoid conflicts
- T013 (check) and T014 (lint) can run in parallel

---

## Parallel Example: User Story 2 Tests

```bash
# All three FR-008 test cases can be drafted together (same file, separate test_that blocks):
Task T007: name with path separator
Task T008: name starting with digit
Task T009: name with space / non-identifier char
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. T001 — create test file
2. T002, T003 — write happy-path tests (ensure FAIL)
3. T004, T005 — remove redundant checks
4. T006 — verify tests pass
5. **STOP and VALIDATE**: US1 happy path fully functional

### Incremental Delivery

1. Setup (T001) → shared test file ready
2. US1 (T002–T006) → redundant pre-checks removed; happy path verified
3. US2 (T007–T012) → FR-008 guard added; error paths verified
4. Polish (T013–T015) → `devtools::check()` clean; ready to merge

---

## Notes

- [P] tasks = different files, no dependencies — safe to run concurrently
- [Story] label maps each task to a specific user story for traceability
- `R/use_function_template.R` is modified in both US1 and US2 — work per story to avoid conflicts
- Write tests first; confirm they FAIL before making the implementation change
- Commit after each phase or logical group
