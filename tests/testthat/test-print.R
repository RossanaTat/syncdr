library(testthat)
library(syncdr)
library(withr)

test_that("remove_root removes directory prefix correctly", {
  skip_on_cran()

  tmp_dir <- local_tempdir()
  sub_file <- file.path(tmp_dir, "sub/file.txt")
  dir.create(file.path(tmp_dir, "sub"), recursive = TRUE)
  file.create(sub_file)

  out <- remove_root(tmp_dir, sub_file)
  out <- gsub("\\\\", "/", out)

  # check that result ends with "/sub/file.txt"
  expect_true(endsWith(out, "/sub/file.txt"))

  # paths outside root remain unchanged
  other_file <- file.path(local_tempdir(), "other/file.txt")
  out2 <- remove_root(tmp_dir, other_file)
  out2 <- gsub("\\\\", "/", out2)
  expect_equal(out2, gsub("\\\\", "/", other_file))
})

test_that("print.syncdr_status runs and returns object invisibly", {
  skip_on_cran()

  tmp_left <- local_tempdir()
  tmp_right <- local_tempdir()

  # minimal realistic common_files and non_common_files
  common_files <- data.frame(
    path_left = character(0),
    path_right = character(0),
    is_new_left = logical(0),
    is_new_right = logical(0),
    is_diff = logical(0),
    modification_time_left = as.POSIXct(character(0)),
    modification_time_right = as.POSIXct(character(0)),
    sync_status = character(0),
    stringsAsFactors = FALSE
  )

  non_common_files <- data.frame(
    path_left = character(0),
    path_right = character(0),
    stringsAsFactors = FALSE
  )

  sync_status <- list(
    left_path = tmp_left,
    right_path = tmp_right,
    common_files = common_files,
    non_common_files = non_common_files
  )
  class(sync_status) <- "syncdr_status"

  out <- print(sync_status)

  expect_s3_class(out, "syncdr_status")
})
