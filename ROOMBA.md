# ROOMBA — Wartungs-Katalog

Wiederkehrende Wartungsjobs für `fmisc`. Pro Lauf wird **genau ein** Job
ausgeführt — der fällige Job mit dem ältesten Fälligkeitsdatum.

## Regeln

- **Ein Job pro Lauf.** Kein Bündeln, kein "während ich schon dabei bin".
- **PRs** nur auf einem Branch `roomba/<job>-<YYYY-MM-DD>`, Diff **< 300 Zeilen**.
- **Verhalten wird nie geändert.** Ausnahme: die Jobs `doc-drift`, `dead-code`
  und `test-flakiness` dürfen Verhalten dort anfassen, wo genau das der Punkt
  ist (falsche Doku, toter Code, instabiler Test).
- **Report-Jobs schreiben keinen Code.** Ergebnis ist eine Datei unter
  `.roomba/reports/<YYYY-MM-DD>-<job>.md`. Umsetzung folgt separat.
- **Jeder Lauf** aktualisiert unten "zuletzt gelaufen" und benennt den nächsten
  fälligen Job.

## Jobs

| # | Job | Beschreibung | Output | Cooldown |
|---|-----|--------------|--------|----------|
| 1 | `deps-audit` | Veraltete/verwundbare Dependencies; Empfehlung je Fund mit Breaking-Change-Risiko | Report | 7d |
| 2 | `doc-drift` | README, Vignetten und Roxygen-Docstrings gegen das tatsächliche Verhalten prüfen | PR | 14d |
| 3 | `dead-code` | Ungenutzte Funktionen, Exporte, Imports — Nachweis jeweils per Referenzsuche | PR | 14d |
| 4 | `error-edges` | API- und IO-Ränder ohne Fehlerbehandlung oder mit stillem Schlucken | Report | 14d |
| 5 | `test-flakiness` | Tests mit Zeit-, Zufalls- oder Netzabhängigkeit | PR | 30d |
| 6 | `security-footguns` | Hartkodierte Pfade, Secrets-Verdacht, Injection-Ränder, unsichere Defaults — **nur Report, nie PR** | Report | 14d |
| 7 | `perf-quickwins` | Offensichtliche N+1-Muster und Kopier-Orgien; in R speziell unnötige `data.frame`-Kopien statt `data.table`-Referenzsemantik | Report | 30d |

## Status

| Job | Zuletzt gelaufen | Nächste Fälligkeit | Letztes Ergebnis |
|-----|------------------|--------------------|------------------|
| `deps-audit` | 2026-08-25 | 2026-09-01 | [Report](.roomba/reports/2026-08-25-deps-audit.md) — 9 Funde, 2 davon hoch |
| `doc-drift` | — | **fällig** | — |
| `dead-code` | — | **fällig** | — |
| `error-edges` | — | **fällig** | — |
| `test-flakiness` | — | **fällig** | — |
| `security-footguns` | — | **fällig** | — |
| `perf-quickwins` | — | **fällig** | — |

**Nächster fälliger Job: `doc-drift` (Job 2)** — offener Verdacht aus dem
deps-audit: `R/fmisc-package.R` bewirbt die native Pipe, während
`DESCRIPTION` `R (>= 3.5.0)` deklariert (Pipe gibt es erst ab R 4.1).
