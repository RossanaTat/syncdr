test_that("toy_dirs creates syncdr.env", {

  toy_dirs()

  # Check if the environment exists
  expect_true(exists("syncdr.env",
                     envir = .GlobalEnv))

  # Check paths exist
  expect_true(exists("left",
                     envir = syncdr.env))
  expect_true(exists("right",
                     envir = syncdr.env))

  left <- syncdr.env$left
  right <- syncdr.env$right

  # Check if the directories exist
  expect_true(fs::dir_exists(left))
  expect_true(fs::dir_exists(right))

  # Check dirs are not empty
  expect_true(length(dir_ls(left,
                            recurse = TRUE)) > 0)
  expect_true(length(dir_ls(right,
                            recurse = TRUE)) > 0)
})
