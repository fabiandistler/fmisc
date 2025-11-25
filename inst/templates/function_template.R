# ==============================================================================
# R Function Template - Best Practices (Tidyverse Style & Design)
# ==============================================================================
#
# Dieses Template enthält Best Practices, die NICHT automatisch von lintr/styler
# erkannt werden. Lösche, was du nicht brauchst.
#
# Quellen:
#   - https://style.tidyverse.org/
#   - https://design.tidyverse.org/
#
# ==============================================================================

# --- ROXYGEN DOCUMENTATION ----------------------------------------------------
# Tipp: Titel und Beschreibung brauchen keine @title/@description Tags
# Tipp: Backticks für Code: `na.rm`, `TRUE`, `NULL`
# Tipp: Cross-reference mit [function_name()] für Links

#' Kurzer Titel (eine Zeile, kein Punkt am Ende)
#'
#' Längere Beschreibung in einem oder mehreren Absätzen.
#' Erklärt WAS die Funktion macht, nicht WIE (das gehört in Details).
#'
#' @details
#' Technische Details zur Implementierung.
#' Verwende für Aufzählungen:
#' * Punkt 1
#' * Punkt 2
#'
#' @section Spezielle Hinweise:
#' Für längere thematische Abschnitte.
#'
#' @param x [DATEN-Argument] Beschreibung. Daten-Argumente kommen ZUERST.
#'   Mehrzeilige Beschreibung mit 2 zusätzlichen Spaces einrücken.
#' @param pattern [DESKRIPTOR-Argument] Beschreibung. Deskriptoren sind meist
#'   required und beschreiben wesentliche Details der Operation.
#' @param ... Dots zwischen Daten/Deskriptoren und Details platzieren.
#'   Zwingt User, Detail-Argumente mit vollem Namen zu benennen.
#' @param na.rm [DETAIL-Argument] Beschreibung. Details sind optional,
#'   haben Defaults und kontrollieren Feinheiten. Default: `FALSE`.
#' @param verbose [DETAIL-Argument] Beschreibung. Default: `TRUE`.
#'
#' @return Beschreibe den Rückgabetyp und die Struktur.
#'   - Bei Transformationen: "Ein [Typ] der gleichen Länge wie `x`"
#'   - Bei Side-Effects: "Gibt `x` unsichtbar zurück (für Pipe-Nutzung)"
#'
#' @export
#' @examples
#' # Einfaches Beispiel
#' my_function(1:10)
#'
#' # Mit optionalen Argumenten
#' my_function(1:10, na.rm = TRUE)
#'
#' @seealso [related_function()], [other_function()]
#' @family family_name
my_function <- function(x,
                        pattern,
                        ...,
                        na.rm = FALSE,
                        verbose = TRUE) {
  # --- ARGUMENT ORDERING CHECKLIST (design.tidyverse.org) -----------------------
  # [ ] 1. DATEN-Argumente zuerst (x, y, data) - required, bestimmen Output-Shape
  # [ ] 2. DESKRIPTOR-Argumente (pattern, by) - beschreiben die Operation
  # [ ] 3. ... (falls verwendet) - zwischen required und optional
  # [ ] 4. DETAIL-Argumente am Ende (na.rm, verbose) - optional mit Defaults
  #
  # Faustregel: Required ohne Default -> Optional mit Default
  # Wichtigkeit: Absteigend von links nach rechts
  #
  # HINWEIS: lintr's function_argument_linter() prüft nur ob Args ohne Default
  # vor Args mit Default kommen - NICHT die data/descriptor/details Kategorisierung!

  # --- ARGUMENT VALIDATION ------------------------------------------------------
  # Tipp: cli::cli_abort() statt stop() für bessere Fehlermeldungen
  # Tipp: Fehlermeldungen: "must be" wenn Ursache klar, "can't" wenn unklar
  # Tipp: Argument-Name in Backticks: `x`

  # Option A: Einfache Validierung mit stopifnot (für interne Funktionen)
  stopifnot(
    is.numeric(x),
    length(na.rm) == 1L,
    is.logical(na.rm)
  )

  # Option B: Informative Fehlermeldungen mit cli (für exportierte Funktionen)
  # Struktur: Problem-Statement + Context (x) + Hinweis (i)
  if (!is.numeric(x)) {
    cli::cli_abort(
      c(
        # Problem-Statement: "must be" wenn klar, "can't" wenn unklar
        "{.arg x} must be a numeric vector.",
        # Context mit x-Bullet
        "x" = "You provided a {.cls {class(x)}} vector.",
        # Optional: Hinweis mit i-Bullet
        "i" = "Convert with {.fn as.numeric} if needed."
      ),
      call = rlang::caller_env()
    )
  }

  # Option C: rlang Type-Checks (kompakt)
  rlang::check_required(x)
  x <- rlang::arg_match(x, c("option1", "option2"))

  # --- DOTS HANDLING ------------------------------------------------------------
  # Wenn ... verwendet wird: IMMER prüfen ob alle dots verwendet wurden
  # Das verhindert stille Fehler bei Tippfehlern in Argument-Namen

  rlang::check_dots_used()
  # ODER für Funktionen die ... gar nicht verwenden sollen:
  rlang::check_dots_empty()
  # ODER wenn ... nur unbenannte Werte haben soll (wie sum()):
  rlang::check_dots_unnamed()

  # --- NULL-PATTERN FÜR OPTIONALE ARGUMENTE -------------------------------------
  # Verwende NULL als Default für komplexe Berechnungen
  # NICHT: function(x, n = nrow(x)) - das ist ein "magical default"
  # BESSER: function(x, n = NULL) mit Berechnung im Body
  # %||% ist der Null-Coalescing-Operator aus rlang

  # Komplexe Default-Berechnung
  computed_default <- na.rm %||% determine_na_handling(x)

  # VERMEIDE "magical defaults" - Defaults die anders funktionieren wenn
  # explizit übergeben vs. weggelassen:
  # - Keine Defaults die von internen Variablen abhängen
  # - Kein missing() verwenden
  # - Keine unexportierten Funktionen als Default

  # --- PROGRESS/MESSAGES FÜR WICHTIGE DEFAULTS ----------------------------------
  # Wenn ein Default "geraten" wird, den User informieren
  # Wichtig bei Deskriptor-Argumenten mit Defaults (z.B. by in left_join)

  if (verbose && is.null(pattern)) {
    pattern <- detect_pattern(x)
    cli::cli_inform(
      "Using detected pattern: {.val {pattern}}"
    )
  }

  # --- FUNCTION BODY ------------------------------------------------------------
  # Tipp: Comments erklären WARUM, nicht WAS
  # Tipp: return() nur für Early Returns, nicht am Ende

  # Early return Beispiel - hier ist return() angebracht
  if (length(x) == 0L) {
    return(x)
  }

  # Normale Berechnung
  result <- x + 1

  # Letzter Ausdruck wird automatisch zurückgegeben - KEIN return() nötig
  result
}

