#' Full asymmetric synchronization to right directory
#'
#' This function performs a full asymmetric synchronization of the right directory
#' based on the left directory. It includes the following synchronization steps (see Details below):
#'
#' * For common files:
#'   - If comparing by date only (`by_date = TRUE`): Copy files that are newer in the left directory to the right directory.
#'   - If comparing by date and content (`by_date = TRUE` and `by_content = TRUE`): Copy files that are newer and different in the left directory to the right directory.
#'   - If comparing by content only (`by_content = TRUE`): Copy files that are different in the left directory to the right directory.
#' * Copy to the right directory those files that exist only in the left directory.
#' * Delete from the right directory those files that are exclusive in the right directory (i.e., missing in the left directory)
#'
#' @param left_path Path to the left/first directory.
#' @param right_path Path to the right/second directory.
#' @param sync_status Object of class "syncdr_status", output of `compare_directories()`.
#' @param by_date Logical. If TRUE, synchronize based on file modification dates (default is TRUE).
#' @param by_content Logical. If TRUE, synchronize based on file contents (default is FALSE).
#' @param recurse Logical. If TRUE (default), files are copied to corresponding subdirectories
#'                in the destination folder. If FALSE, files are copied to the top level of the destination folder
#'                without creating subdirectories if they do not exist.
#' @param backup Logical. If TRUE, creates a backup of the right directory before synchronization. The backup is stored in the location specified by `backup_dir`.
#' @param backup_dir Path to the directory where the backup of the original right directory will be stored. If not specified, the backup is stored in a temporary directory (`tempdir`).
#' @param verbose logical. If TRUE, display directory tree before and after synchronization. Default is FALSE
#' @return Invisible TRUE indicating successful synchronization.
#'
#' @export
#' @examples
#' # Create syncdr environment with toy directories
#' e <- toy_dirs()
#'
#' # Get left and right directories' paths
#' left  <- e$left
#' right <- e$right
#'
#' # Synchronize by date & content
#' # Providing left and right paths to directories, as well as by_date and content
#' full_asym_sync_to_right(left_path  = left,
#'                         right_path = right,
#'                         by_date    = FALSE,
#'                         by_content = TRUE)
#' # Providing sync_status object
#' sync_status = compare_directories(left_path = left,
#'                                   right_path = right)
#' full_asym_sync_to_right(sync_status = sync_status)
full_asym_sync_to_right <- function(left_path   = NULL,
                                    right_path  = NULL,
                                    sync_status = NULL,
                                    by_date     = TRUE,
                                    by_content  = FALSE,
                                    recurse     = TRUE,
                                    backup      = FALSE,
                                    backup_dir  = "temp_dir",
                                    verbose     = getOption("syncdr.verbose")) {


  # Display folder structure before synchronization
  if (verbose == TRUE) {

    style_msgs(color_name = "blue",
               text = "Directories structure BEFORE synchronization:\n")

    display_dir_tree(path_left  = left_path,
                     path_right = right_path)
  }

  # --- Check validity of arguments -----------------

  # Either sync_status is null, and both right and left path are provided,
  # or sync_status is provided and left and right are NULL

  if(!(
    is.null(sync_status) && !is.null(left_path) && !is.null(right_path) ||
       !is.null(sync_status) && is.null(left_path) && is.null(right_path)
    )) {

    style_msgs(color_name = "purple",
               text = "Incorrect arguments specification!\n")

    cli::cli_abort("Either sync_status or left and right paths must be provided")

  }

  # --------------------------------------------------

  # If sync_status is null, but left and right paths are provided
  # get sync_status object -internal call to compare_directories()

  if(is.null(sync_status)) {

    # --- first check directories path ---
    stopifnot(exprs = {
      fs::dir_exists(left_path)
      fs::dir_exists(right_path)
    })

    # --- get sync_status ---
    sync_status <- compare_directories(left_path  = left_path,
                                       right_path = right_path,
                                       by_date    = by_date,
                                       by_content = by_content,
                                       recurse    = recurse,
                                       verbose    = verbose
    )
  } else {

    # If sync_status is already provided,
    # retrieve paths of left and right directory as well as by_date and by_content arguments

    left_path  <- sync_status$left_path
    right_path <- sync_status$right_path

    by_date    <- fifelse(is.null(sync_status$common_files$is_new_right),
                           FALSE,
                           by_date)
    by_content <- fifelse(!(is.null(sync_status$common_files$is_diff)),
                          TRUE,
                          by_content)

  }

  # --------------------------------------------------

  # --- Backup ---

  # Copy right directory in backup directory
  if (backup) {
    backup_dir <- fifelse(backup_dir == "temp_dir", # the default

                          #tempdir(),
                          file.path(tempdir(),
                                    "copied_directory"),
                          backup_dir) # path provided by the user

    # create the target directory if it does not exist
    if (!dir.exists(backup_dir)) {
      dir.create(backup_dir, recursive = TRUE)
    }


    # copy dir content
    file.copy(from      = right_path,
              to        = backup_dir,
              recursive = TRUE)


  }


  # --------------------------------------------------

  # --- synchronization ---

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

    style_msgs(color_name = "blue",
               text = "Directories structure AFTER synchronization:\n")
    display_dir_tree(path_left  = left_path,
                     path_right = right_path)

  }

  style_msgs(color_name = "green",
             text = paste0("\u2714", " synchronized\n"))

  invisible(TRUE)

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
#' @param left_path Path to the left/first directory.
#' @param right_path Path to the right/second directory.
#' @param sync_status Object of class "syncdr_status", output of `compare_directories()`.
#' @param by_date logical, TRUE by default
#' @param by_content logical, FALSE by default
#' @param recurse logical, TRUE by default.
#'  If recurse is TRUE: when copying a file from source folder to destination folder, the file will be copied into the corresponding (sub)directory.
#'  If the sub(directory) where the file is located does not exist in destination folder (or you are not sure), set recurse to FALSE,
#'  and the file will be copied at the top level
#' @param verbose logical. If TRUE, display directory tree before and after synchronization. Default is FALSE
#' @return Invisible TRUE indicating successful synchronization.
#' @export
#' @examples
#' # Compare directories with 'compare_directories()'
#' e <- toy_dirs()
#'
#' # Get left and right directories' paths
#' left  <- e$left
#' right <- e$right
#'
#' # Example: Synchronize by date
#' # Option 1
#' common_files_asym_sync_to_right(left_path  = left,
#'                                 right_path = right)
#' # Option 2
#' sync_status = compare_directories(left,
#'                                   right)
#' common_files_asym_sync_to_right(sync_status = sync_status)
common_files_asym_sync_to_right <- function(left_path   = NULL,
                                            right_path  = NULL,
                                            sync_status = NULL,
                                            by_date     = TRUE,
                                            by_content  = FALSE,
                                            recurse     = TRUE,
                                            verbose     = getOption("syncdr.verbose")) {

  if(verbose == TRUE) {
  # Display folder structure before synchronization
  style_msgs(color_name = "blue",
             text = "Directories structure BEFORE synchronization:\n")
  display_dir_tree(path_left  = left_path,
                   path_right = right_path)}

  # --- Check validity of arguments -----------------

  # Either sync_status is null, and both right and left path are provided,
  # or sync_status is provided and left and right are NULL

  if(!(
    is.null(sync_status) && !is.null(left_path) && !is.null(right_path) ||
    !is.null(sync_status) && is.null(left_path) && is.null(right_path)
  )) {

    style_msgs(color_name = "purple",
               text = "Incorrect arguments specification!\n")

    cli::cli_abort("Either sync_status or left and right paths must be provided")

  }

  # --------------------------------------------------

  # If sync_status is null, but left and right paths are provided
  # get sync_status object -internal call to compare_directories()

  if(is.null(sync_status)) {

    # --- first check directories path ---
    stopifnot(exprs = {
      fs::dir_exists(left_path)
      fs::dir_exists(right_path)
    })

    # --- get sync_status ---
    sync_status <- compare_directories(left_path  = left_path,
                                       right_path = right_path,
                                       by_date    = by_date,
                                       by_content = by_content,
                                       recurse    = recurse,
                                       verbose    = verbose
    )
  } else {

    # If sync_status is already provided, retrieve by_date and by_content arguments from it

    by_date    <- fifelse(is.null(sync_status$common_files$is_new_right),
                          FALSE,
                          by_date)

    by_content <- fifelse(!(is.null(sync_status$common_files$is_diff)),
                          TRUE,
                          by_content)

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
    style_msgs(color_name = "blue",
               text = "Directories structure AFTER synchronization:\n")
    display_dir_tree(path_left  = left_path,
                     path_right = right_path)
  }

  style_msgs(color_name = "green",
             text = paste0("\u2714", " synchronized\n"))
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
#' @param left_path Path to the left/first directory.
#' @param right_path Path to the right/second directory.
#' @param sync_status Object of class "syncdr_status", output of `compare_directories()`.
#' @param recurse logical, TRUE by default.
#'  If recurse is TRUE: when copying a file from source folder to destination folder, the file will be copied into the corresponding (sub)directory.
#'  If the sub(directory) where the file is located does not exist in destination folder (or you are not sure), set recurse to FALSE,
#'  and the file will be copied at the top level
#' @param verbose logical. If TRUE, display directory tree before and after synchronization. Default is FALSE
#' @return Invisible TRUE indicating successful synchronization.

#' @export
#' @examples
#' # Compare directories with 'compare_directories()'
#' e <- toy_dirs()
#'
#' # Get left and right directories' paths
#' left  <- e$left
#' right <- e$right
#'
#' # Option 1
#' update_missing_files_asym_to_right(left_path  = left,
#'                                    right_path = right)
#' # Option 2
#' sync_status = compare_directories(left,
#'                                   right)
#'
#' update_missing_files_asym_to_right(sync_status = sync_status)
update_missing_files_asym_to_right <- function(left_path = NULL,
                                               right_path = NULL,
                                               sync_status = NULL,
                                               recurse    = TRUE,
                                               verbose    = getOption("syncdr.verbose")) {

  if (verbose == TRUE) {
    # Display folder structure before synchronization
    style_msgs(color_name = "blue",
               text = "Directories structure BEFORE synchronization:\n")
    display_dir_tree(path_left  = left_path,
                     path_right = right_path)
  }

  # --- Check validity of arguments -----------------

  # Either sync_status is null, and both right and left path are provided,
  # or sync_status is provided and left and right are NULL

  if(!(
    is.null(sync_status) && !is.null(left_path) && !is.null(right_path) ||
    !is.null(sync_status) && is.null(left_path) && is.null(right_path)
  )) {

    style_msgs(color_name = "purple",
               text = "Incorrect arguments specification!\n")

    cli::cli_abort("Either sync_status or left and right paths must be provided")

  }

  # --------------------------------------------------

  # If sync_status is null, but left and right paths are provided
  # get sync_status object -internal call to compare_directories()

  if(is.null(sync_status)) {

    # --- first check directories path ---
    stopifnot(exprs = {
      fs::dir_exists(left_path)
      fs::dir_exists(right_path)
    })

    # --- get sync_status ---
    sync_status <- compare_directories(left_path  = left_path,
                                       right_path = right_path,
                                       recurse    = recurse,
                                       verbose    = verbose
    )
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
  style_msgs(color_name = "blue",
               text = "Directories structure AFTER synchronization:\n")
  display_dir_tree(path_left  = left_path,
                   path_right = right_path)
  }

  style_msgs(color_name = "green",
             text = paste0("\u2714", " synchronized\n"))
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
#' @param left_path Path to the left/first directory.
#' @param right_path Path to the right/second directory.
#' @param sync_status Object of class "syncdr_status", output of `compare_directories()`.
#' @param recurse logical, TRUE by default.
#'  If recurse is TRUE: when copying a file from source folder to destination folder, the file will be copied into the corresponding (sub)directory.
#'  If the sub(directory) where the file is located does not exist in destination folder (or you are not sure), set recurse to FALSE,
#'  and the file will be copied at the top level
#' @param verbose logical. If TRUE, display directory tree before and after synchronization. Default is FALSE
#' @return Invisible TRUE indicating successful synchronization.

#' @export
#' @examples
#' # Compare directories with 'compare_directories()'
#' e <- toy_dirs()
#'
#' # Get left and right directories' paths
#' left  <- e$left
#' right <- e$right
#'
#' # Option 1
#' partial_update_missing_files_asym_to_right(left_path  = left,
#'                                            right_path = right)
#' # Option 2
#' sync_status = compare_directories(left,
#'                                   right)
#' partial_update_missing_files_asym_to_right(sync_status = sync_status)
#'
partial_update_missing_files_asym_to_right <- function(left_path = NULL,
                                                       right_path = NULL,
                                                       sync_status = NULL,
                                                       recurse = TRUE,
                                                       verbose    = getOption("syncdr.verbose")) {


  if(verbose == TRUE) {
    # Display folder structure before synchronization
    style_msgs(color_name = "blue",
               text = "Directories structure BEFORE synchronization:\n")
    display_dir_tree(path_left  = left_path,
                     path_right = right_path)
  }

  # --- Check validity of arguments -----------------

  # Either sync_status is null, and both right and left path are provided,
  # or sync_status is provided and left and right are NULL

  if(!(
    is.null(sync_status) && !is.null(left_path) && !is.null(right_path) ||
    !is.null(sync_status) && is.null(left_path) && is.null(right_path)
  )) {

    style_msgs(color_name = "purple",
               text = "Incorrect arguments specification!\n")

    cli::cli_abort("Either sync_status or left and right paths must be provided")

  }

  # --------------------------------------------------

  # If sync_status is null, but left and right paths are provided
  # get sync_status object -internal call to compare_directories()

  if(is.null(sync_status)) {

    # --- first check directories path ---
    stopifnot(exprs = {
      fs::dir_exists(left_path)
      fs::dir_exists(right_path)
    })

    # --- get sync_status ---
    sync_status <- compare_directories(left_path  = left_path,
                                       right_path = right_path,
                                       recurse    = recurse,
                                       verbose    = verbose
    )
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
    style_msgs(color_name = "blue",
               text = "Directories structure AFTER synchronization:\n")
    display_dir_tree(path_left  = left_path,
                     path_right = right_path)
  }
  style_msgs(color_name = "green",
             text = paste0("\u2714", " synchronized\n"))
  invisible(TRUE)
}


