
# library(joyn)
# library(DT)
# library(fs)
# library(rlang)


library(collapse)

#' Compare directories
#'
#' This function takes two directories as input, say left and right, and compares them.
#' The goal is to return the status of synchronization -at file level- of the two directories.
#' The sync status is returned for both:
#' *1. NON common files, i.e., files that are either only in left or only in right
#' *2. Common files, i.e., files that are in both directories
#'
#' @section possible types of sync status:
#'
#' Sync status is computed for both files that are available in both directories
#' and files that are only into one directory or into the other. It is also computed either by date only,
#' or by content only, or by date and content -depending on what you choose.
#'
#' Possible value of sync status -for common files:
#'
#' * When comparing by date: new, old, same
#'
#' * When comparing by date $ content: | date | content |
#'                                      new  and diff;
#'                                      new  and same;
#'                                      old  and diff;
#'                                      old  and same;
#'                                      same and diff;
#'                                      same and same
#'
#' * When comparing by content only: diff or same
#'
#' Possible value of sync status -for non common files:
#'
#' * When comparing by date; or by date and content; or by content only:
#'      "missing in left" or "only in right"
#'
#'
#' @param left_path path of one directory
#' @param right_path path of another directory
#' @param by_date logical: if TRUE, i.e., the default, it compares the directories based on date of modification of their common files
#' @param by_content logical: default is FALSE.
#'    If TRUE, it compares the directories based on whether (hashed) content of common files is same or different (ADD EXPLANATION OF 3 TYPES)
#' @param recurse If TRUE recurse fully, if a positive number the number of levels to recurse.
#'
#' @return list of class "syncdr_status", with 4 elements:
#'   * Non-common files: paths and sync status of files only in right/only in left
#'   * Common files: paths and sync status of files in both directories
#'   * Path of left directory
#'   * Path of right directory
#'
#' @export
compare_directories <- function(left_path,
                                right_path,
                                recurse    = TRUE,
                                by_date    = TRUE,
                                by_content = FALSE){
                                #...) {

  # Check directory paths
  stopifnot(exprs = {
    fs::dir_exists(left_path)
    fs::dir_exists(right_path)
  })

  # Get info on directory 1, i.e. left
  info_left <- directory_info(dir     = left_path,
                              recurse = recurse)
  # Get info on directory 2, i.e., right
  info_right <- directory_info(dir    = right_path,
                              recurse = recurse)

  # Combine info with a full join to keep all information
  join_info  <- joyn::joyn(x                = info_left,
                           y                = info_right,
                           by               = "wo_root",
                           keep_common_vars = TRUE,
                           suffixes         = c("_left", "_right"),
                           match_type       = "1:1",
                           reportvar        = ".joyn",
                           verbose          = FALSE)


  # Unique file status:
  # -NOTE: available in both here is not needed here,
  #        since we are filtering files that are only in left or only in right

  non_common_files <- join_info |>

    # Filter non unique files
    fsubset(.joyn == "y" | .joyn == "x" ) |>
    fselect(path_left, path_right) |>
    ftransform(sync_status = ifelse(
      (is.na(path_left) & !is.na(path_right)), "missing in left, only in right",
      ifelse(!is.na(path_left), "only in left", "missing in left, only in right"))
      )

  # Compare common files by date only
  if ((isTRUE(by_date) & isFALSE(by_content))) {

    common_files <- join_info |>
      fsubset(.joyn == "x & y") |>
      fselect(path_left,
              path_right,
              modification_time_left,
              modification_time_right) |>
      ftransform(is_new_left = modification_time_left > modification_time_right,
                 is_new_right = modification_time_right > modification_time_left)

    #common_files$is_new <- mapply(compare_files, common_files$path_left, common_files$path_right)

    common_files <- common_files |>
      ftransform(sync_status = ifelse(
        is_new_left & !is_new_right, "newer in left, older in right dir",
        ifelse(!is_new_left & is_new_right, "older in left, newer in right dir", "same date")
      )) |>

      # reordering columns for better displaying
      fselect(path_left,
              path_right,
              is_new_left,
              is_new_right,
              modification_time_left,
              modification_time_right,
              sync_status)

  }

  else if (isTRUE(by_date) & isTRUE(by_content)) {

    common_files <- join_info |>
      fsubset(.joyn == "x & y") |>
      fselect(path_left,
              path_right,
              modification_time_left,
              modification_time_right) |>
      ftransform(is_new_left = modification_time_left > modification_time_right,
                 is_new_right = modification_time_right > modification_time_left)

    #common_files$is_new <- mapply(compare_files, common_files$path_left, common_files$path_right)

    common_files <- common_files |>
      fsubset(is_new_left == TRUE | is_new_right == TRUE) |>

      # hash and compare content of files (that do not have same date of last modification)
      ftransform(hash_left = hash_files_contents(path_left,
                                                 path_right)$left_hash,
                 hash_right = hash_files_contents(path_left,
                                                  path_right)$right_hash) |>
      ftransform(is_diff    = (hash_left != hash_right),
                 hash_left  = NULL,
                 hash_right = NULL) |>

      # determine sync_status
      ftransform(sync_status = ifelse(
        is_new_left & is_diff, "newer in left, different content than right",
        ifelse(is_new_left & !is_diff, "newer in left, same content as right",
               ifelse(is_new_right & !is_diff, "newer in right, same content as left",
                      ifelse(is_new_right & is_diff, "newer in right, different content than left",
                             "same date, different content")
               )
        )
      )) |>
      # reordering columns for better displaying
      fselect(path_left, path_right, is_new_left, is_new_right, is_diff, sync_status)

  }

  else if (isFALSE(by_date) & isTRUE(by_content)) {
    # compare by content only
    common_files <- join_info |>
      fsubset(.joyn == "x & y") |>
      fselect(path_left, path_right)

    common_files <- common_files |>

      # hash and compare content of files (that do not have same date of last modification)
      ftransform(hash_left = hash_files_contents(path_left,
                                                 path_right)$left_hash,
                 hash_right = hash_files_contents(path_left,
                                                  path_right)$right_hash) |>
      ftransform(is_diff    = (hash_left != hash_right),
                 hash_left  = NULL,
                 hash_right = NULL) |>

      # determine sync status
      ftransform(sync_status = ifelse(
        is_diff == TRUE,
        "different content",
        "same content"
      )) |>

      # reordering columns for better displaying
      fselect(path_left,
              path_right,
              is_diff,
              sync_status)

  }

  else {

    # if both by_date is FALSE and by_content is FALSE, just return info
    common_files <- join_info |>
      fsubset(.joyn == "x & y") |>
      fselect(path_left,
              path_right)
  }

  # object to return
  sync_status = list(
    common_files = common_files,
    non_common_files = non_common_files,
    left_path = left_path,
    right_path = right_path
  )

  # assign class 'syncdr_status'
  class(sync_status) <- "syncdr_status"

  return(sync_status)

} # close function