# --- SIDE-EFFECT FUNCTIONS ----------------------------------------------------
# Funktionen die hauptsächlich Side-Effects haben (print, plot, write)
# sollten das erste Argument unsichtbar zurückgeben für Pipe-Nutzung

#' Print method for my_class
#' @export
print.my_class <- function(x, ...) {
  cat("My Class Object\n")
  cat("Value:", x$value, "\n")
  invisible(x)
}

# --- OPTIONS OBJECT PATTERN ---------------------------------------------------
# Bei vielen Detail-Argumenten: Auslagern in separates Options-Objekt
# Beispiele: glm.control(), readr::locale(), tune::control_resamples()

#' Create options for my_function
#'
#' @param opt1 Beschreibung.
#' @param opt2 Beschreibung.
#' @return A `my_function_opts` object.
#' @export
my_function_opts <- function(opt1 = 1, opt2 = 2) {
  structure(
    list(
      opt1 = opt1,
      opt2 = opt2
    ),
    class = "mypackage_my_function_opts"
  )
}

# Nutzung in Hauptfunktion:
# my_function <- function(x, ..., opts = my_function_opts()) {
#   if (!inherits(opts, "mypackage_my_function_opts")) {
#     cli::cli_abort("{.arg opts} must be created by {.fn my_function_opts}.")
#   }
# }

