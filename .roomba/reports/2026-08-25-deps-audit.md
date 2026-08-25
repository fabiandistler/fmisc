# deps-audit — 2026-08-25

**Job:** 1 (`deps-audit`) · **Output:** Report · **Cooldown:** 7d
**Basis:** `DESCRIPTION` @ `066aff9`, `.github/workflows/*`, Referenzsuche in `R/`, `src/`, `tests/`, `vignettes/`
**Vergleichsbasis für "aktuell":** CRAN-Release-`DESCRIPTION`s, gelesen über den CRAN-GitHub-Spiegel am 2026-08-25.

## Wichtige Einschränkung vorab

In dieser Umgebung ist kein R installiert und der Netz-Proxy blockiert
CRAN, `crandb.r-pkg.org` und `osv.dev`. Daraus folgt:

- **Es gab keinen maschinellen Schwachstellen-Scan.** Aussagen unten zu
  Sicherheit sind Angriffsflächen-Argumente, keine bestätigten CVEs.
- "Veraltet" ist hier **nicht** gegen installierte Versionen gemessen (es gibt
  keine Lockdatei und keine Installation), sondern gegen die deklarierten
  Untergrenzen in `DESCRIPTION`. Genau das ist bei diesem Paket auch der
  eigentliche Befund: es gibt fast keine.

Für R/CRAN existiert ohnehin kein brauchbarer CVE-Feed — GHSA deckt das
Ökosystem nicht ab. Die reale CVE-Fläche eines R-Pakets liegt in den
Systembibliotheken, die über kompilierte Dependencies hereinkommen (siehe F2).

## Versionsstand

Harte Dependencies (`Imports`), keine davon mit deklarierter Untergrenze:

| Paket | Deklariert | Aktuell auf CRAN | Verlangt R |
|-------|------------|------------------|------------|
| `cachem` | (keine) | 1.1.0 | — |
| `cli` | (keine) | 3.6.6 | >= 3.4 |
| `data.table` | (keine) | 1.18.6.1 | >= 3.4.0 |
| `foreach` | (keine) | 1.5.2 | >= 2.5.0 |
| `memoise` | (keine) | 2.0.1 | — |
| `Rcpp` | (keine) | 1.1.2 | >= 3.5.0 |
| `usethis` | (keine) | 3.2.1 | **>= 4.1** |
| `stats`, `utils` | (keine) | Basis-R | — |

Relevante `Suggests`:

| Paket | Deklariert | Aktuell | Verlangt R |
|-------|------------|---------|------------|
| `testthat` | >= 3.0.0 | 3.3.2 | **>= 4.1.0** |
| `knitr` | (keine) | 1.51 | >= 3.6.0 |
| `rmarkdown` | (keine) | 2.31 | >= 3.0 |
| `rlang` | (keine) | 1.3.0 | >= 4.0.0 |
| `glue` | (keine) | 1.8.1 | **>= 4.1** |
| `future` | (keine) | 1.75.0 | >= 3.2.0 |
| `furrr` | (keine) | 0.4.0 | **>= 4.1.0** |
| `doParallel` | (keine) | 1.0.17 | >= 2.14.0 |
| `doMC` | (keine) | 1.3.8 | >= 2.14.0 |
| `yaml` | (keine) | 2.3.12 | — |
| `flir` | (keine) | 0.6.0 | **>= 4.2** |

Alle in `Suggests` gelisteten Pakete werden auch tatsächlich referenziert —
kein Karteileichen-Befund auf dieser Ebene (Einschränkung siehe F9).

---

## Funde

### F1 — `Depends: R (>= 3.5.0)` ist nicht einlösbar · **hoch**

`usethis` ist ein harter `Import` und verlangt selbst `R >= 4.1`. Auf R 3.5
bis 4.0 lässt sich `fmisc` daher gar nicht installieren; die deklarierte
Untergrenze ist seit dem Hinzufügen von `usethis` faktisch tot.

Zwei unabhängige Belege für dieselbe Grenze im eigenen Code:

