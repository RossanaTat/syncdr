
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
  # create an isolated environment and files explicitly so tests are deterministic
  env <- copy_temp_environment()
  left <- env$left
  right <- env$right

  # single file
  f1 <- fs::path(left, "one.txt")
  writeLines("one", f1)
  df1 <- data.table::data.table(path_left = f1)

  copy_files_to_right(left_dir = left, right_dir = right, files_to_copy = df1)
  expect_true(fs::file_exists(fs::path(right, fs::path_rel(f1, start = left))))

  # multiple files including nested
  fs::dir_create(fs::path(left, "sub"))
  f2 <- fs::path(left, "sub", "two.txt")
  writeLines("two", f2)
  df2 <- data.table::data.table(path_left = c(f1, f2))

  copy_files_to_right(left_dir = left, right_dir = right, files_to_copy = df2)
  rels <- fs::path_rel(df2$path_left, start = left)
  expect_true(all(fs::file_exists(fs::path(right, rels))))

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
  # create explicit files in right and copy them to left
  env <- copy_temp_environment()
  left <- env$left
  right <- env$right

  r1 <- fs::path(right, "r_one.txt")
  writeLines("r1", r1)
  df1 <- data.table::data.table(path_right = r1)

  copy_files_to_left(left_dir = left, right_dir = right, files_to_copy = df1)
  expect_true(fs::file_exists(fs::path(left, fs::path_rel(r1, start = right))))

  # multiple files including nested
  fs::dir_create(fs::path(right, "sub"))
  r2 <- fs::path(right, "sub", "r_two.txt")
  writeLines("r2", r2)
  df2 <- data.table::data.table(path_right = c(r1, r2))

  copy_files_to_left(left_dir = left, right_dir = right, files_to_copy = df2)
  rels <- fs::path_rel(df2$path_right, start = right)
  expect_true(all(fs::file_exists(fs::path(left, rels))))

})

