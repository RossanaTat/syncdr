
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

# Additional tests####
test_that("copy_files_to_right works when recurse = FALSE", {
  env <- copy_temp_environment()
  left <- env$left
  right <- env$right
  sync_status <- compare_directories(left, right)

  to_copy <- sync_status$non_common_files[1, ] |>
    ftransform(path_from = path_left)

  copy_files_to_right(
    left_dir = left,
    right_dir = right,
    files_to_copy = to_copy,
    recurse = FALSE
  )

  expected <- fs::path(right, fs::path_file(to_copy$path_left))
  expect_true(fs::file_exists(expected))
})

test_that("copy_files_to_right handles empty files_to_copy", {
  env <- copy_temp_environment()
  left <- env$left
  right <- env$right

  empty_df <- data.table::data.table(
    path_left = character()
  )

  expect_silent(
    copy_files_to_right(left, right, empty_df)
  )
})

test_that("copy_files_to_right creates needed subdirectories", {
  env <- copy_temp_environment()
  left  <- env$left
  right <- fs::path_temp() |> fs::path("nonexistent_dir")

  sync_status <- compare_directories(left, env$right)

  to_copy <- sync_status$non_common_files[1, ] |>
    ftransform(wo_root = gsub(left, "", path_left))

  copy_files_to_right(left, right, to_copy)

  expect_true(fs::dir_exists(fs::path_dir(fs::path(right, to_copy$wo_root))))
})

test_that("copy_files_to_right overwrites existing files", {
  env <- copy_temp_environment()
  left <- env$left
  right <- env$right

  src     <- fs::path(left, "file.txt")
  dest    <- fs::path(right, "file.txt")

  writeLines("original", src)
  writeLines("old", dest)

  df <- data.table::data.table(path_left = src)

  copy_files_to_right(left, right, df)

  expect_equal(readLines(dest), "original")
})

test_that("copy_files_to_right errors when left_dir does not exist", {
  env <- copy_temp_environment()
  right <- env$right

  df <- data.table::data.table(path_left = "missing.txt")

  expect_error(
    copy_files_to_right("idontexist", right, df),
    regexp = ".*" # adjust based on actual error
  )
})

test_that("copy_files_to_right errors if path_from does not exist", {
  env <- copy_temp_environment()
  left <- env$left
  right <- env$right

  df <- data.table::data.table(path_left = fs::path(left, "no_such_file"))

  expect_error(
    copy_files_to_right(left, right, df)
  )
})

test_that("copy_files_to_right returns invisible(TRUE)", {
  env <- copy_temp_environment()
  left <- env$left
  right <- env$right
  sync_status <- compare_directories(left, right)

  to_copy <- sync_status$non_common_files[1, ]

  output <- copy_files_to_right(left, right, to_copy)

  expect_true(output)
})

test_that("copy_files_to_right handles spaces and special chars", {
  env <- copy_temp_environment()
  left <- env$left
  right <- env$right

  special <- fs::path(left, "my file @#$%.txt")
  writeLines("data", special)

  df <- data.table::data.table(path_left = special)

  copy_files_to_right(left, right, df)

  expect_true(fs::file_exists(fs::path(right, "my file @#$%.txt")))
})


