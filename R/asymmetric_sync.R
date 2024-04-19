
# This file contains functions to perform an asymmetric synchronization -in other words, one-way synchronization:
# this means that you have a master/left/leader directory and you want to ensure that changes made there are
# reflected in a secondary/right/follower directory.
# thus, right/follower directory will mirror the contents of the left/leader directory.
# Please read the NOTE below before using the functions

# ------------------------------- <<<< NOTE >>>> -------------------------------
#
# For all of the asymmetric functions below, asymmetric synchronization goes left to right:
#
# this means that you sync right (follower) directory
# based on left (leader) directory
#
# Important (1)
# The input should always be the result of compare_directories(),
# with the "leader" passed to "path_left" argument, and follower to "path_right".
#
# Say you want to perform a synchronization between A and B.
# If you want to sync B based on A, then:
#
# sync_status <- compare_directories(path_left = path_A,
#                                    path_right = path_B)
# full_asym_sync_to_right(sync_status)
#
# If, instead, you want to sync A based on B, then:
#
# sync_status <- compare_directories(path_left = path_B,
#                                    path_right = path_A)
# full_asym_sync_to_right(sync_status)
#
#
# Important (2)
# Also, you must provide as input the result of compare_directories()
# with by_date and by_content set in the same way as you pass them
# to the asymmetric synchronization functions
#
# For Example:
# sync_status <- compare_directories(left_path  = left,
#                                    right_path = right,
#                                    by_content = TRUE)
#
# full_asym_sync_to_right(sync_status = sync_status,
#                         by_content  = TRUE)
# ------------------------------------------------------------------------------


#' Fully asymmetric synchronization to right directory
#'
#' This function performs a full asymmetric synchronization of the right directory
#' based on the left directory. It includes the following synchronization steps:
#'
#' * For common files:
#'   - If comparing by date only (`by_date = TRUE`): Copy files that are newer in the left directory to the right directory.
#'   - If comparing by date and content (`by_date = TRUE` and `by_content = TRUE`): Copy files that are newer and different in the left directory to the right directory.
#'   - If comparing by content only (`by_content = TRUE`): Copy files that are different in the left directory to the right directory.
#' * Copy to the right directory those files that exist only in the left directory.
#' * Delete from the right directory those files that are exclusive in the right directory (i.e., missing in the left directory)
#'
#' @param sync_status An object of class 'syncdr_status' containing information about
#'                    synchronization status and directory comparison.
#' @param by_date Logical. If TRUE, synchronize based on file modification dates (default is TRUE).
#' @param by_content Logical. If TRUE, synchronize based on file contents (default is FALSE).
#' @param recurse Logical. If TRUE (default), files are copied to corresponding subdirectories
#'                in the destination folder. If FALSE, files are copied to the top level of the destination folder
#'                without creating subdirectories if they do not exist.
#' @param verbose logical. If TRUE, display directory tree before and after synchronization. Default is FALSE
#' @return Invisible TRUE indicating successful synchronization.
#'
#' @export
full_asym_sync_to_right <- function(sync_status,
                                    by_date    = TRUE,
                                    by_content = FALSE,
                                    recurse    = TRUE,
                                    verbose    = FALSE) {

  # Check sync_status is the result of compare_directories()
  stopifnot(expr = {
    inherits(sync_status, "syncdr_status")
  })

  # Display folder structure before synchronization

  if (verbose == TRUE) {

    cat("\033[1;31m\033[1mDirectory structure BEFORE synchronization:\033[0m\n")

    display_dir_tree(path_left  = sync_status$left_path,
                     path_right = sync_status$right_path)
  }

  # Get files to copy -from common files
  files_to_copy <- sync_status$common_files |>
    filter_common_files(by_date    = by_date,
                        by_content = by_content,
                        dir = "left") #syncdr aux function

  # Add files to copy -from non common files
  files_to_copy <- files_to_copy |>
    rowbind(
      filter_non_common_files(sync_status$non_common_files,
                              dir = "left")
      ) # files only in left

  # Copy files ####

  copy_files_to_right(left_dir      = sync_status$left_path,
                      right_dir     = sync_status$right_path,
                      files_to_copy = files_to_copy,
                      recurse       = recurse)


  # Get files to delete, i.e., missing in left
  files_to_delete <- sync_status$non_common_files |>
    filter_non_common_files(dir = "right") |>
    fselect(path_right)

  # Delete Files ####
  fs::file_delete(files_to_delete$path_right)

  if(verbose == TRUE) {

    # Display folder structure AFTER synchronization
    cat("\033[1;31m\033[1mDirectory structure AFTER synchronization:\033[0m\n")

    display_dir_tree(path_left  = sync_status$left_path,
                     path_right = sync_status$right_path)

  }

  cat(paste0("\033[1;32m", "\u2714", " synchronized", "\033[0m"), "\n")

  invisible(TRUE)
  #return(print("synchronized"))
}


