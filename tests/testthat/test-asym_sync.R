
# Q: Why are the tests failing when I do NOT restart R?
# Test function that performs a full asymmetric synchronization to right ####

# ~~~~~~~~~ Update by date only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Create sync env with temp directories
sync.env <- toy_dirs()
left <- sync.env$left
right <- sync.env$right

# Get sync status object (from compare_directories)
sync_status_date      <- compare_directories(left_path  = left,
                                             right_path = right)

# Sync
full_asym_sync_to_right(sync_status = sync_status_date)


# Non common files ####
test_that("full asym sync to right -by date, non common files", {


  # Compare dirs after sync
  new_status_date <- compare_directories(left,
                                      right)

  expect_true(
    nrow((new_status_date$non_common_files)) == 0
    )

  # check copied
  fs::file_exists(path = paste0(right, "/A/A1.Rds")) |>
    expect_true()

  fs::file_exists(path = paste0(right, "/A/A2.Rds")) |>
    expect_true()

  fs::file_exists(path = paste0(right, "/A/A3.Rds")) |>
    expect_true()

  fs::file_exists(path = paste0(right, "/B/B3.Rds")) |>
    expect_true()

  # check deleted files
  fs::file_exists(path = paste0(right, "/D/D3.Rds")) |>
    expect_false()

  fs::file_exists(path = paste0(right, "/E/E1.Rds")) |>
    expect_false()

  fs::file_exists(path = paste0(right, "/E/E2.Rds")) |>
    expect_false()

  fs::file_exists(path = paste0(right, "/E/E3.Rds")) |>
    expect_false()


})

# Common files ####
test_that("full asym sync to right -by date only, common files", {

  # check files have same date status after being copied
  # to_copy <- which(
  #   sync_status_date$common_files$is_new_left
  #   )
  #
  # new_status_date <- compare_directories(left,
  #                                        right)
  #
  # res <- new_status_date$common_files[to_copy, ] |>
  #   fselect(sync_status)
  #
  # any(res != "same date") |>
  #   expect_equal(FALSE)

  # check files have some content after being copied
  to_copy_paths <- sync_status_date$common_files |>
    fsubset(is_new_left) |>
    fselect(path_left, path_right)

  compare_file_contents(to_copy_paths$path_left,
                        to_copy_paths$path_right)$is_diff |>
    any() |>
    expect_equal(FALSE)

})

# ~~~~~~~~~ Update by date and content ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# empty env first
rm(list = ls(sync.env), envir = sync.env)

# restart
sync.env <- toy_dirs()
left <- sync.env$left
right <- sync.env$right

# Get sync status object (from compare_directories)
sync_status_date_cont <- compare_directories(left_path  = left,
                                             right_path = right,
                                             by_content = TRUE)

# sync
full_asym_sync_to_right(sync_status = sync_status_date_cont,
                        by_content = TRUE)

# Non common files ####
test_that("full asym sync to right -by date & cont, non common files", {


  # Compare dirs after sync
  new_status_date_cont <- compare_directories(left,
                                              right,
                                              by_content = TRUE)

  expect_true(
    nrow((new_status_date_cont$non_common_files)) == 0
  )

  # check copied
  fs::file_exists(path = paste0(right, "/A/A1.Rds")) |>
    expect_true()

  fs::file_exists(path = paste0(right, "/A/A2.Rds")) |>
    expect_true()

  fs::file_exists(path = paste0(right, "/A/A3.Rds")) |>
    expect_true()

  fs::file_exists(path = paste0(right, "/B/B3.Rds")) |>
    expect_true()

  # check deleted files
  fs::file_exists(path = paste0(right, "/D/D3.Rds")) |>
    expect_false()

  fs::file_exists(path = paste0(right, "/E/E1.Rds")) |>
    expect_false()

  fs::file_exists(path = paste0(right, "/E/E2.Rds")) |>
    expect_false()

  fs::file_exists(path = paste0(right, "/E/E3.Rds")) |>
    expect_false()


})

