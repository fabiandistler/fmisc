# Contract: `use_function_template()`

**Type**: Public R function (exported)  
**Package**: fmisc

## Signature

```r
use_function_template(name, open = interactive())
```

## Arguments

| Argument | Type | Default | Description |
|---|---|---|---|
| `name` | character(1) | required | Name for the new R file, without or with `.R` extension |
| `open` | logical(1) | `interactive()` | Whether to open the created file for editing |

## Return Value

Invisibly returns the result of `usethis::use_template()` (a logical scalar — `TRUE` if the file was written, `FALSE` otherwise).

## Side Effects

- Creates `R/<name>.R` in the active R package project
- Emits a success message and usage hints via `cli`
- Opens the file for editing when `open = TRUE`

## Errors

| Condition | Error message |
|---|---|
| Target file already exists | "File `R/<name>.R` already exists." |

All other error conditions (no active project, missing R/ dir) are delegated to `usethis::use_template()`.

## Behavior Notes

- A trailing `.R` in `name` is stripped before constructing the file path
- `usethis::use_template()` requires an active usethis project context; the function must be called from within an R package directory