#' Partial asymmetric synchronization to right (update common files)
#'
#' Partially synchronize right directory based on left one -i.e., the function will:
#' * for common_files:
#'    - if by date only: copy files that are newer in left to right
#'    - if by date and content: copy files that are newer and different in left to right
#'    - if by content only: copy files that are different in left to right
#' * for non common files, nothing changes: i.e.,
#'    - disregard those files that are only in left
#'    - keep in right those files that are only in right (i.e., files 'missing in left')
#'
#' @param sync_status object of class 'syncdr_status' with info on sync status and comparison of directories
#' @param by_date logical, TRUE by default
#' @param by_content logical, FALSE by default
#' @param recurse logical, TRUE by default.
#'  If recurse is TRUE: when copying a file from source folder to destination folder, the file will be copied into the corresponding (sub)directory.
#'  If the sub(directory) where the file is located does not exist in destination folder (or you are not sure), set recurse to FALSE,
#'  and the file will be copied at the top level
#' @param verbose logical. If TRUE, display directory tree before and after synchronization. Default is FALSE
#' @return print "synchronized"
#' @export
common_files_asym_sync_to_right <- function(sync_status,
                                            by_date    = TRUE,
                                            by_content = FALSE,
                                            recurse    = TRUE,
                                            verbose    = FALSE) {

  # Check sync_status is the result of compare_directories()
  stopifnot(expr = {
    inherits(sync_status, "syncdr_status")
  })

if(verbose == TRUE) {
  # Display folder structure before synchronization
  cat("\033[1;31m\033[1mDirectory structure BEFORE synchronization:\033[0m\n")

  display_dir_tree(path_left  = sync_status$left_path,
                   path_right = sync_status$right_path)
}

  # Get files to copy -from common files
  files_to_copy <- sync_status$common_files |>
    filter_common_files(by_date    = by_date,
                        by_content = by_content,
                        dir = "left")
  # Copy files
  copy_files_to_right(left_dir      = sync_status$left_path,
                      right_dir     = sync_status$right_path,
                      files_to_copy = files_to_copy,
                      recurse       = recurse)

  if (verbose == TRUE) {
    # Display folder structure AFTER synchronization
    cat("\033[1;31m\033[1mDirectory structure AFTER synchronization:\033[0m\n")

    display_dir_tree(path_left  = sync_status$left_path,
                     path_right = sync_status$right_path)
  }

  cat(paste0("\033[1;32m", "\u2714", " synchronized", "\033[0m"), "\n")

  invisible(TRUE)

}

