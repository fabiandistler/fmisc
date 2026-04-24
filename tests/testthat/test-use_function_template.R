test_that("use_function_template() creates R/my_func.R in a temp package", {
  path <- withr::local_tempdir()
  suppressMessages(usethis::create_package(path, open = FALSE, rstudio = FALSE))
  usethis::local_project(path, quiet = TRUE)
  withr::local_dir(path)
  use_function_template("my_func", open = FALSE)
  expect_true(file.exists(file.path("R", "my_func.R")))
})

test_that("use_function_template() strips .R extension from name", {
  path <- withr::local_tempdir()
  suppressMessages(usethis::create_package(path, open = FALSE, rstudio = FALSE))
  usethis::local_project(path, quiet = TRUE)
  withr::local_dir(path)
  use_function_template("my_func.R", open = FALSE)
  expect_true(file.exists(file.path("R", "my_func.R")))
  expect_false(file.exists(file.path("R", "my_func.R.R")))
})

test_that("use_function_template() aborts when name contains path separators", {
  expect_error(
    use_function_template("../../etc/bad"),
    "must be a valid R identifier"
  )
})

test_that("use_function_template() aborts when name starts with a digit", {
  expect_error(
    use_function_template("123bad"),
    "must be a valid R identifier"
  )
})

test_that("use_function_template() aborts when name contains a space", {
  expect_error(
    use_function_template("bad name"),
    "must be a valid R identifier"
  )
})
