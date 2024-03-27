
# Test function that performs a full asymmetric synchronization ####

# Create sync enviornment with temp directories
sync.env <- toy_dirs()

# Get left and right paths
left <- sync.env$left
right <- sync.env$right

# Get sync status object (from compare_directories)
sync_status_date      <- compare_directories(left_path  = left,
                                             right_path = right)

sync_status_date_cont <- compare_directories(left_path  = left,
                                             right_path = right,
                                             by_content = TRUE)

sync_status_content   <- compare_directories(left_path = left,
                                             right_path  = right,
                                           by_date     = FALSE,
                                           by_content  = TRUE)

# Test full asym sync to right #############################
# update right (follower) dir to mirror left (leader) dir

# --------- Update by date only -------------------

# Non common files ####
test_that("full asym sync to right -by date only, non common files", {

  # Perform sync
  full_asym_sync_to_right(sync_status = sync_status_date)

  # Compare dirs after sync
  status_after <- compare_directories(left,
                                      right)

  expect_true(
    nrow((status_after$non_common_files)) == 0
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
test_that("full asym sync to right -by date only, non common files", {

  to_copy <- which(
    sync_status_date$common_files$is_new_left
    )

  status_after$common_files[to_copy, ] |>
    fselect(sync_status)





})
