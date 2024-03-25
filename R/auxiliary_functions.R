
#' Filter files that are present in both directories under comparison
#'
#' This function filters common_files in "syncdr_status" object (resulting from 'compare_directories()') in the following way:
#' (note that filtering is based on left (right) directory depending on the 'dir' argument)
#' * by date only: filter files that are new in left (right or either left/right)
#' * by date and content: filter files that are new in left(right  or either left/right) AND different
#' * by content only: filter files that are different between the two directories
#'
#' @param sync_status object of class 'syncdr_status' with info on sync status
#'                    and comparison of directories (common files only)
#' @param by_date logical, TRUE by default
#' @param by_content logical, FALSE by default
#' @param dir character specifying master(primary) directory, either left, right or all
#' @return 'syncdr_status' object filtered accordingly
#' @keywords internal
#'
filter_common_files <- function(sync_status,
                                by_date    = TRUE,
                                by_content = FALSE,
                                dir        = "left") {

  # Check argument
  stopifnot(
    dir %in% c("left", "right", "all")
  )

  # Define date filter based on arguments
  date_filter <- if (by_date) {

    if (dir == "left") {
      sync_status$is_new_left
    } else if (dir == "right") {
      sync_status$is_new_right
    } else if(dir == "all") {
      sync_status$is_new_left | sync_status$is_new_right
    }
    } else {
    TRUE  # If by_date is false, include all dates
  }

  # Define content filter based on arguments
  content_filter <- if (by_content) {
    sync_status$is_diff
  } else {
    TRUE
    }

  # Filter sync_status accordingly
  sync_status <- sync_status |>
    fsubset(date_filter & content_filter) |>
    fselect(path_left,
            path_right,
            sync_status)

  return(sync_status)
}


#' Filter files that are NOT common between the two directories under comparison
#'
#' This function filters non common files in "syncdr_status" object (resulting from 'compare_directories()')

#'
#' @param sync_status object of class 'syncdr_status' with info on sync status
#'                    and comparison of directories
#' @param dir character, either "left", "right", "all" (both directories)
#' @return 'syncdr_status' object filtered accordingly
#' @keywords internal
#'
filter_non_common_files <- function(sync_status,
                                    dir = "left") {

  stopifnot(expr = {
    dir %in% c("left", "right" , "all")
  })

  if (dir == "left") {

    sync_status <- sync_status |>
      fsubset(!is.na(path_left)) |>
      fselect(path_left, path_right, sync_status)

  } else if (dir == "right") {

    sync_status <- sync_status |>
      fsubset(!is.na(path_right)) |>
      fselect(path_left, path_right, sync_status)

  } else {sync_status <- sync_status |>
    fselect(path_left, path_right, sync_status)}

  return(sync_status)

}

#' Hash content of files of two directories under comparison, say left and right
#'
#' @param left_path path of files in left directory
#' @param right_path path of files in right directory
#' @return list of hashes of files from left paths and hashes of files from right paths
#' @keywords internal
#'
hash_files_contents <- function(left_path,
                                right_path) {

  # Compute hash for left files
  left_hashes <- lapply(left_path,
                        function(path) digest::digest(object = path,
                                                      algo = "sha256",
                                                      file = TRUE))

  # Compute hash for right files
  right_hashes <- lapply(right_path, function(path) digest::digest(object = path,
                                                                   algo = "sha256",
                                                                   file = TRUE))

  return(list(
    left_hash = unlist(left_hashes),
    right_hash = unlist(right_hashes)
    ))
}

#' Get directory information
#' @param dir character string, path of directory
#' @param recurse If TRUE recurse fully, if a positive number the number of levels to recurse
#' @return data frame with info on directory's files
#'
#' @keywords internal
#'
directory_info <- function(dir,
                           recurse = TRUE,
                           ...) {

  # List of files -also in sub-directories
  files <- fs::dir_ls(path = dir,
                      type = "file",
                      recurse = recurse)

  # Filtering out special files
  files <- files[!grepl("^\\.\\.$|^\\.$", files)]

  # Get all dir info available in file_info
  info_df <- fs::file_info(files) |>
    ftransform(wo_root = gsub(dir, "", path),
               modification_time = as.POSIXct(modification_time)) #add without root var

  return(info_df)

}

#' Compare date of last modification of two files and determine sync status
#'
#' @keywords internal
#'
compare_modification_times <- function(modification_time_left,
                                       modification_time_right) {

  is_new_left  <- modification_time_left > modification_time_right
  is_new_right <- modification_time_right > modification_time_left

  sync_status_date <- ifelse(
    is_new_left & !is_new_right, "newer in left, older in right dir",
    ifelse(!is_new_left & is_new_right, "older in left, newer in right dir", "same date")
  )

  return(list(
    is_new_left = is_new_left,
    is_new_right = is_new_right,
    sync_status_date = sync_status_date)
    )

}

#' Compare contents of two files and determine their sync status
#'
#' @keywords internal
#'
compare_file_contents <- function(path_left,
                                  path_right) {

  hash_left <- hash_files_contents(path_left,
                                   path_right)$left_hash
  hash_right <- hash_files_contents(path_left,
                                    path_right)$right_hash

  is_diff <- (hash_left != hash_right)

  sync_status_content <- ifelse(
    is_diff, "different content",
    "same content"
  )
  return(list(is_diff = is_diff,
              sync_status_content = sync_status_content))
}

# Compare individual files auxiliary function -not used for the moment ####
#
# compare_files <- function(file1, file2) {
#
#   if (!fs::file_exists(file2)) return(list(new_left = TRUE, new_right = FALSE))  # New file in dir1
#   if (!fs::file_exists(file1)) return(list(new_left = FALSE, new_right = TRUE))   # Old file in dir1
#
#   # Compare creation times
#   time1 <- fs::file_info(file1)$modification_time
#   time2 <- fs::file_info(file2)$modification_time
#
#   if (time1 > time2) {
#     return(list(new_left = TRUE, new_right = FALSE))
#   }  # Newer file in dir1
#
#   else if (time2 > time1) {
#     return(list(new_left = FALSE, new_right = TRUE))
#   } # newer file in dir2
#
#   else {return(list(new_left = FALSE, new_right = FALSE))} # Same modification date
#
# }
