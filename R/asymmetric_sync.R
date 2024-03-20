
# Higher level functions to perform an asymmetric synchronization, to left or to right

# Option 1: Full by-date asymmetric synchronization to right,
# --> sync right directory based on left one (left is leader, right is follower)
#     Forced options:
#        a. (for common_files) overwrite right older files with left newer files, i.e., copy from left to right
#        b. copy files only in left in right
#        c. delete files only in right

full_sync_to_right_by_date <- function(sync_status) {

  # Check sync_status is the result of compare_directories()
  stopifnot(expr = {
    inherits(sync_status, "sync_status")
  })

  # a. copy newer files from left to right ------------------------------------

  # Filter files that are newer in left
  files_to_copy <- sync_status$common_files |>
    filter_common_files() #syncdr aux function

  # Copy files from left to right -need to set overwrite = true
  #mapply(fs::copy_files, files_to_copy$path_left, files_to_copy$path_right)

  # b. Filter files that are only in left to right
  files_to_copy <- files_to_copy |>
    rowbind(filter_non_common_files(sync_status$non_common_files))


  # c. Delete files that are only in right
  files_to_delete <- sync_status$non_common_files |>
    filter_non_common_files(dir = "right") |>
    fselect(path_right)

  #delete files
  fs::file_delete(files_to_delete)

}



