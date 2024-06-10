
# Test copy to right function ####
toy_dirs()

# Copy original paths to test functions on copies
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right

# Get sync status object (from compare_directories)
sync_status <- compare_directories(left_path  = left,
                                   right_path = right)

test_that("copy files to right works", {

  # ----------- Copy one file ---------------

  to_copy <- sync_status$non_common_files[1, "path_left"] |>
    ftransform(wo_root = gsub(left, "", path_left))

  copy_files_to_right(left_dir      = left,
                      right_dir     = right,
                      files_to_copy = to_copy)

  fs::file_exists(fs::path(right,
                           to_copy$wo_root)) |>
    expect_true()

  # --------- Copy multiple files ------------

  to_copy <- sync_status$non_common_files[1:3, "path_left"] |>
    ftransform(wo_root = gsub(left, "", path_left))

  copy_files_to_right(left_dir      = left,
                      right_dir     = right,
                      files_to_copy = to_copy)

  fs::file_exists(fs::path(right,
                           to_copy$wo_root)) |>
    all() |>
    expect_true()

})

# Test copy to left function ####

# restart
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right

# compare directories
sync_status <- compare_directories(left,
                                   right)

test_that("copy files to left works", {

  # ----------- Copy one file ---------------

  to_copy <- sync_status$non_common_files |>
    fsubset(!is.na(path_right)) |>
    fsubset(1) |>
    ftransform(wo_root = gsub(right, "", path_right))

  copy_files_to_left(left_dir      = left,
                      right_dir     = right,
                      files_to_copy = to_copy)

  fs::file_exists(fs::path(left,
                           to_copy$wo_root)) |>
    expect_true()

  # --------- Copy multiple files ------------

  to_copy <- sync_status$non_common_files |>
    fsubset(!is.na(path_right)) |>
    fsubset(1:3) |>
    ftransform(wo_root = gsub(right, "", path_right))

  copy_files_to_left(left_dir      = left,
                      right_dir     = right,
                      files_to_copy = to_copy)

  fs::file_exists(fs::path(left,
                           to_copy$wo_root)) |>
    all() |>
    expect_true()

})
