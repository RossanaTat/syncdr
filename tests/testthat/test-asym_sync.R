# 1. | Full asymmetric synchronization to right ####

## --- Update by date only ----

# Create sync env with temp directories
e = toy_dirs()

# Copy temp env
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right

# Get sync status object (from compare_directories)
sync_status_date      <- compare_directories(left_path  = left,
                                             right_path = right)

# Sync
full_asym_sync_to_right(sync_status = sync_status_date)


### Non common files ####
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

### Common files ####
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

### Backup option ####

# With default backup directory
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right

right_files <- list.files(right,
                         recursive = TRUE)

full_asym_sync_to_right(left_path  = left,
                        right_path = right,
                        backup     = TRUE)


test_that("full synchronization -backup option works", {

  # test backup directory is in tempdir
  # tempdir_files <- list.files(tempdir())
  #
  # lapply(tempdir_files,
  #        function(x) grepl("backup_directory", x)) |>
  #   any() |>
  #   expect_equal(TRUE)
  #
  # # check content matches original directory
  # list.files(tempdir(), recursive = TRUE)

  backup_dir <- file.path(tempdir(), "backup_directory")
  backup_files <- list.files(backup_dir,
                             recursive = TRUE)
  # remove prefix
  backup_files <-sub("copy_right_\\d+/", "", backup_files)

  # check backup directory exists
  fs::dir_exists(backup_dir) |>
    expect_true()

  # check files in backup dir matches original right dir
  sort(backup_files) |>
    expect_equal(sort(right_files))

})

## --- Update by date and content ----

# restart
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right

# Get sync status object (from compare_directories)
sync_status_date_cont <- compare_directories(left_path  = left,
                                             right_path = right,
                                             by_content = TRUE)

# sync
full_asym_sync_to_right(sync_status = sync_status_date_cont,
                        by_content = TRUE)

### Non common files ####
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

### Common files ####
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

## --- Update by content only ----

# restart
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right


# Get sync status object (from compare_directories)
sync_status_cont <- compare_directories(left_path  = left,
                                        right_path = right,
                                        by_content = TRUE,
                                        by_date = FALSE)

# sync
full_asym_sync_to_right(sync_status = sync_status_cont,
                        by_content  = TRUE,
                        by_date     = FALSE)

### Non common files ####
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

### Common files ####

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

# 2. | Asymmetric synchronization to right for common files only ####

# ~~~~~~~~~ Update by date only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# restart
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right


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


  # check same content after sync

  compare_file_contents(to_copy$path_left,
                        to_copy$path_right)$is_diff |>
    any() |>
    expect_equal(FALSE)

})

### Backup option ####

# #With default backup directory
# syncdr_temp <- copy_temp_environment()
# left  <- syncdr_temp$left
# right <- syncdr_temp$right
#
# right_files <- list.files(right,
#                           recursive = TRUE)
#
# # clean backup directory
# fs::file_delete(list.files(backup_dir,
#                        recursive = TRUE))
#
# common_files_asym_sync_to_right(left_path  = left,
#                                 right_path = right,
#                                 backup     = TRUE)
#
#
# test_that("common files synchronization -backup option works", {
#
#   backup_dir <- file.path(tempdir(), "backup_directory")
#   backup_files <- list.files(backup_dir,
#                              recursive = TRUE)
#   # remove prefix
#   backup_files <-sub("copy_right_\\d+/", "", backup_files)
#
#   # check backup directory exists
#   fs::dir_exists(backup_dir) |>
#     expect_true()
#
#   # check files in backup dir matches original right dir
#   sort(backup_files) |>
#     expect_equal(sort(right_files))
#
# })

# ~~~~~~~~~ Update by date and content  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# restart
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right


# Get sync status object (from compare_directories)
sync_status      <- compare_directories(left_path  = left,
                                        right_path = right,
                                        by_content = TRUE)

# Sync
common_files_asym_sync_to_right(sync_status = sync_status)

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


  # check same content after sync

  compare_file_contents(to_copy$path_left,
                        to_copy$path_right)$is_diff |>
    any() |>
    expect_equal(FALSE)

})

# ~~~~~~~~~ Update by content only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# restart
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right


# Get sync status object (from compare_directories)
sync_status      <- compare_directories(left_path  = left,
                                        right_path = right,
                                        by_date    = FALSE,
                                        by_content = TRUE)

# Sync
common_files_asym_sync_to_right(sync_status = sync_status)

test_that("common files asym sync to right works -by content", {

  # check that common files that are different are copied to right

  sync_status_after <- compare_directories(left_path  = left,
                                           right_path = right,
                                           by_date    = FALSE,
                                           by_content = TRUE)

  sync_status_after$is_diff |>
    any() |> #are some values TRUE?
    expect_equal(FALSE)

  to_copy <- sync_status$common_files |>
    fsubset(is_diff) |>
    fselect(path_left,
            path_right)

  sync_status_after$common_files |>
    fsubset(path_left %in% to_copy$path_left) |>
    fselect(is_diff) |>
    any() |>
    expect_equal(FALSE)


})

# 3. | Missing files only (asymmetric synchronization to right) ####

# ~~~~~~~~~ Update missing files  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# restart
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right


# Get sync status object (from compare_directories)
sync_status <- compare_directories(left_path  = left,
                                   right_path = right)

# Sync
update_missing_files_asym_to_right(sync_status = sync_status)

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

# restart
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right

# Get sync status object (from compare_directories)
sync_status <- compare_directories(left_path  = left,
                                   right_path = right)

# Sync
partial_update_missing_files_asym_to_right(sync_status = sync_status)

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


