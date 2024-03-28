
# Test symmetric synchronization functions ####

# Create sync env with temp directories
sync.env <- toy_dirs()
left <- sync.env$left
right <- sync.env$right

# Get sync status object (from compare_directories)
sync_status_date      <- compare_directories(left_path  = left,
                                             right_path = right)

# ~~~~~~~~~ Update by date only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

full_symmetric_sync(sync_status = sync_status_date)

test_that("full symm sync works -by date", {

  # common files ####
  to_copy <- sync_status_date$common_files |>
    fsubset(is_new_left | is_new_right)

  sync_status_after <- compare_directories(left,
                                           right)

  # non common files ####
  sync_status_after$non_common_files |>
    nrow() |>
    expect_equal(0)

  cf_status_after <- sync_status_after$common_files |>
    fselect(path_left, path_right, sync_status)

  all(cf_status_after$sync_status == "same date") |>
    expect_equal(TRUE)

  all(compare_file_contents(cf_status_after$path_left,
                            cf_status_after$path_right)$sync_status_content == "same content") |>
    expect_equal(TRUE)


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
full_symmetric_sync(sync_status = sync_status_date_cont)

test_that("full symm sync works -by date&cont", {

  # common files ####
  # to_copy <- sync_status_date_cont$common_files |>
  #   fsubset((is_new_left | is_new_right) & is_diff)

  sync_status_after <- compare_directories(left,
                                           right)
  # non common files ####
  sync_status_after$non_common_files |>
    nrow() |>
    expect_equal(0)

  cf_status_after <- sync_status_after$common_files |>
    fselect(path_left, path_right, sync_status)

  all(cf_status_after$sync_status == "same date") |>
    expect_equal(TRUE)

  all(compare_file_contents(cf_status_after$path_left,
                            cf_status_after$path_right)$sync_status_content == "same content") |>
    expect_equal(TRUE)

})

# ~~~~~~~~~ Update content only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#ADD TEST HERE


# Testing partial symmetric sync function ####

# ~~~~~~~~~ Update by date only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

# sync

partial_symmetric_sync_common_files(sync_status)

test_that("partial symm sync works -by date", {

  # common files ####
  to_copy <- sync_status$common_files |>
    fsubset(is_new_left | is_new_right)

  sync_status_after <- compare_directories(left,
                      right)$common_files |>
    fsubset(path_left %in% to_copy$path_left &
              path_right %in% to_copy$path_right)

  all(compare_file_contents(sync_status_after$path_left,
                        sync_status_after$path_right)$is_diff == FALSE) |>
    expect_equal(TRUE)

  all(sync_status_after$sync_status == "same date") |>
    expect_equal(TRUE)

  # non common files ####
  compare_directories(left,
                      right)$non_common_files |>
    expect_equal(sync_status$non_common_files)

})

# ~~~~~~~~~ Update by date & content ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# empty env first
rm(list = ls(sync.env), envir = sync.env)

# restart
sync.env <- toy_dirs()
left <- sync.env$left
right <- sync.env$right

# Get sync status object (from compare_directories)
sync_status <- compare_directories(left_path  = left,
                                   right_path = right,
                                   by_content = TRUE)

# sync
partial_symmetric_sync_common_files(sync_status,
                                    by_content = TRUE)

test_that("partial sym sync works -by date & cont", {

  to_copy <- sync_status$common_files |>
    fsubset(is_new_left | is_new_right) |>
    fsubset(is_diff)

  sync_status_after <- compare_directories(left,
                                           right)$common_files |>
    fsubset(path_left %in% to_copy$path_left &
              path_right %in% to_copy$path_right)


  all(compare_file_contents(sync_status_after$path_left,
                            sync_status_after$path_right)$sync_status == "same content") |>
    expect_equal(TRUE)

})


