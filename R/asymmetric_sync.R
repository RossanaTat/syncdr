
# This file contains higher level functions to perform an asymmetric synchronization

# Synchronization is done left to right: i.e., sync right (follower) directory
# based on left (leader) directory

# Function 1: Full asymmetric synchronization to right
# --> sync right directory based on left one
#     Forced options:
#        a. (for common_files)
#            - if by date only: copy files that are newer in left to right
#            - if by date and content: copy files that are newer and different in left to right
#            - if by content only: copy files that are different in left to right
#        b. copy to right files only in left
#        c. delete in right files only in right (i.e., files 'missing in left')

# ------------------------------- <<<< NOTE >>>> -------------------------------
#
# The user must provide as input the result of compare_directories()
# with by_date and by_content set in the same way as they pass them
# to full_asym_sync_to_right function
#
# For Example:
# sync_status <- compare_directories(left_path  = left,
#                                    right_path = right,
#                                    by_content = TRUE)
#
# full_asym_sync_to_right(sync_status = sync_status_date,
#                         by_content  = TRUE)
# ------------------------------------------------------------------------------

# MEMO: RT: Write documentation !



full_asym_sync_to_right <- function(sync_status,
                                    by_date    = TRUE,
                                    by_content = FALSE) {

  # Check sync_status is the result of compare_directories()
  stopifnot(expr = {
    inherits(sync_status, "syncdr_status")
  })

  # Get files to copy -from common files
  files_to_copy <- sync_status$common_files |>
    filter_common_files(by_date    = by_date,
                        by_content = by_content) #syncdr aux function

  # Add files to copy -from non common files
  files_to_copy <- files_to_copy |>
    rowbind(
      filter_non_common_files(sync_status$non_common_files)
      ) # files only in left

  # Copy files ####

  copy_files_to_right(left_dir      = sync_status$left_path,
                      right_dir     = sync_status$right_path,
                      files_to_copy = files_to_copy)


  # Get files to delete, i.e., missing in left
  files_to_delete <- sync_status$non_common_files |>
    filter_non_common_files(dir = "right") |>
    fselect(path_right)

  # Delete Files ####
  fs::file_delete(files_to_delete$path_right)

  return(print("synchronized"))
}

# Example usage ####
# sync_status <- compare_directories(left_path = left,
#                                    right_path = right)
# full_asym_sync_to_right(sync_status = sync_status_date)


# Asymmetric synchronization for common files only
partial_asym_sync_to_right <- function(sync_status,
                                       by_date    = TRUE,
                                       by_content = FALSE) {


}
