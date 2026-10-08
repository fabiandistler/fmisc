# MAINTENANCE - maintenance catalog

<!--
Source: prompt idea by Fabian Distler, 2026-09-01, developed with skill `idee-zu-artefakt`.
Run by: plugin `repo-maintenance`, skill `maintenance-run`.
Review date: 2026-12-01 - see sunset condition below.
-->

## Status

| Field | Value |
|---|---|
| Last run | *(none yet)* |
| Last job | - |
| Next due job | `deps-audit` (no job has run yet -> catalog order) |
| Open maintenance PRs | - |

## Rules

1. **Exactly one job per run.**
2. **Job choice by relative overdueness:** `score = (today - last_run) / cooldown`.
   Highest score wins, `-` counts as infinite, ties go to catalog order.
   Reason: picking by absolute date, a 7-day job would take every slot.
3. **A job with an open maintenance PR is skipped** and counts as in progress.
4. **Every run ends in exactly one PR** on `maintenance/<job>-<YYYY-MM-DD>`, report-only jobs
   too. No commit to the default branch.
5. **Diff budget < 300 lines.** The rest goes under *Backlog*.
6. **Behavior is never changed.** Changes only to docs, dead exports, and test
   infrastructure - and only with identical check status before and after the run.

## What does NOT belong in this catalog

Anything a tool answers conclusively belongs in the CI gate, not in an agent run. A job that
regularly finds nothing when CI is green only burns rotation slots.

| Once planned as a job | Runs in CI instead |
|---|---|
| security-footguns | gitleaks, bandit, ruff default rules (`BLE001`, `S110`, `ASYNC`) + pre-commit |
| dead-code (local vars/imports) | `ruff F401/F841`, `lintr::object_usage_linter` |
| workflow security | zizmor (GitHub Actions) |
| deps-audit, scan half (uv projects) | `uv audit`: blocking on lockfile PRs, weekly report |
| new dependencies (slopsquatting) | `maintenance-new-deps`: report on PRs that add a dependency |

Only the open question stays in the catalog: `dead-exports` (exports across the package boundary)
and the triage half of `deps-audit`.

## Preconditions per run

- Clean working tree, on the default branch, `git fetch` has run.
- Baseline recorded: `R CMD check` / `pytest` **before** the run.
- Red or missing baseline -> report jobs only.

## Jobs

| # | Job | Scanner | Output | Cooldown | Last run |
|---|---|---|---|---|---|
| 1 | `deps-audit` | yes | Report | 7d | - |
| 2 | `doc-drift` | no | PR | 14d | - |
| 3 | `dead-exports` | yes | PR | 14d | - |
| 4 | `error-edges` | no | Report | 14d | - |
| 5 | `test-flakiness` | yes | PR | 30d | - |
| 6 | `perf-quickwins` | no | Report | 30d | - |
| 7 | `semantic-duplication` | no | Report | 30d | - |

Open question per job (details in the skill under `references/jobs.md`):

1. **deps-audit** - Will these updates break me, and does this advisory hit code we call?
   The scanner or the weekly CI report delivers the list, the run delivers breaking-change
   risk from changelogs it has read, and a decision per finding.
2. **doc-drift** - Do the docs still describe what the code does? Proven by running the
   examples. Only docs are touched.
3. **dead-exports** - Is this export really dead across the package boundary? Evidence per
   removal: git grep, NAMESPACE/`__all__`, vignettes, reverse deps, `git log -S`.
4. **error-edges** - Where does the code swallow an error silently? Report, no PR.
5. **test-flakiness** - Is the time, randomness, or network dependency intentional? Only the
   source of nondeterminism is replaced, never the assertion.
6. **perf-quickwins** - Measurably slow, or just ugly? No measurement, no finding.
7. **semantic-duplication** - Does this logic already exist elsewhere in a different shape?
   Also parameters no caller passes, single-implementation abstractions, pure wrappers.
   Evidence: both locations and a shared input with the same output. Report, no PR.

## Backlog

*(empty)*

## Run history

| Date | Job | Output | PR |
|---|---|---|---|
| - | - | - | - |

## Sunset condition

Review date 2026-12-01. Fewer than four runs or not a single merged maintenance PR ->
replace with a manual checklist and uninstall the plugin.
