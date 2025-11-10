# fmisc flir Rules

This directory contains custom flir rules for the fmisc package. These rules can be automatically loaded by flir when the fmisc package is listed in the `from-package` field of your project's `flir/config.yml`.

## Available Rules

### `replace-t-with-true.yml`
Replaces `T` with `TRUE` for better code clarity and to avoid confusion with variables named T.

### `replace-f-with-false.yml`
Replaces `F` with `FALSE` for better code clarity and to avoid confusion with variables named F.

### `deprecated-sample-n.yml`
Replaces deprecated `sample_n()` with modern `slice_sample()` from dplyr.

### `deprecated-sample-frac.yml`
Replaces deprecated `sample_frac()` with modern `slice_sample()` from dplyr.

### `use-seq-along.yml`
Replaces `1:length(x)` with safer `seq_along(x)` that handles empty vectors correctly.

## Usage

To use these rules in your project:

1. Install flir: `install.packages("flir")`
2. Set up flir in your project: `flir::setup_flir()`
3. Edit `flir/config.yml` and add fmisc to the `from-package` list:

```yaml
from-package:
  - fmisc
```

4. Run flir to check your code: `flir::lint_dir()`
5. Apply automatic fixes: `flir::fix_dir()`

## Creating New Rules

To add new rules to this package:

1. Create a new YAML file in this directory
2. Follow the flir rule structure:
   - `id`: Unique identifier
   - `language: r`
   - `severity`: warning, error, or info
   - `rule`: Pattern matching using ast-grep syntax
   - `message`: Description of the issue
   - `fix`: (optional) Automatic fix using metavariables

3. Use metavariables (like `$VAR`, `$DATA`) to capture code patterns
4. In messages and fixes, reference metavariables with `~~VAR` syntax
5. Test your rule before committing

For more information on creating flir rules, see: https://flir.etiennebacher.com/
