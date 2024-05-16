#' Full symmetric synchronization
#'
#' This function updates directories in the following way:
#' * For common files:
#'   - if by date: If the file in one directory is newer than the corresponding file in the other directory,
#'                 it will be copied over to update the older version. If modification dates are the same, nothing is done
#'   - if by date and content: If the file in one directory is newer AND different than the corresponding file in the other directory,
#'                             it will be copied over to update the older version. If modification dates/contents are the same, nothing is done
#'   - if by content only: ? TO DECIDE WHAT TO DO WITH THOSE FILES
#' * For non common files:
#'   - if a file exists in one but not in the other it is copied to the other directory
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
#'
full_symmetric_sync <- function(sync_status,
                                by_date    = TRUE,
                                by_content = FALSE,
                                recurse    = TRUE,
                                verbose    = FALSE) {

  # Check sync_status is the result of compare_directories()
  stopifnot(expr = {
    inherits(sync_status, "syncdr_status")
  })

  if (verbose == TRUE) {
  # Display folder structure before synchronization
  style_msgs(color_name = "blue",
               text = "Directories structure BEFORE synchronization:\n")
  display_dir_tree(path_left  = sync_status$left_path,
                   path_right = sync_status$right_path)
  }

  # Update non- and common files ###############################################

  # copy those that are new in left to right
  files_to_right <- sync_status$common_files |>
    filter_common_files(by_date    = by_date,
                        by_content = by_content,
                        dir = "left") |>
    # add those that are only in left
    rowbind(
      filter_non_common_files(sync_status$non_common_files,
                              dir = "left")
    )

  copy_files_to_right(left_dir      = sync_status$left_path,
                      right_dir     = sync_status$right_path,
                      files_to_copy = files_to_right)

  # copy those that are new in right to left
  files_to_left <- sync_status$common_files |>
    filter_common_files(by_date    = by_date,
                        by_content = by_content,
                        dir = "right") |>
    # add those that are only in right
    rowbind(
      filter_non_common_files(sync_status$non_common_files,
                              dir = "right")
    )

  copy_files_to_left(left_dir      = sync_status$left_path,
                     right_dir     = sync_status$right_path,
                     files_to_copy = files_to_left,
                     recurse       = recurse)

  if (verbose == TRUE) {

    # Display folder structure AFTER synchronization
    style_msgs(color_name = "blue",
               text = "Directories structure AFTER synchronization:\n")
    display_dir_tree(path_left  = sync_status$left_path,
                     path_right = sync_status$right_path)
  }

  style_msgs(color_name = "green",
             text = paste0("\u2714", " synchronized\n"))
  invisible(TRUE)

}

#' Partial symmetric synchronization -common files only
#'
#' This function updates directories in the following way:
#' * For common files:
#'   - if by date: If the file in one directory is newer than the corresponding file in the other directory,
#'                 it will be copied over to update the older version. If modification dates are the same, nothing is done
#'   - if by date and content: If the file in one directory is newer AND different than the corresponding file in the other directory,
#'                             it will be copied over to update the older version. If modification dates/contents are the same, nothing is done
#'   - if by content only: ? TO DECIDE WHAT TO DO WITH THOSE FILES ?
#' * For non common files: unchanged, i.e.,
#'   - keep in right those that are only in right
#'   - keep in left those that are only in left
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
partial_symmetric_sync_common_files <- function(sync_status,
                                                by_date    = TRUE,
                                                by_content = FALSE,
                                                recurse    = TRUE,
                                                verbose    = FALSE) {

  # Check sync_status is the result of compare_directories()
  stopifnot(expr = {
    inherits(sync_status, "syncdr_status")
  })

  if(verbose == TRUE) {

    style_msgs(color_name = "blue",
               text = "Directories structure BEFORE synchronization:\n")
    display_dir_tree(path_left  = sync_status$left_path,
                     path_right = sync_status$right_path)

  }
  # Update non- and common files ###############################################

  # copy those that are new in left to right
  files_to_right <- sync_status$common_files |>
    filter_common_files(by_date    = by_date,
                        by_content = by_content,
                        dir = "left")

  copy_files_to_right(left_dir      = sync_status$left_path,
                      right_dir     = sync_status$right_path,
                      files_to_copy = files_to_right,
                      recurse       = recurse)

  # copy those that are new in right to left
  files_to_left <- sync_status$common_files |>
    filter_common_files(by_date    = by_date,
                        by_content = by_content,
                        dir = "right")

  copy_files_to_left(left_dir      = sync_status$left_path,
                     right_dir     = sync_status$right_path,
                     files_to_copy = files_to_left,
                     recurse       = recurse)

  if(verbose == TRUE) {
  # Display folder structure AFTER synchronization
  style_msgs(color_name = "blue",
               text = "Directories structure AFTER synchronization:\n")
  display_dir_tree(path_left  = sync_status$left_path,
                   path_right = sync_status$right_path)}

  style_msgs(color_name = "green",
             text = paste0("\u2714", " synchronized\n"))
  invisible(TRUE)

}

