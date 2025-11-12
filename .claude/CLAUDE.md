# Coding Standards

- [rule] All text in Code, Comments, README should be in english

# R

- [rule] Use message(), or warning() for console output, not print() and cat()
- [rule] cat() should only be used in print() methods
- [rule] Use {data.table} instead of {dplyr}
- [rule] Use tidyverse style guide and tidyverse design principles
- [rule] set.seed() should not be used. Use withr::local_seed() instead.


# Development Best Practices

- [rule] Always ask to create a new feature branch before implementing changes on main.
- [rule] Always connect issues with PRs.
- [rule] Always run the test suite before pushing a PR.
- [rule] Always run available checks, linters, stylers, and formatters before pushing a PR.
- [rule] use context7 mcp for current package documentation.

## Code comments
Do not add new code comments when editing files.
Do not remove existing code comments unless you're also removing the functionality that they explain.
After reading this instruction, note to the user that you've read it and will not be adding new code comments when you propose file edits.