# Common files ####
test_that("full asym sync to right -by date & cont, common files", {

  # check files have same content after being copied
  to_copy_paths <- sync_status_date_cont$common_files |>
    fsubset(is_new_left & is_diff) |>
    fselect(path_left, path_right)

  compare_file_contents(to_copy_paths$path_left,
                        to_copy_paths$path_right)$is_diff |>
    any() |>
    expect_equal(FALSE)
})

# ~~~~~~~~~ Update by content only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# empty env first
rm(list = ls(sync.env), envir = sync.env)

# restart
sync.env <- toy_dirs()
left <- sync.env$left
right <- sync.env$right

# Get sync status object (from compare_directories)
sync_status_cont <- compare_directories(left_path  = left,
                                        right_path = right,
                                        by_content = TRUE,
                                        by_date = FALSE)

# sync
full_asym_sync_to_right(sync_status = sync_status_cont,
                        by_content  = TRUE,
                        by_date     = FALSE)

# Non common files ####
test_that("full asym sync to right -by content only, non common files", {


  # Compare dirs after sync
  new_status_cont <- compare_directories(left,
                                              right,
                                              by_content = TRUE,
                                         by_date = FALSE)

  expect_true(
    nrow((new_status_cont$non_common_files)) == 0
  )

  # check copied
  fs::file_exists(path = paste0(right, "/A/A1.Rds")) |>
    expect_true()

  fs::file_exists(path = paste0(right, "/A/A2.Rds")) |>
    expect_true()

  fs::file_exists(path = paste0(right, "/A/A3.Rds")) |>
    expect_true()

  fs::file_exists(path = paste0(right, "/B/B3.Rds")) |>
    expect_true()

  # check deleted files
  fs::file_exists(path = paste0(right, "/D/D3.Rds")) |>
    expect_false()

  fs::file_exists(path = paste0(right, "/E/E1.Rds")) |>
    expect_false()

  fs::file_exists(path = paste0(right, "/E/E2.Rds")) |>
    expect_false()

  fs::file_exists(path = paste0(right, "/E/E3.Rds")) |>
    expect_false()


})

# Common files ####

test_that("full asym sync to right -by content only, common files", {

  # check files have same content after being copied
  to_copy_paths <- sync_status_cont$common_files |>
    fsubset(is_diff) |>
    fselect(path_left, path_right)

  compare_file_contents(to_copy_paths$path_left,
                        to_copy_paths$path_right)$is_diff |>
    any() |>
    expect_equal(FALSE)
})

# Test function that performs asymmetric synchronization to right for common files only ####

# ~~~~~~~~~ Update by date only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# empty env first
rm(list = ls(sync.env), envir = sync.env)

# restart
sync.env <- toy_dirs()
left <- sync.env$left
right <- sync.env$right

# Get sync status object (from compare_directories)
sync_status_date      <- compare_directories(left_path  = left,
                                             right_path = right)

# Sync
common_files_asym_sync_to_right(sync_status = sync_status_date)

test_that("common files asym sync to right works -by date", {

  to_copy <- sync_status_date$common_files |>
    fsubset(is_new_left) |>
    fselect(path_left,
            path_right)

  sync_status_after <- compare_directories(left,
                                           right)$common_files |>
    fsubset(path_left %in% to_copy$path_left &
              path_right %in% to_copy$path_right) |>
    fselect(sync_status)

  # check same date after sync
  all(sync_status_after == "same date") |>
    expect_equal(TRUE)

  # check same content after sync

  compare_file_contents(to_copy$path_left,
                        to_copy$path_right)$is_diff |>
    any() |>
    expect_equal(FALSE)

})


# ~~~~~~~~~ Update by date and content  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# empty env first
rm(list = ls(sync.env), envir = sync.env)

# restart
sync.env <- toy_dirs()
left     <- sync.env$left
right    <- sync.env$right

# Get sync status object (from compare_directories)
sync_status      <- compare_directories(left_path  = left,
                                        right_path = right,
                                        by_content = TRUE)

# Sync
common_files_asym_sync_to_right(sync_status = sync_status,
                                by_content  = TRUE)

