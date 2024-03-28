# Testing auxiliary functions

sync.env <- toy_dirs()
left <- sync.env$left
right <- sync.env$right

# Get sync status object (from compare_directories)
sync_status_date      <- compare_directories(left_path  = left,
                                             right_path = right)

sync_status_date_cont <- compare_directories(left_path  = left,
                                             right_path = right,
                                             by_content = TRUE)

sync_status_content   <- compare_directories(left_path  = left,
                                             right_path = right,
                                             by_date    = FALSE,
                                             by_content = TRUE)

# Test filter common files ####

# ~~~~~~~~~ filter by date only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

test_that("filter common files works -by date", {

  # ----------- left dir --------------------------

  to_filter <- sync_status_date$common_files |>
    fsubset(is_new_left) |>
    fselect(path_left, path_right)

  res_left <- filter_common_files(sync_status_date$common_files,
                                  dir = "left") |>
    fselect(path_left, path_right)

  expect_equal(to_filter,
               res_left)


  # ---------- right dir ---------------------------
  to_filter <- sync_status_date$common_files |>
    fsubset(is_new_right) |>
    fselect(path_left, path_right)

  res_right <- filter_common_files(sync_status_date$common_files,
                                  dir = "right") |>
    fselect(path_left, path_right)

  expect_equal(to_filter,
               res_right)

  # ---------- both dir ---------------------------

  to_filter <- sync_status_date$common_files |>
    fsubset(is_new_right | is_new_left) |>
    fselect(path_left, path_right)

  res_all <- filter_common_files(sync_status_date$common_files,
                                   dir = "all") |>
    fselect(path_left, path_right)

  expect_equal(to_filter,
               res_all)

})

# ~~~~~~~~~ filter by date and content ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

test_that("filter common files works -by date&cont", {

  # ----------- left dir --------------------------
  to_filter <- sync_status_date_cont$common_files |>
    fsubset(is_new_left) |>
    fsubset(is_diff) |>
    fselect(path_left, path_right)

  res_left <- filter_common_files(sync_status_date_cont$common_files,
                                  dir = "left",
                                  by_content = TRUE) |>
    fselect(path_left, path_right)

  expect_equal(to_filter,
               res_left)

  # ---------- right dir ---------------------------
  to_filter <- sync_status_date_cont$common_files |>
    fsubset(is_new_right) |>
    fsubset(is_diff) |>
    fselect(path_left, path_right)

  res_right <- filter_common_files(sync_status_date_cont$common_files,
                                   dir = "right",
                                   by_content = TRUE) |>
    fselect(path_left, path_right)

  expect_equal(to_filter,
               res_right)

  # ---------- both dir ---------------------------

  to_filter <- sync_status_date_cont$common_files |>
    fsubset(is_new_right | is_new_left) |>
    fselect(path_left, path_right)

  res_all <- filter_common_files(sync_status_date_cont$common_files,
                                 dir = "all",
                                 by_content = TRUE) |>
    fselect(path_left, path_right)

  expect_equal(to_filter,
               res_all)

})

# ~~~~~~~~~ filter by content only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

test_that("filter common files works -by cont", {

  to_filter <- sync_status_content$common_files |>
      fsubset(is_diff) |>
      fselect(path_left, path_right)

  res_left <- filter_common_files(sync_status_content$common_files,
                                  dir = "left",
                                  by_date = FALSE,
                                  by_content = TRUE) |>
    fselect(path_left, path_right)

  expect_equal(to_filter,
               res_left)


  res_right <- filter_common_files(sync_status_content$common_files,
                                   dir = "right",
                                   by_date = FALSE,
                                   by_content = TRUE) |>
    fselect(path_left, path_right)

  expect_equal(res_left,
               res_right)

  res_all <- filter_common_files(sync_status_content$common_files,
                                 dir = "all",
                                 by_date = FALSE,
                                 by_content = TRUE) |>
    fselect(path_left, path_right)

  expect_equal(res_right,
               res_all)

})
