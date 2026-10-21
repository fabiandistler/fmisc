# printing shows one line per finding

    Code
      print(findings)
    Output
      7 findings from commit 0123456
      unparsed      -                        ##[group]Run if FILES_TO_COMMIT=($(git diff-index --name-... [style]
      lint          R/chunking.R:186         [return_linter] Use implicit return behavior; explicit re... [r-lint]
      lint          R/chunking.R:239         [assignment_linter] Replace <<- by assigning to a specifi... [r-lint]
      lint          R/chunking.R:256         [return_linter] Use implicit return behavior; explicit re... [r-lint]
      lint          R/chunking.R:258         [return_linter] Use implicit return behavior; explicit re... [r-lint]
      lint          R/chunking.R:356         [return_linter] Use implicit return behavior; explicit re... [r-lint]
      lint          R/stop2.R:140            [return_linter] Use implicit return behavior; explicit re... [r-lint]
      Full text of each finding is in `$message`.

---

    Code
      print(findings[0, ])
    Output
      No findings: the branch has no failed CI run.

