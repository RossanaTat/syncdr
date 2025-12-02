test_that("rs_theme runs without error and returns a list", {
  skip_on_cran()  # skip on CRAN

  # call internal function via triple colon
  theme <- syncdr:::rs_theme()

  # check that it returns a list
  expect_type(theme, "list")

  # check it has expected names
  expect_true(all(c("editor", "global", "dark", "foreground", "background") %in% names(theme)))
})