#' Full asymmetric synchronization of non common files
#'
#' update non common files in right directory based on left one -i.e., the function will:
#' * for common_files:
#'    - do nothing, left unchanged
#' * for non common files,
#'    - copy those files that are only in left to right
#'    - delete in right those files that are only in right (i.e., files 'missing in left')
#'
#' @param sync_status object of class 'syncdr_status' with info on sync status and comparison of directories
#' @param by_date logical, TRUE by default
#' @param by_content logical, FALSE by default
#' @param recurse logical, TRUE by default.
#'  If recurse is TRUE: when copying a file from source folder to destination folder, the file will be copied into the corresponding (sub)directory.
#'  If the sub(directory) where the file is located does not exist in destination folder (or you are not sure), set recurse to FALSE,
#'  and the file will be copied at the top level
#'  @param verbose logical. If TRUE, display directory tree before and after synchronization. Default is FALSE
#'
#' @return print "synchronized"
#' @export
update_missing_files_asym_to_right <- function(sync_status,
                                               recurse    = TRUE,
                                               verbose    = FALSE) {

  # Check sync_status is the result of compare_directories()
  stopifnot(expr = {
    inherits(sync_status, "syncdr_status")
  })

  if (verbose == TRUE) {
    # Display folder structure before synchronization
    cat("\033[1;31m\033[1mDirectory structure BEFORE synchronization:\033[0m\n")

    display_dir_tree(path_left  = sync_status$left_path,
                     path_right = sync_status$right_path)
  }

  # Get files to copy
  files_to_copy <- sync_status$non_common_files |>
    filter_non_common_files(dir = "left")

  # Copy files
  copy_files_to_right(left_dir      = sync_status$left_path,
                      right_dir     = sync_status$right_path,
                      files_to_copy = files_to_copy,
                      recurse       = recurse)

  # Get files to delete
  files_to_delete <- sync_status$non_common_files |>
    filter_non_common_files(dir = "right") |>
    fselect(path_right)

  # Delete Files ####
  fs::file_delete(files_to_delete$path_right)

  if (verbose == TRUE) {
  # Display folder structure AFTER synchronization
  cat("\033[1;31m\033[1mDirectory structure AFTER synchronization:\033[0m\n")

  display_dir_tree(path_left  = sync_status$left_path,
                   path_right = sync_status$right_path)
  }

  cat(paste0("\033[1;32m", "\u2714", " synchronized", "\033[0m"), "\n")

  invisible(TRUE)
}

#' Partial asymmetric asymmetric synchronization of non common files
#'
#' update non common files in right directory based on left one -i.e., the function will:
#' * for common_files:
#'    - do nothing, left unchanged
#' * for non common files,
#'    - copy those files that are only in left to right
#'    - keep in right those files that are only in right (i.e., files 'missing in left')
#'
#' @param sync_status object of class 'syncdr_status' with info on sync status and comparison of directories
#' @param by_date logical, TRUE by default
#' @param by_content logical, FALSE by default
#' @param recurse logical, TRUE by default.
#'  If recurse is TRUE: when copying a file from source folder to destination folder, the file will be copied into the corresponding (sub)directory.
#'  If the sub(directory) where the file is located does not exist in destination folder (or you are not sure), set recurse to FALSE,
#'  and the file will be copied at the top level
#' @param verbose logical. If TRUE, display directory tree before and after synchronization. Default is FALSE
#' @return print "synchronized"
#' @export
partial_update_missing_files_asym_to_right <- function(sync_status,
                                                       recurse = TRUE,
                                                       verbose = FALSE) {

  # Check sync_status is the result of compare_directories()
  stopifnot(expr = {
    inherits(sync_status, "syncdr_status")
  })

  if(verbose == TRUE) {
    # Display folder structure before synchronization
    cat("\033[1;31m\033[1mDirectory structure BEFORE synchronization:\033[0m\n")

    display_dir_tree(path_left  = sync_status$left_path,
                     path_right = sync_status$right_path)
  }

  # Get files to copy
  files_to_copy <- sync_status$non_common_files |>
    filter_non_common_files(dir = "left")

  # Copy files
  copy_files_to_right(left_dir      = sync_status$left_path,
                      right_dir     = sync_status$right_path,
                      files_to_copy = files_to_copy,
                      recurse       = recurse)

  if(verbose == TRUE) {
    # Display folder structure AFTER synchronization
    cat("\033[1;31m\033[1mDirectory structure AFTER synchronization:\033[0m\n")

    display_dir_tree(path_left  = sync_status$left_path,
                     path_right = sync_status$right_path)
  }

  cat(paste0("\033[1;32m", "\u2714", " synchronized", "\033[0m"), "\n")

  invisible(TRUE)
}


