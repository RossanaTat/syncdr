# tests/testthat/test-zzz.R

library(testthat)

test_that(".onLoad sets default options correctly", {
  skip_on_cran()

  # load withr inside test to avoid R version warning
  library(withr)

  # backup current options
  old_opts <- options()

  # remove syncdr options to simulate fresh load
  options(syncdr.verbose = NULL, syncdr.save_format = NULL)

  # manually call .onLoad using triple colon
  syncdr:::.onLoad(libname = tempdir(), pkgname = "syncdr")

  # check that options are set
  expect_equal(getOption("syncdr.verbose"), FALSE)
  expect_equal(getOption("syncdr.save_format"), "fst")

  # restore original options
  options(old_opts)
})