# --- ERROR CONSTRUCTOR PATTERN ------------------------------------------------
# Für wiederholte Fehler: Custom Error Classes für besseres Testing/Handling
# Ermöglicht: expect_error(..., class = "mypackage_error_not_found")

#' @noRd
stop_not_found <- function(path, call = rlang::caller_env()) {
  cli::cli_abort(
    c("File not found: {.path {path}}"),
    class = "mypackage_error_not_found",
    path = path,
    call = call
  )
}

# --- INTERNE/PRIVATE FUNKTIONEN -----------------------------------------------
# Dokumentiere mit @noRd um .Rd Generierung zu verhindern

#' Helper function for internal use
#'
#' @param x Input.
#' @return Processed input.
#' @noRd
.my_helper <- function(x) {
  x
}

# ==============================================================================
# DESIGN PRINCIPLES CHECKLIST
# ==============================================================================
#
# ARGUMENT DESIGN (NICHT von lintr geprüft):
# [ ] Argument-Reihenfolge: data -> descriptors -> ... -> details
# [ ] Required Args haben KEINEN Default
# [ ] Optional Args haben einen Default
# [ ] Defaults sind kurz und verständlich (nicht: x = complex_calculation())
# [ ] NULL für komplexe Default-Berechnungen im Body
# [ ] Keine "magischen" Defaults (Default != explizit übergebener Wert)
# [ ] Keine missing() Verwendung
# [ ] Keine internen Variablen in Defaults
# [ ] Wichtige Auto-Defaults werden dem User mitgeteilt
#
# ERROR HANDLING (NICHT von lintr geprüft):
# [ ] cli::cli_abort() statt stop()
# [ ] Fehlermeldungen: Problem + Kontext (x) + ggf. Hinweis (i)
# [ ] "must be" wenn Ursache klar, "can't" wenn unklar
# [ ] Error-Konstruktoren für wiederholte Fehler
# [ ] call = rlang::caller_env() für korrekte Fehlerlokalisierung
#
# DOTS HANDLING (NICHT von lintr geprüft):
# [ ] ... zwischen data/descriptors und details
# [ ] rlang::check_dots_used() oder check_dots_empty()
#
# FUNCTION OUTPUT (NICHT von lintr geprüft):
# [ ] return() nur für Early Returns
# [ ] Side-Effect-Funktionen: invisible(x) zurückgeben
# [ ] Output-Shape folgt Input-Shape (für Pipe-Kompatibilität)
#
# DOCUMENTATION (teilweise von lintr geprüft):
# [ ] Titel: Eine Zeile, kein Punkt
# [ ] @param: Typ und Bedeutung, Default erwähnen wenn wichtig
# [ ] @return: Typ und Struktur
# [ ] @examples: Lauffähige Beispiele
# [ ] Backticks für Code in Dokumentation
# [ ] @inheritParams für geteilte Parameter
#
# ==============================================================================
# WAS LINTR BEREITS PRÜFT (hier nicht im Template):
# ==============================================================================
# - Spacing um Operatoren und nach Kommas
# - Zeilenlänge (80 chars)
# - <- statt = für Assignment
# - Einrückung (2 spaces)
# - Keine ; am Zeilenende
# - TRUE/FALSE statt T/F
# - Keine trailing whitespace
# - function_argument_linter: Args ohne Default vor Args mit Default
#   (aber NICHT die data/descriptor/details Kategorisierung!)
#
# ==============================================================================
