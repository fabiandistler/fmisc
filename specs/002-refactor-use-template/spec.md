# Feature Specification: Refactor use_*_template Functions

**Feature Branch**: `002-refactor-use-template`  
**Created**: 2026-04-24  
**Status**: Draft  
**Input**: User description: "Refactor use_*_template functions to wrap usethis::use_template()"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create Function File from Template (Priority: P1)

An R package developer calls `use_function_template("my_func")` inside a package project. The function creates `R/my_func.R` from the bundled template, opening it for editing.

**Why this priority**: This is the primary happy-path use case the function exists to serve.

**Independent Test**: Can be fully tested by calling `use_function_template("test_func", open = FALSE)` in a temporary package directory and verifying the file is created with the expected content.

**Acceptance Scenarios**:

1. **Given** a valid R package directory, **When** `use_function_template("my_func", open = FALSE)` is called, **Then** `R/my_func.R` is created from the function template
2. **Given** a valid R package directory, **When** `use_function_template("my_func.R", open = FALSE)` is called with a `.R` extension, **Then** the extension is stripped and `R/my_func.R` is created

---

### User Story 2 - Error on Invalid Conditions (Priority: P2)

A developer calls `use_function_template("my_func")` outside a package project, or when the target file already exists. The function reports a clear, actionable error.

**Why this priority**: Errors must be clear enough that the developer immediately understands what went wrong and what to do next.

**Independent Test**: Callable in isolation with incorrect preconditions; error messages are verifiable without side effects.

**Acceptance Scenarios**:

1. **Given** a directory without a `DESCRIPTION` file, **When** `use_function_template("my_func")` is called, **Then** an error is raised indicating the function must be called from an R package
2. **Given** a valid package where `R/my_func.R` already exists, **When** `use_function_template("my_func")` is called, **Then** an error is raised indicating the file already exists

---

### Edge Cases

- **Invalid `name`**: If `name` (after stripping `.R`) contains path separators (`/`, `\`) or non-identifier characters, `use_function_template()` errors with a clear message before reaching usethis (FR-008).
- **Missing `R/` directory**: Delegated entirely to `usethis::use_template()`; no pre-check or directory creation in `use_function_template()`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `use_function_template()` MUST create `R/<name>.R` from the bundled function template
- **FR-002**: `use_function_template()` MUST strip a trailing `.R` extension from `name` before constructing the file path
- **FR-003**: `use_function_template()` MUST surface an actionable error when called outside an R package directory; this error is raised and owned by `usethis::use_template()` and MUST NOT be duplicated with a custom pre-check
- **FR-004**: `use_function_template()` MUST surface an actionable error when the target file already exists; this error is raised and owned by `usethis::use_template()` and MUST NOT be duplicated with a custom pre-check
- **FR-005**: Error messages MUST be consistent with usethis conventions (style, tone, and structure)
- **FR-006**: `use_function_template()` MUST NOT duplicate validation that is already performed internally by `usethis::use_template()`
- **FR-008**: `use_function_template()` MUST validate that `name` (after stripping any `.R` extension) contains only valid R identifier characters and no path separators; if invalid, it MUST error with a clear, actionable message before calling `usethis::use_template()`
- **FR-007**: The `open` argument MUST control whether the created file is opened for editing, defaulting to `TRUE` in interactive sessions

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All existing acceptance scenarios pass after the refactor
- **SC-002**: The function body is reduced by removing validation logic that is already handled by the dependency
- **SC-003**: Error messages in all failure paths remain clear and actionable for the developer
- **SC-004**: No regression in `devtools::check()` output compared to before the refactor

## Assumptions

- `usethis::use_template()` internally checks for a valid R package context (DESCRIPTION present) and raises its own errors when preconditions are not met
- `usethis::use_template()` internally handles the case where the destination file already exists
- Any validation not covered by `usethis::use_template()` (e.g., stripping the `.R` extension) remains in `use_function_template()`
- Scope is limited to `use_function_template()`; `use_make2()` is excluded

## Clarifications

### Session 2026-04-24

- Q: Should `use_function_template()` add its own pre-checks with custom error messages before calling usethis, or rely on usethis errors to propagate naturally? → A: Rely on usethis errors to propagate; no custom pre-checks (aligns with FR-006)
- Q: What should happen when `name` contains path separators or non-identifier characters? → A: Validate and error with a clear message before calling usethis (FR-008)
- Q: What should happen when the `R/` directory does not exist in an otherwise valid package? → A: Delegate to `usethis::use_template()`; no pre-check or directory creation
