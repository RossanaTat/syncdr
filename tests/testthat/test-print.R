library(testthat)
library(syncdr)
library(withr)

# remove_root() tests
test_that("remove_root removes root prefix correctly", {
  expect_equal(
    remove_root("/home/user/base", "/home/user/base/sub/file.txt"),
    "/sub/file.txt"
  )
  expect_equal(
    remove_root("/abc", "/xyz/file.txt"),
    "/xyz/file.txt"
  )
})

# print.syncdr_status() tests
test_that("print.syncdr_status prints full synchronization summary", {
  skip_on_cran()

  e <- toy_dirs()

  # date & content mode
  s <- compare_directories(e$left, e$right, by_date = TRUE, by_content = TRUE)
  expect_snapshot(print(s))

  # content-only mode
  s <- compare_directories(e$left, e$right, by_date = FALSE, by_content = TRUE)
  expect_snapshot(print(s))

  # date-only mode
  s <- compare_directories(e$left, e$right, by_date = TRUE, by_content = FALSE)
  expect_snapshot(print(s))
})
