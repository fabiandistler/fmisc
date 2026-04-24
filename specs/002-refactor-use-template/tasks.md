# Tasks: Refactor use_function_template()

**Input**: Design documents from `specs/002-refactor-use-template/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, contracts/use_function_template.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)
- Exact file paths are included in each description

---

## Phase 1: Setup

**Purpose**: Confirm the current implementation aligns with the plan before making changes.

- [ ] T001 Read `R/use_function_template.R` and verify the two blocks to remove (DESCRIPTION check and R/ directory check) match their described locations in plan.md

**Checkpoint**: Implementation baseline confirmed — user story work can begin

---

## Phase 2: Foundational (Blocking Prerequisites)

No foundational phase needed — this refactor modifies a single existing function with no shared infrastructure dependencies.

---

## Phase 3: User Story 1 - Create Function File from Template (Priority: P1) 🎯 MVP

**Goal**: `use_function_template("my_func", open = FALSE)` creates `R/my_func.R` from the bundled template; `.R` extension in `name` is stripped transparently.

**Independent Test**: Call `use_function_template("test_func", open = FALSE)` in a temp package created with `withr::local_tempdir()` and verify `R/test_func.R` is created with the expected content.

### Tests for User Story 1

> **Write these tests FIRST — they document expected behavior before the implementation changes**

- [ ] T002 [US1] Create `tests/testthat/test-use_function_template.R` with happy-path test (creates `R/my_func.R` in a temp package using `withr::local_tempdir()` + `usethis::create_package()`) and `.R` extension-stripping test (`"my_func.R"` produces `R/my_func.R`, not `R/my_func.R.R`)

### Implementation for User Story 1

- [ ] T003 [US1] Remove the DESCRIPTION-file check block and the R/-directory check block from `R/use_function_template.R` per plan.md, keeping the `.R` extension stripping, file-exists check, `usethis::use_template()` call, and success messages

**Checkpoint**: User Story 1 fully functional — `use_function_template()` creates a file from the template in any valid R package without custom pre-validation for DESCRIPTION or R/

---

## Phase 4: User Story 2 - Error on Invalid Conditions (Priority: P2)

**Goal**: Calling `use_function_template()` outside an R package or when the target file already exists raises a clear, actionable error.

**Independent Test**: Callable with incorrect preconditions in isolation — verify an error is raised; the file-exists error message is verifiable without side effects.

### Tests for User Story 2

> **Write these tests BEFORE verifying implementation — confirm error paths behave as specified**

- [ ] T004 [P] [US2] Add US2 tests to `tests/testthat/test-use_function_template.R`: (1) second call with same name raises error "File `R/my_func.R` already exists." (file-exists hard error); (2) call in a non-package temp dir raises an error (delegated to usethis — do not assert specific message text)

### Implementation for User Story 2

- [ ] T005 [US2] Read `R/use_function_template.R` and confirm the file-exists check block is intact after T003 — no code change expected; task is verification only

**Checkpoint**: User Stories 1 and 2 both independently functional — happy path creates file, error paths raise actionable errors

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validate the full package is clean after the refactor.

- [ ] T006 [P] Run `devtools::test()` and confirm all tests in `tests/testthat/` pass
- [ ] T007 [P] Run `devtools::check()` and confirm no new NOTEs, WARNINGs, or ERRORs vs. pre-refactor baseline
- [ ] T008 [P] Run `lintr::lint_package()` on `R/use_function_template.R` and `tests/testthat/test-use_function_template.R` and address any lint issues

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **User Stories (Phase 3–4)**: Depend on Setup completion
  - US1 and US2 can proceed sequentially (single function — no parallelism needed)
- **Polish (Phase 5)**: Depends on all user story phases being complete

### User Story Dependencies

- **User Story 1 (P1)**: Starts after Setup (T001) — no dependency on US2
- **User Story 2 (P2)**: Starts after US1 implementation (T003) is complete — shares the same modified file

### Within Each User Story

- Tests (T002, T004) MUST be written before implementation tasks that affect the same behavior
- T003 (implementation) depends on T002 (tests written first)
- T005 (verify file-exists check) depends on T003 (implementation complete)

### Parallel Opportunities

- T004 (US2 tests) can be written in parallel with T003 (US1 implementation) — they write to the same test file but cover independent scenarios; coordinate to avoid conflicts
- T006, T007, T008 (polish) can all run in parallel — read-only verification tasks

---

## Parallel Example: Polish Phase

```r
# All three can run simultaneously once US1 and US2 are complete:
devtools::test()
devtools::check()
lintr::lint_package()
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Write US1 tests (T002)
3. Implement refactor (T003)
4. **STOP and VALIDATE**: Run `devtools::test()` — US1 tests pass
5. Proceed to US2 if validated

### Incremental Delivery

1. T001 (Setup) → T002 (US1 tests) → T003 (US1 impl) → validate US1
2. T004 (US2 tests) → T005 (US2 verify) → validate US2
3. T006 + T007 + T008 in parallel → confirm clean package

---

## Notes

- [P] tasks = independent files or read-only, no write conflicts
- [Story] label maps each task to the user story for traceability
- The implementation change (T003) is a ~20-line deletion in a single file — keep it atomic
- No new dependencies are introduced; usethis and cli are already in `Imports`
- `withr::local_tempdir()` and `usethis::create_package()` are required in tests to satisfy usethis's active-project requirement; see plan.md for full test scaffold
