# fmisc Constitution

## Core Principles

### I. Tidyverse Design & data.table Implementation
Every utility must follow tidyverse design philosophy: purposeful design, consistency, error handling. Implementation must use `{data.table}` for data manipulation (not `{dplyr}`). Roxygen2 documentation required; all exported functions must have complete documentation with examples. Clear, focused purpose required—utilities must serve R package developers, not organizational-only tools.

### II. Test-First Development (NON-NEGOTIABLE)
TDD mandatory for all features: tests written and approved → tests fail → implement → tests pass → refactor. Red-Green-Refactor cycle strictly enforced. Minimum coverage: new features require corresponding tests. Integration tests required for complex workflows. Use `{testthat}` (edition >= 3). No commits merge without passing test suite.

### III. Code Quality & Linting Standards
All code must pass `devtools::check()` with zero errors and minimal warnings. Use `{lintr}` for linting; custom rules via fmisc's flir rule definitions. Code must follow tidyverse style guide. Roxygen2 must generate clean documentation without warnings. No code comments unless the WHY is non-obvious.

### IV. Feature Scope & Clarity
Each utility must have a single, well-defined responsibility. Functions must follow argument ordering: data → descriptors → details. No "org-only" utilities; all tools must be reusable and independently testable. Breaking changes require version bumping (MAJOR.MINOR.PATCH) and explicit documentation.

### V. Development Workflow & Review Discipline
All changes to main require: (1) feature branch off main, (2) new tests, (3) full test suite passing, (4) check output clean, (5) PR created and linked to issue. Code review required. Auto-commit on PR merge. R >= 3.5.0 minimum version target.

## R Ecosystem Standards

- **Dependencies**: Minimize dependencies; Rcpp allowed for performance-critical code (C++11 required). Future/foreach backends supported.
- **Documentation**: Roxygen2-generated docs only; markdown=TRUE for modern formatting.
- **Testing**: testthat edition >= 3; test files in `tests/testthat/`.
- **Utilities**: Use `cli` for user-facing messages; `message()` and `warning()` preferred over `print()` and `cat()` (except in print methods).
- **Seeding**: Use `withr::local_seed()` instead of `set.seed()`.

## Quality Gates

All PRs must satisfy:

1. **Test Suite**: All 272+ tests PASS with `devtools::test()`.
2. **Check**: `devtools::check()` returns 0 errors, <= 3 pre-existing warnings/notes.
3. **Style**: Tidyverse style guide compliance verified.
4. **Documentation**: All exported functions documented; vignettes up-to-date if applicable.
5. **Linting**: No new lintr violations introduced.

Feature freeze on release branches. Version follows MAJOR.MINOR.PATCH semver.

## Governance

This constitution supersedes informal practices. Amendments require:
- Ratification: approval from project maintainer
- Documentation: clear statement of what changed and why
- Migration: update CLAUDE.md and this document

The constitution is the authoritative source for development practices. All PRs and reviews must verify compliance. Use [CLAUDE.md](../../CLAUDE.md) for runtime development guidance. Non-compliance must be justified and documented.

**Version**: 1.0.0 | **Ratified**: 2026-04-23 | **Last Amended**: 2026-04-23