- `tests/testthat/test-decorators.R:313,321,342`,
  `tests/testthat/test-smart_parallel.R:30` und `vignettes/decorators.Rmd:84,96`
  benutzen die native Pipe `|>` — gibt es erst ab R 4.1.
- `R/fmisc-package.R` bewirbt genau das als Feature ("Wrappers stack with the
  native pipe").

Die CI-Matrix deckt das nicht auf: getestet werden nur `devel`, `release` und
`oldrel-1`, also durchweg R >= 4.4. Die 3.5.0-Zusage wird nie geprüft.

**Empfehlung:** `Depends: R (>= 4.1)`.
**Breaking-Change-Risiko: niedrig.** Formal eine Verengung der Zusage, real
keine — die betroffenen R-Versionen können das Paket heute schon nicht
installieren. Die Änderung macht eine falsche Angabe korrekt, sie nimmt
niemandem etwas weg.

### F2 — `usethis` als harter Import zieht ~22 transitive Dependencies · **hoch**

Genutzt wird `usethis` an **einer** Stelle: `usethis::use_template()` in
`R/use_function_template.R:80` (dazu ein Erwähnung im Hinweistext in Zeile 48).

Dafür kommen mit `usethis` 3.2.1 herein: `cli`, `clipr`, `crayon`, `curl`,
`desc`, `fs`, `gert`, `gh`, `glue`, `jsonlite`, `lifecycle`, `purrr`,
`rappdirs`, `rlang`, `rprojroot`, `rstudioapi`, `whisker`, `withr`, `yaml`,
plus `stats`/`tools`/`utils`. Darunter `curl` (libcurl) und `gert` (libgit2) —
kompilierte Pakete mit Systembibliotheken, und damit die einzige nennenswerte
CVE-Fläche dieses Pakets. Ein Paket, dessen Kern Decorators und
Chunk-Verarbeitung sind, hängt so an einem Git- und HTTP-Stack.

`usethis` ist außerdem alleiniger Grund für die R-4.1-Grenze aus F1.

**Empfehlung:** `usethis` nach `Suggests` verschieben und
`use_function_template()` mit `requireNamespace("usethis", quietly = TRUE)`
absichern, mit klarer Fehlermeldung statt stillem Fallback.
**Breaking-Change-Risiko: mittel.** Für alle Funktionen außer
`use_function_template()` ändert sich nichts. Wer `use_function_template()`
ohne installiertes `usethis` aufruft, bekommt künftig einen Fehler statt eines
Ergebnisses — das ist der bewusst in Kauf genommene Teil. Gehört in einen
eigenen PR mit Test für den ungesicherten Pfad, nicht in diesen Report.

### F3 — `data.table` ist ein harter Import ohne jede Wirkung · **mittel**

Referenzsuche über `R/` und `src/`: `data.table` wird an genau zwei Stellen
benutzt, `R/chunking.R:180` und `R/chunking.R:220`, beide Male als

```r
if (is.data.frame(data) || data.table::is.data.table(data) || is.matrix(data))
```

Ein `data.table` **ist** ein `data.frame` (es erbt davon). `is.data.frame()`
liefert für jedes `data.table` bereits `TRUE`, `||` kürzt ab — der
`data.table`-Zweig ist unerreichbar. Er ändert das Ergebnis der Bedingung in
keinem Fall.

Dazu kommt der `@importFrom data.table`-Block in `R/fmisc-package.R` (`:=`,
`.BY`, `.EACHI`, `.GRP`, `.I`, `.N`, `.NGRP`, `.SD`, `data.table`). Das ist
unverändertes `usethis::use_data_table()`-Boilerplate; keines dieser Symbole
kommt irgendwo im Paket vor. Die Suche nach `:=`, `setDT`, `setDF`, `.SD`,
`as.data.table` und `data.table(` außerhalb dieses Blocks liefert null Treffer.

**Empfehlung:** `data.table` aus `Imports` entfernen, den `@importFrom`-Block
löschen, die beiden redundanten `|| data.table::is.data.table(data)` streichen.
Spart eine große kompilierte Dependency.
**Breaking-Change-Risiko: niedrig.** Beweisbar verhaltenserhaltend, solange die
Vererbungsregel gilt — und die gilt für jedes `data.table`.
**Achtung Zuständigkeit:** Der Schnitt selbst ist ein Code-Change und gehört zu
`dead-code` (Job 3), nicht hierher. Hier steht nur die Dependency-Konsequenz.

### F4 — `SystemRequirements: C++11` erzeugt eine R-CMD-check-NOTE · **mittel**

Seit R 4.3 quittiert `R CMD check` eine explizite C++11-Angabe mit
"Specified C++11: please drop specification unless essential". Die Angabe wird
hier nicht gebraucht: `src/rcpp_chunking.cpp` benutzt ausschließlich
C++98-Konstrukte (`<fstream>`, `<string>`, `<sstream>`, `std::min`,
`std::floor`, `static_cast`) — kein `auto`, kein `nullptr`, keine Lambdas,
keine Range-for. `src/Makevars` ist leer, `src/Makevars.win` setzt nur
`PKG_LIBS = -lpsapi`. Rcpp 1.1.2 verlangt die Deklaration ebenfalls nicht.

**Empfehlung:** Die `SystemRequirements`-Zeile ersatzlos streichen.
**Breaking-Change-Risiko: niedrig.** Der verwendete Standard wird dadurch der
Default des Compilers, der überall längst >= C++11 ist.

### F5 — GitHub Actions drei Major-Versionen hinterher · **mittel**

| Action | In Benutzung | Aktuell |
|--------|--------------|---------|
| `actions/checkout` | `v4` (beide Workflows) | `v7.0.1` |
| `actions/cache` | `v4` (`style.yaml`) | `v6.1.0` |
| `r-lib/actions/*` | `v2` | `v2.12.1` — **aktuell, nichts zu tun** |

`actions/checkout@v4` läuft auf Node20. Dessen Abkündigung ist angekündigt;
erst gibt es Deprecation-Warnungen, später bricht der Job hart ab. Das ist
kein akutes, aber ein terminiertes Problem.

**Empfehlung:** `actions/cache` auf `v6`, `actions/checkout` auf `v5` als
risikoarmer Zwischenschritt. Vor einem Sprung auf `v7` die Release-Notes von
`v5`, `v6` und `v7` lesen — in dieser Linie gab es Verhaltensänderungen rund um
`allow-unsafe-pr-checkout`, und `style.yaml` hängt an
`fetch-depth: 0` plus einem eigenen `git commit`/`git push`.
**Breaking-Change-Risiko: niedrig für `v5`, mittel für `v7`.** Betrifft nur CI,
nicht das ausgelieferte Paket.

### F6 — `cli` und `foreach` sind Imports, werden aber wie Suggests behandelt · **niedrig**

- `R/stop2.R:72`: `if (requireNamespace("cli", quietly = TRUE))` — `cli` ist ein
  harter Import, die Bedingung ist in jeder korrekten Installation `TRUE`. Die
  gesamte Fallback-Kette darunter (`glue` in Zeile 81, `rlang` in Zeile 87,
  `simple_glue`/`stop` als letzte Stufe) ist damit unerreichbar.
- `R/smart_parallel.R:121`: `foreach = requireNamespace("foreach", ...)` —
  dasselbe Muster, der "foreach nicht verfügbar"-Pfad ist tot.

Die Fallback-Logik in `stop2()` ist sorgfältig gebaut und dokumentiert
(`R/stop2.R:5-42`) — sie beschreibt ein Verhalten, das so nie eintritt. Das ist
entweder ein Dependency-Fehler (`cli` gehört nach `Suggests`) oder toter Code.
Beides gleichzeitig stehen zu lassen ist die einzige Variante, die sicher falsch
ist.

**Empfehlung:** Einmal entscheiden. `cli` nach `Suggests` zu verschieben ist die
Variante, die zur vorhandenen Fallback-Kette passt und nebenbei F2 unterstützt.
**Breaking-Change-Risiko: niedrig** in beiden Richtungen.
**Zuständigkeit:** Übergabe an `dead-code` (Job 3) und `doc-drift` (Job 2) — die
Doku in `R/stop2.R` beschreibt den nicht existierenden Fall.

### F7 — Keine Versionsuntergrenzen für Imports · **niedrig**

Einzige Untergrenze im ganzen `DESCRIPTION` ist `testthat (>= 3.0.0)`. Für die
harten Imports steht nichts, obwohl der Code nachweislich neuere APIs benutzt:

- `R/decorators.R:436` ruft `memoise::memoise(f, cache = cache)` — das
  `cache`-Argument mit `cachem`-Backend kam mit **memoise 2.0.0**. Gegen
  memoise 1.x bricht das.
- `R/decorators.R:435` ruft `cachem::cache_mem(max_n = ..., max_age = ...)` —
  braucht **cachem >= 1.0.0**.
- `R/stop2.R:73` ruft `cli::cli_abort()` — braucht **cli >= 3.0.0**.

**Empfehlung:** `memoise (>= 2.0.0)`, `cachem (>= 1.0.0)`, `cli (>= 3.0.0)`
eintragen.
**Breaking-Change-Risiko: niedrig.** Schreibt nur fest, was faktisch schon
vorausgesetzt wird.

### F8 — `Config/roxygen2/version: 8.0.0` vs. aktuell 8.1.0 · **info**

Kein eigenständiger Handlungsbedarf. Beim nächsten Doku-Change ohnehin neu
roxygenisieren und den Versionsstempel mitziehen — dann bitte in einem Commit,
der nur das tut, damit der Doku-Diff nicht mit Inhaltsänderungen verschmilzt.

### F9 — `Suggests: flir` wird nie ausgeführt · **info**

Alle `flir`-Aufrufe in `vignettes/using-fmisc.Rmd` (Zeilen 28, 56, 59, 66, 69)
stehen in `eval=FALSE`-Chunks. `tests/testthat/test-flir_rules.R` prüft nur den
Pfad aus `get_flir_rules()` und liest die YAML-Regeln mit `yaml` — `flir` selbst
wird nirgends geladen. `R/flir_rules.R` erwähnt es ausschließlich im
`\dontrun{}`-Beispiel.

`flir` verlangt R >= 4.2 und bringt über `astgrepr` eine Rust-Toolchain mit; es
wird bei jedem `R-CMD-check`-Lauf mitinstalliert, ohne je benutzt zu werden.

**Empfehlung:** Bewusst entscheiden — entweder aus `Suggests` streichen (die
Regeln sind reine YAML-Dateien in `inst/flir/rules/`, dafür braucht es `flir`
nicht) oder drin lassen und die CI-Kosten akzeptieren. Kein Fehler, aber eine
unbemerkte Entscheidung.
**Breaking-Change-Risiko: niedrig.**

---

## Vorschlag zur Reihenfolge

1. **F4 + F7** — reine `DESCRIPTION`-Änderungen, kein Verhaltensrisiko, kleiner
   Diff. Gutes erstes Paket.
2. **F1** — `Depends: R (>= 4.1)`. Einzeiler, aber eigener Commit, weil es eine
   dokumentierte Zusage ändert und in `NEWS.md` gehört.
3. **F5** — CI-Bumps, isoliert testbar, betrifft das Paket selbst nicht.
4. **F3 + F6** — an `dead-code` (Job 3) übergeben, Doku-Anteil an `doc-drift`
   (Job 2).
5. **F2** — der größte Gewinn und das größte Risiko. Eigener PR mit Test für den
   Pfad ohne `usethis`. Nicht mit etwas anderem bündeln.

## Offene Punkte für den nächsten Lauf

- Schwachstellen-Scan nachholen, sobald `osv.dev` oder ein CRAN-Mirror
  erreichbar ist. Dieser Lauf konnte das nicht leisten.
- Prüfen, ob `renv.lock` oder eine vergleichbare Feststellung gewollt ist —
  aktuell gibt es keinerlei reproduzierbaren Dependency-Stand.
