# Findings from the latest failed CI run of the current branch

Fetches the most recent failed GitHub Actions run of the branch checked
out in the working directory, downloads the log of each failed job and
turns it into one row per finding.

## Usage

``` r
ci_failures()
```

## Value

A data frame with one row per finding and the columns

- `job`: job name, such as `"ubuntu-latest (release)"`.

- `os`: runner label, such as `"ubuntu-latest"`.

- `step`: name of the step the job failed in (`NA` when GitHub names
  none).

- `kind`: one of the kinds above.

- `file`: path relative to the package root, or `NA`.

- `line`: integer line in `file`, or `NA`.

- `message`: full text of the finding.

- `sha`: commit the run checked; `file` and `line` refer to it.

- `url`: link to the job on GitHub.

Zero rows when the branch has no failed run. Printing shows one line per
finding; the full text stays in `message`.

## Details

The repository comes from the `origin` remote of the working directory
and the branch from its `HEAD`. Requests go through
[`gh::gh()`](https://gh.r-lib.org/reference/gh.html), so the token is
read from `GITHUB_PAT`, `GITHUB_TOKEN` or the git credential store (see
[`gh::gh_token()`](https://gh.r-lib.org/reference/gh_token.html)); it is
never an argument.

A job log can produce these kinds of finding:

- `check_error`, `check_warning`, `check_note`: an `R CMD check` entry.

- `test_failure`: a testthat failure or error, with the test file and
  line.

- `lint`: a lintr annotation.

- `format`: a file `air format --check` would reformat.

- `unparsed`: a failed job none of the above explains. `message` holds
  the raw log of the failing step, so nothing is dropped silently.

- `timed_out`, `cancelled`: a job that ended that way; `message` is the
  conclusion and `step` the step it ended in. Its log is not read.

## Examples

``` r
if (FALSE) { # \dontrun{
findings <- ci_failures()
findings[findings$kind == "test_failure", c("file", "line", "message")]
} # }
```