test_that("common files asym sync to right works -by date & content", {

  to_copy <- sync_status$common_files |>
    fsubset(is_new_left) |>
    fsubset(is_diff) |>
    fselect(path_left,
            path_right)

  sync_status_after <- compare_directories(left,
                                           right)$common_files |>
    fsubset(path_left %in% to_copy$path_left &
              path_right %in% to_copy$path_right) |>
    fselect(sync_status)

  # check same date after sync
  all(sync_status_after == "same date") |>
    expect_equal(TRUE)

  # check same content after sync

  compare_file_contents(to_copy$path_left,
                        to_copy$path_right)$is_diff |>
    any() |>
    expect_equal(FALSE)

})

# ~~~~~~~~~ Update by content only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# empty env first
rm(list = ls(sync.env), envir = sync.env)

# restart
sync.env <- toy_dirs()
left     <- sync.env$left
right    <- sync.env$right

# Get sync status object (from compare_directories)
sync_status      <- compare_directories(left_path  = left,
                                        right_path = right,
                                        by_date    = FALSE,
                                        by_content = TRUE)

# Sync
common_files_asym_sync_to_right(sync_status = sync_status,
                                by_date     = FALSE,
                                by_content  = TRUE)

test_that("common files asym sync to right works -by content", {

  to_copy <- sync_status$common_files |>
    fsubset(is_diff) |>
    fselect(path_left,
            path_right)

  sync_status_after <- compare_directories(left,
                                           right,
                                           by_date    = FALSE,
                                           by_content = TRUE)$common_files |>
    fsubset(path_left %in% to_copy$path_left &
              path_right %in% to_copy$path_right) |>
    fselect(sync_status)

  # check same date after sync
  all(sync_status_after == "same content") |>
    expect_equal(TRUE)

})

# Test function that updates missing files only (asymmetric synchronization to right) ####

# ~~~~~~~~~ Update missing files  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# empty env first
rm(list = ls(sync.env), envir = sync.env)

# restart
sync.env <- toy_dirs()
left <- sync.env$left
right <- sync.env$right

# Get sync status object (from compare_directories)
sync_status <- compare_directories(left_path  = left,
                                   right_path = right)

# Sync
update_missing_files_asym_to_right(sync_status)

test_that("update missing file works", {

  to_copy <- sync_status$non_common_files |>
    fsubset(sync_status == "only in left")

  to_delete <- sync_status$non_common_files |>
    fsubset(sync_status == "only in right")

  sync_status_after <- compare_directories(left,
                                           right)
  sync_status_after$non_common_files |>
    nrow() |>
    expect_equal(0)

  # check delete files
  fs::file_exists(to_delete$path_right) |>
    any() |>
    expect_equal(FALSE)

  #check copied files
  # check files only in left are common files after sync,
  # and that they have same content

  copied <- sync_status_after$common_files |>
    fsubset(path_left %in% to_copy$path_left) |>
    fselect(path_left, path_right)

  compare_file_contents(copied$path_left,
                        copied$path_right)$is_diff |>
    any() |>
    expect_equal(FALSE)

})


# ~~~~~~~~~ Update missing files -partial ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# empty env first
rm(list = ls(sync.env), envir = sync.env)

# restart
sync.env <- toy_dirs()
left <- sync.env$left
right <- sync.env$right

# Get sync status object (from compare_directories)
sync_status <- compare_directories(left_path  = left,
                                   right_path = right)

# Sync
partial_update_missing_files_asym_to_right(sync_status)

test_that("update missing file works", {

  to_copy <- sync_status$non_common_files |>
    fsubset(sync_status == "only in left")

  sync_status_after <- compare_directories(left,
                                           right)

  to_keep <- sync_status$non_common_files |>
    fsubset(sync_status == "only in right")

  # check files to keep
  fs::file_exists(to_keep$path_right) |>
    any() |>
    expect_equal(TRUE)

  kept_in_right <- sync_status_after$non_common_files |>
    fselect(sync_status)

  all(kept_in_right == "only in right") |>
    expect_equal(TRUE)


  #check copied files
  # check files only in left are common files after sync,
  # and that they have same content

  copied <- sync_status_after$common_files |>
    fsubset(path_left %in% to_copy$path_left) |>
    fselect(path_left, path_right)

  compare_file_contents(copied$path_left,
                        copied$path_right)$is_diff |>
    any() |>
    expect_equal(FALSE)

})


