# deps-audit report, 2026-11-01

Baseline: not recorded (no R in the run environment) -> report-only run, no code change.

Scanner coverage: `renv::vulns()` skipped (no `renv.lock`, no Rscript); `old.packages()` not run
(no R). Only the DESCRIPTION-vs-OSV-CRAN check ran. Not covered: installed/transitive versions.
Dependabot is configured (PR #80 is its zizmor-action bump), so plain updates stay there.
`issue_comment` one-off check: the only match is a comment in `maintenance-gate.yml`; no trigger.

Advisory details could not be fetched (api.osv.dev returned 403 through the session proxy), so the
findings below rest on the scanner's output (id, title, affected range) and call-site evidence only.
The changelogs were not read; breaking-change risk is therefore unassessed.

## gh: RSEC-2025-0 / CVE-2025-54956 (Arbitrary Code Execution)

- Affected 1.1.0 to <1.5.0; DESCRIPTION has `Imports: gh` with no lower bound, so it admits them.
- Reachability: `gh::gh()` and `gh::gh_tree_remote()` are called in `R/ci_failures.R` (lines 45, 51, 63, 83).
  The package is a hard import, so the code path is reachable at runtime.
- Proposal: raise the bound to `gh (>= 1.5.0)` after reading gh's NEWS for 1.5.0 (not done here).
- Decision: upgrade now (bound change only; it changes DESCRIPTION, so it needs the owner's check run).

## jsonlite: RSEC-2023-3 / CVE-2023-33460 (memory leak)

- Affected 0.9.12 to <1.8.8; `Suggests: jsonlite` has no bound.
- Reachability: `jsonlite::validate()` / `fromJSON()` in `R/agent_run.R` (lines 158, 168, 208) parse
  output of the external Claude CLI, optional at runtime; tests use `toJSON` only.
- Proposal: add `jsonlite (>= 1.8.8)` to Suggests; low urgency (memory leak, Suggests only).
- Decision: upgrade now, same caveat as above.