# Additional tests####
test_that("copy_files_to_right works when recurse = FALSE", {
  env <- copy_temp_environment()
  left <- env$left
  right <- env$right

  # create a nested file and copy without recursion -> should land in top-level right
  fs::dir_create(fs::path(left, "nested"))
  f <- fs::path(left, "nested", "flat.txt")
  writeLines("flat", f)

  df <- data.table::data.table(path_left = f)

  copy_files_to_right(
    left_dir = left,
    right_dir = right,
    files_to_copy = df,
    recurse = FALSE
  )

  expected <- fs::path(right, fs::path_file(f))
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
  # Build an isolated fixture with a guaranteed left-only file in a subdirectory
  base   <- fs::path_temp("ctr_subdir_test")
  left_  <- fs::path(base, "left")
  right_ <- fs::path(base, "right_src")
  dest_  <- fs::path(base, "right_dest")     # nonexistent — must be created
  fs::dir_create(c(left_, right_))
  # file in a subdirectory so that dir_create is exercised
  fs::dir_create(fs::path(left_, "sub"))
  saveRDS(1L, fs::path(left_, "sub", "file.Rds"))
  on.exit(fs::dir_delete(base), add = TRUE)

  sync_status <- compare_directories(left_, right_)
  to_copy <- sync_status$non_common_files |>
    fsubset(!is.na(path_left)) |>
    fsubset(1)

  expect_true(nrow(to_copy) == 1L)
  copy_files_to_right(left_, dest_, to_copy)

  rel <- fs::path_rel(to_copy$path_left, start = left_)
  expect_true(fs::dir_exists(fs::path_dir(fs::path(dest_, rel))))
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
  left  <- env$left
  right <- env$right

  # create a known left-only file so to_copy is always non-empty
  src <- fs::path(left, "invisible_test.txt")
  writeLines("test", src)
  to_copy <- data.table::data.table(path_left = src)

  # function returns invisible(TRUE) - capture with withVisible
  vis <- withVisible(copy_files_to_right(left, right, to_copy))
  expect_true(vis$visible == FALSE)
  expect_true(vis$value)
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


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Tests for VUL-02 / VUL-03 / VUL-31: regex-metacharacter safety in
# copy_files_to_right() and copy_files_to_left()
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

test_that("copy_files_to_right works with dots in directory name (VUL-02)", {
  base  <- fs::path_temp("cfr_dot_test")
  left_ <- fs::path(base, "user.name", "left")
  right_<- fs::path(base, "user.name", "right")
  fs::dir_create(left_)
  fs::dir_create(right_)
  f <- fs::path(left_, "report.csv")
  writeLines("data", f)
  on.exit(fs::dir_delete(base), add = TRUE)

  df <- data.table::data.table(path_left = f)
  copy_files_to_right(left_, right_, df)

  expect_true(fs::file_exists(fs::path(right_, "report.csv")))
})

test_that("copy_files_to_right works with parentheses in directory name (VUL-02)", {
  base  <- fs::path_temp("cfr_paren_test")
  left_ <- fs::path(base, "data (copy)", "left")
  right_<- fs::path(base, "data (copy)", "right")
  fs::dir_create(left_)
  fs::dir_create(right_)
  f <- fs::path(left_, "results.csv")
  writeLines("x", f)
  on.exit(fs::dir_delete(base), add = TRUE)

  df <- data.table::data.table(path_left = f)
  copy_files_to_right(left_, right_, df)

  expect_true(fs::file_exists(fs::path(right_, "results.csv")))
})

test_that("copy_files_to_right works with plus sign in directory name (VUL-02)", {
  base  <- fs::path_temp("cfr_plus_test")
  left_ <- fs::path(base, "project+files", "left")
  right_<- fs::path(base, "project+files", "right")
  fs::dir_create(left_)
  fs::dir_create(right_)
  f <- fs::path(left_, "output.csv")
  writeLines("y", f)
  on.exit(fs::dir_delete(base), add = TRUE)

  df <- data.table::data.table(path_left = f)
  copy_files_to_right(left_, right_, df)

  expect_true(fs::file_exists(fs::path(right_, "output.csv")))
})

test_that("copy_files_to_right works when left_dir has trailing slash (VUL-31)", {
  base  <- fs::path_temp("cfr_slash_test")
  left_ <- fs::path(base, "left")
  right_<- fs::path(base, "right")
  fs::dir_create(left_)
  fs::dir_create(right_)
  f <- fs::path(left_, "file.csv")
  writeLines("z", f)
  on.exit(fs::dir_delete(base), add = TRUE)

  df <- data.table::data.table(path_left = f)
  # trailing slash on left_dir — must not mangle the relative path
  copy_files_to_right(paste0(left_, "/"), right_, df)

  expect_true(fs::file_exists(fs::path(right_, "file.csv")))
})

test_that("copy_files_to_right copies subdirectory files to correct destination (VUL-02)", {
  base  <- fs::path_temp("cfr_subdir_test")
  left_ <- fs::path(base, "v1.0", "left")
  right_<- fs::path(base, "v1.0", "right")
  sub   <- fs::path(left_, "sub")
  fs::dir_create(sub)
  fs::dir_create(fs::path(right_, "sub"))
  f <- fs::path(sub, "nested.csv")
  writeLines("n", f)
  on.exit(fs::dir_delete(base), add = TRUE)

  df <- data.table::data.table(path_left = f)
  copy_files_to_right(left_, right_, df)

  expect_true(fs::file_exists(fs::path(right_, "sub", "nested.csv")))
})

test_that("copy_files_to_left works with dots in directory name (VUL-03)", {
  base  <- fs::path_temp("cfl_dot_test")
  left_ <- fs::path(base, "user.name", "left")
  right_<- fs::path(base, "user.name", "right")
  fs::dir_create(left_)
  fs::dir_create(right_)
  f <- fs::path(right_, "report.csv")
  writeLines("data", f)
  on.exit(fs::dir_delete(base), add = TRUE)

  df <- data.table::data.table(path_right = f)
  copy_files_to_left(left_, right_, df)

  expect_true(fs::file_exists(fs::path(left_, "report.csv")))
})

test_that("copy_files_to_left works with parentheses in directory name (VUL-03)", {
  base  <- fs::path_temp("cfl_paren_test")
  left_ <- fs::path(base, "data (copy)", "left")
  right_<- fs::path(base, "data (copy)", "right")
  fs::dir_create(left_)
  fs::dir_create(right_)
  f <- fs::path(right_, "results.csv")
  writeLines("p", f)
  on.exit(fs::dir_delete(base), add = TRUE)

  df <- data.table::data.table(path_right = f)
  copy_files_to_left(left_, right_, df)

  expect_true(fs::file_exists(fs::path(left_, "results.csv")))
})


