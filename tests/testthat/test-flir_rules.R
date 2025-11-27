test_that("get_flir_rules returns valid path", {
  rules_path <- get_flir_rules()

  expect_type(rules_path, "character")
  expect_true(dir.exists(rules_path))
})

test_that("flir rules directory contains YAML files", {
  rules_path <- get_flir_rules()
  yaml_files <- list.files(rules_path, pattern = "\\.yml$")

  expect_true(length(yaml_files) > 0)
  expect_true("replace-t-with-true.yml" %in% yaml_files)
  expect_true("replace-f-with-false.yml" %in% yaml_files)
  expect_true("deprecated-sample-n.yml" %in% yaml_files)
  expect_true("use-seq-along.yml" %in% yaml_files)
})

test_that("flir rules are valid YAML", {
  skip_if_not_installed("yaml")

  rules_path <- get_flir_rules()
  yaml_files <- list.files(rules_path, pattern = "\\.yml$", full.names = TRUE)

  for (yaml_file in yaml_files) {
    expect_error(
      yaml::read_yaml(yaml_file),
      NA, # Expect no error
      info = paste("Failed to parse:", basename(yaml_file))
    )

    rule <- yaml::read_yaml(yaml_file)

    # Check required fields
    expect_true("id" %in% names(rule), info = basename(yaml_file))
    expect_true("language" %in% names(rule), info = basename(yaml_file))
    expect_true("rule" %in% names(rule), info = basename(yaml_file))
    expect_equal(rule$language, "r", info = basename(yaml_file))
  }
})