# Auxiliary functions ####
# Q: should I move these functions to another, say, auxiliary_functions .R file?

# Get all info of a single directory auxiliary function ####

directory_info <- function(dir,
                           recurse = TRUE,
                           ...) {

  # List of files -also in sub-directories
  files <- fs::dir_ls(path = dir,
                      type = "file",
                      recurse = recurse,
                      ...)

  # Filtering out special files
  files <- files[!grepl("^\\.\\.$|^\\.$", files)]

  # Get all dir info available in file_info
  info_df <- fs::file_info(files) |>
    ftransform(wo_root = gsub(dir, "", path)) #add without root var

  return(info_df)

}

# Compare individual files auxiliary function -not used for the moment ####

compare_files <- function(file1, file2) {

  if (!fs::file_exists(file2)) return(list(new_left = TRUE, new_right = FALSE))  # New file in dir1
  if (!fs::file_exists(file1)) return(list(new_left = FALSE, new_right = TRUE))   # Old file in dir1

  # Compare creation times
  time1 <- fs::file_info(file1)$modification_time
  time2 <- fs::file_info(file2)$modification_time

  if (time1 > time2) {
    return(list(new_left = TRUE, new_right = FALSE))
  }  # Newer file in dir1

  else if (time2 > time1) {
    return(list(new_left = FALSE, new_right = TRUE))
  } # newer file in dir2

  else {return(list(new_left = FALSE, new_right = FALSE))} # Same modification date

}


# Example paths ####
left <- left_path <- paste0(getwd(), "/temp_folder_1")
right <- right_path <- paste0(getwd(), "/temp_folder_2")

#Example usage ####

sync_status_date <- compare_directories(left,
                                        right)

sync_status_date_cont <- compare_directories(left,
                                             right,
                                             by_content = TRUE)

sync_status_content_only <- compare_directories(left,
                                                right,
                                                by_content = TRUE,
                                                by_date = FALSE)
#

