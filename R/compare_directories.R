
#' @import joyn
#' @import fs
#' @import digest
#' @rawNamespace import(collapse, except = fdroplevels)
#' @rawNamespace import(data.table, except = fdroplevels)


library(fs)
library(fastverse)
library(joyn)

#

# compare directories - workhorse function ####

#' Compare directories

#' This function takes two directories as input, say left and right, and compares them.
#' The goal is to return the status of synchronization -at file level- of the two directories.
#' The sync status is returned for both:
#' *1. NON common files, i.e., files that are either only in left or only in right
#' *2. Common files, i.e., files that are in both directories
#' @param left_path path of one directory
#' @param right_path path of another directory
#' @param by_date logical: if TRUE, i.e., the default, it compares the directories based on date of modification of their common files
#' @param by_content logical: default is FALSE.
#'    If TRUE, it compares the directories based on whether (hashed) content of common files is same or different (ADD EXPLANATION OF 3 TYPES)
#' @param recurse If TRUE recurse fully, if a positive number the number of levels to recurse.
#'
#' @return list of class "syncdr_status", with two elements:
#'   *1. Unique files: ...TODO
#'   *2  Common files: ...TODO


# TODO(RT): explain different types of status

compare_directories <- function(left_path,
                                right_path,
                                recurse    = TRUE,
                                by_date    = TRUE,
                                by_content = FALSE,
                                ...) {

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
  #   - unique files are files that are available only in left or only in right
  #   - status is either missing in left: when file is in right but not in left
  #               or     only in left: when file is
  #   -NOTE: available in both here is not needed,
  #          since we are filtering files that are only in left or only in right

  non_common_files <- join_info |>

    # Filter non unique files
    fsubset(.joyn == "y" | .joyn == "x" ) |>
    fselect(path_left, path_right) |>
    ftransform(sync_status = ifelse(
      (is.na(path_left) & !is.na(path_right)), "missing in left",
      ifelse(!is.na(path_left), "only in left", "missing in left"))
      )

  # Compare common files by date only
  if ((isTRUE(by_date) & isFALSE(by_content))) {

    common_files <- join_info |>
      fsubset(.joyn == "x & y") |>
      fselect(path_left, path_right, modification_time_left, modification_time_right)

    common_files$is_new <- mapply(compare_files, common_files$path_left, common_files$path_right)

    common_files <- common_files |>
      ftransform(sync_status = ifelse(
        is_new == TRUE, "newer in left, older in right dir",
        "older in left, newer in right dir"
      )) |>
      fselect(path_left, path_right, is_new, modification_time_left, modification_time_right, sync_status)

  }

  else if (isTRUE(by_date) & isTRUE(by_content)) {

    common_files <- join_info |>
      fsubset(.joyn == "x & y") |>
      fselect(path_left, path_right, modification_time_left, modification_time_right)

    common_files$is_new <- mapply(compare_files, common_files$path_left, common_files$path_right)

    common_files <- common_files |>
      fsubset(is_new == TRUE) |>
      ftransform(hash_left  = sapply(path_left, rlang::hash_file),    #To fix: re try to replace with digest
                 hash_right = sapply(path_right, rlang::hash_file)) |>
      ftransform(is_diff    = (hash_left != hash_right),
                 hash_left  = NULL,
                 hash_right = NULL) |>
      ftransform(sync_status = ifelse(
        (is_new == TRUE & is_diff == TRUE), "newer in left, different content than right",
        ifelse((is_new == TRUE & is_diff == FALSE), "newer in left, same content as right",
               "older in left, same content as right")
      )) |>
      fselect(path_left, path_right, is_new, is_diff, sync_status)


  }

  else if (isFALSE(by_date) & isTRUE(by_content)) {

    common_files <- join_info |>
      fsubset(.joyn == "x & y") |>
      fselect(path_left, path_right)

    common_files <- common_files |>
      ftransform(hash_left  = sapply(path_left, rlang::hash_file),    #To fix: re try to replace with digest
                 hash_right = sapply(path_right, rlang::hash_file)) |>
      ftransform(is_diff    = (hash_left != hash_right),
                 hash_left  = NULL,
                 hash_right = NULL) |>
      ftransform(sync_status = ifelse(
        is_diff == TRUE, "different content", "same content"
      )) |>
      fselect(path_left, path_right, is_diff, sync_status)


  }

  else { # if both by_date is FALSE and by_content is FALSE

    common_files <- join_info |>
      fsubset(.joyn == "x & y") |>
      fselect(path_left, path_right)
  }

  sync_status = list(
    common_files = common_files,
    non_common_files = non_common_files
  )

  class(sync_status) <- "syncdr_status"

  return(sync_status)


} # close function

# Auxiliary functions ####
# Q: should I move these functions to another, say, auxiliary_functions .R file?

#Directory info auxiliary function ####

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
    ftransform(wo_root = gsub(dir, "", path))

  # Add vriable of path without root

  return(info_df)

}

# Compare individual files auxiliary function ####

compare_files <- function(file1, file2) {
  if (!fs::file_exists(file2)) return(new = TRUE)  # New file in dir1
  if (!fs::file_exists(file1)) return(new = FALSE)   # Old file in dir1

  # Compare creation times
  time1 <- fs::file_info(file1)$modification_time
  time2 <- fs::file_info(file2)$modification_time

  if (time1 > time2) return(new = TRUE)  # Newer file in dir1
  return(new = FALSE)                        # Older file in dir2
}


# Example paths ####
left  <- paste0(getwd(), "/temp_folder_1")
right <- paste0(getwd(), "/temp_folder_2")

