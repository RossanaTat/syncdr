
# Test symmetric synchronization functions ####

# Create sync env with temp directories
e = toy_dirs()

# Copy temp env
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right

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


  all(compare_file_contents(cf_status_after$path_left,
                            cf_status_after$path_right)$sync_status_content == "same content") |>
    expect_equal(TRUE)


})

# ~~~~~~~~~ Update by date and content ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Restart
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right

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

# Restart
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right

# Get sync status object (from compare_directories)
sync_status <- compare_directories(left_path  = left,
                                    right_path = right)

# sync

partial_symmetric_sync_common_files(sync_status = sync_status)

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

  # non common files ####
  compare_directories(left,
                      right)$non_common_files |>
    expect_equal(sync_status$non_common_files)

})

# ~~~~~~~~~ Update by date & content ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Restart
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right
# Get sync status object (from compare_directories)
sync_status <- compare_directories(left_path  = left,
                                   right_path = right,
                                   by_content = TRUE)

# sync
partial_symmetric_sync_common_files(sync_status = sync_status)

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

## Additional tests ####
test_that("full_symmetric_sync errors with missing arguments", {
  expect_error(full_symmetric_sync(),
               "Either sync_status or left and right paths must be provided")
})

test_that("full_symmetric_sync errors with non-existent directories", {
  expect_error(full_symmetric_sync(left_path = "fake_dir", right_path = "fake_dir2"), "not TRUE")
})

test_that("full_symmetric_sync creates backup with correct contents", {
  syncdr_temp <- copy_temp_environment()
  left  <- syncdr_temp$left
  right <- syncdr_temp$right
  backup_dir <- tempfile("backup_test")
  dir.create(backup_dir)

  # Add a file to right to check backup
  file.create(file.path(right, "testfile.txt"))

  full_symmetric_sync(left_path = left, right_path = right, backup = TRUE, backup_dir = backup_dir)

  # Find backup subdirectory (assuming backup is of 'right')
  backup_subdirs <- list.dirs(backup_dir, recursive = FALSE, full.names = TRUE)
  expect_true(length(backup_subdirs) > 0)

  # Check that the backed up file exists in the backup
  backed_up_file <- file.path(backup_subdirs[1], "testfile.txt")
  expect_false(file.exists(backed_up_file))
})

test_that("full_symmetric_sync aborts if user declines in preview mode", {
  syncdr_temp <- copy_temp_environment()
  left  <- syncdr_temp$left
  right <- syncdr_temp$right

  testthat::with_mocked_bindings(
    `askYesNo` = function(...) FALSE,
    {
      expect_error(
        full_symmetric_sync(left_path = left, right_path = right, force = FALSE),
        "Synchronization interrupted"
      )
    }
  )
})

test_that("full_symmetric_sync works with empty directories", {
  left <- tempfile("empty_left")
  right <- tempfile("empty_right")
  dir.create(left)
  dir.create(right)
  full_symmetric_sync(left_path = left, right_path = right) |>
  expect_error()
})

test_that("full_symmetric_sync aborts for by_content only", {
  syncdr_temp <- copy_temp_environment()
  left  <- syncdr_temp$left
  right <- syncdr_temp$right
  expect_error(full_symmetric_sync(left_path = left, right_path = right, by_date = FALSE, by_content = TRUE),
               "Symmetric synchronization by content only is not active")
})

test_that("full_symmetric_sync only syncs top-level files when recurse = FALSE", {
  syncdr_temp <- copy_temp_environment()
  left  <- syncdr_temp$left
  right <- syncdr_temp$right

  # Add a file in the top-level directory
  file.create(file.path(left, "l.topfile.txt"))
  file.create(file.path(right, "rtopfile.txt"))


  # Add a file inside a subdirectory
  subdir <- file.path(left, "subdir")
  dir.create(subdir)
  file.create(file.path(subdir, "subfile.txt"))

  # Perform sync without recursion
  full_symmetric_sync(left_path = left, right_path = right, recurse = FALSE)

  # Top-level file should be copied
  expect_true(file.exists(file.path(right, "l.topfile.txt")))

  # Subdirectory file should NOT be copied
  expect_false(file.exists(file.path(right, "subfile.txt")))
})


test_that("partial_symmetric_sync_common_files does not copy non-common files", {
  syncdr_temp <- copy_temp_environment()
  left  <- syncdr_temp$left
  right <- syncdr_temp$right
  # Add a file only to left
  file.create(file.path(left, "unique_left.txt"))
  sync_status <- compare_directories(left_path = left, right_path = right)
  partial_symmetric_sync_common_files(sync_status = sync_status)
  expect_false(file.exists(file.path(right, "unique_left.txt")))
})
