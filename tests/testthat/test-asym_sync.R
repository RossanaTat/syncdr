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

# Additional tests ####
test_that("full_asym_sync_to_right errors for invalid arguments", {
  expect_error(full_asym_sync_to_right(left_path = "x", right_path = NULL))
  expect_error(full_asym_sync_to_right(sync_status = "not_a_status"))
  expect_error(full_asym_sync_to_right())  # all NULL
})

test_that("full_asym_sync_to_right errors for nonexistent dirs", {
  tmp <- tempfile()
  expect_error(full_asym_sync_to_right(left_path = tmp, right_path = tmp))
})

with_mocked_bindings(
  askYesNo = function(...) FALSE,
  test_that("full_asym_sync_to_right aborts when user says no", {
    e <- toy_dirs()
    expect_error(full_asym_sync_to_right(left_path = e$left,
                                         right_path = e$right,
                                         force = FALSE))
  }))

test_that("full_asym_sync_to_right respects delete_in_right = FALSE", {
  e <- copy_temp_environment()
  left  <- e$left
  right <- e$right

  full_asym_sync_to_right(left_path  = left,
                          right_path = right,
                          delete_in_right = FALSE)

  # verify right-only files still exist
  expect_true(fs::file_exists(file.path(right, "E/E1.Rds")))
})

test_that("copy without recurse places top-level files at destination top-level", {
  e <- copy_temp_environment()
  left  <- e$left
  right <- e$right

  # --- 0. Add a dummy top-level file to RIGHT so compare_directories won't error ----
  writeLines("dummy", fs::path(right, "dummy.txt"))

  # --- 1. Create top-level test files in left ---------------------------------------
  top_files <- c("top1.txt", "top2.txt")
  for (f in top_files) {
    writeLines("test", fs::path(left, f))
  }

  # --- 2. Verify they do NOT exist in right -----------------------------------------
  expect_false(any(fs::file_exists(fs::path(right, top_files))))

  # --- 3. Run sync without recurse ---------------------------------------------------
  full_asym_sync_to_right(
    left_path  = left,
    right_path = right,
    recurse    = FALSE
  )

  # --- 4. Files must exist at top-level of right ------------------------------------
  expect_true(all(fs::file_exists(fs::path(right, top_files))))

  # --- 5. Ensure NOT placed inside subfolders ---------------------------------------
  subfiles <- fs::dir_ls(right, recurse = TRUE, type = "file")
  expect_false(any(grepl("A/top", subfiles, fixed = TRUE)))
})

test_that("sync by content only", {
  e <- copy_temp_environment()
  left  <- e$left
  right <- e$right

  full_asym_sync_to_right(left_path = left,
                          right_path = right,
                          by_date = FALSE,
                          by_content = TRUE)

  # ensure modified content is synced
  status <- compare_directories(left, right, by_content = TRUE)
  expect_false(any(status$common_files$is_diff))
})

test_that("backup works to custom directory", {
  e <- copy_temp_environment()
  backup_dir <- tempfile()

  full_asym_sync_to_right(left_path = e$left,
                          right_path = e$right,
                          backup = TRUE,
                          backup_dir = backup_dir)

  expect_true(fs::dir_exists(backup_dir))
  expect_true(length(list.files(backup_dir, recursive = TRUE)) > 0)
})

test_that("update_missing_files_asym_to_right skips copy when copy_to_right = FALSE", {
  e <- copy_temp_environment()
  left  <- e$left
  right <- e$right

  # --- Create an asymmetric file (in left but not right) -----
  writeLines("hello", fs::path(left, "new_top_level.txt"))

  # Check preconditions
  status <- compare_directories(left, right, recurse = TRUE)
  expect_true(nrow(status$non_common_files) > 0)

  # --- Run with flag set to skip copying ---
  update_missing_files_asym_to_right(
    left_path      = left,
    right_path     = right,
    recurse        = TRUE,
    copy_to_right  = FALSE
  )

  # Because copy_to_right = FALSE, file should STILL be missing in right
  expect_false(fs::file_exists(fs::path(right, "new_top_level.txt")))
})


test_that("exclude_delete prevents deletion", {
  e <- copy_temp_environment()
  left  <- e$left
  right <- e$right

  update_missing_files_asym_to_right(left_path = left,
                                     right_path = right,
                                     exclude_delete = "E")

  expect_true(fs::file_exists(file.path(right, "E/E1.Rds")))
})

test_that("common_files_asym_sync_to_right works by content only", {
  e <- copy_temp_environment()
  left  <- e$left
  right <- e$right

  common_files_asym_sync_to_right(left_path = left,
                                  right_path = right,
                                  by_date = FALSE,
                                  by_content = TRUE)

  status <- compare_directories(left, right, by_content = TRUE)
  expect_false(any(status$common_files$is_diff))
})

test_that("partial update without recurse places top-level files at root", {
  e <- copy_temp_environment()
  left  <- e$left
  right <- e$right

  # -- 1. Create missing top-level files in LEFT --------------------
  top_files <- c("topA.txt", "topB.txt")
  for (f in top_files) {
    writeLines("data", fs::path(left, f))
  }

  # -- 2. Create ONE dummy file in RIGHT so compare_directories won't error ----
  writeLines("dummy", fs::path(right, "dummy.txt"))

  # -- 3. Check preconditions --------------------------------------
  expect_true(all(fs::file_exists(fs::path(left, top_files))))
  expect_false(any(fs::file_exists(fs::path(right, top_files))))

  # -- 4. Run partial update WITHOUT recurse ------------------------
  partial_update_missing_files_asym_to_right(
    left_path  = left,
    right_path = right,
    recurse    = FALSE
  )

  # -- 5. Files should appear at top-level of RIGHT -----------------
  expect_true(all(fs::file_exists(fs::path(right, top_files))))

  # -- 6. Ensure files are NOT placed inside subdirectories ---------
  subfiles <- fs::dir_ls(right, recurse = TRUE, type = "file")
  expect_false(any(grepl("/A/topA.txt|/A/topB.txt", subfiles)))
})

