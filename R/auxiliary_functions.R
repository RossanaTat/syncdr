
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

#' Hash content of files for two directories under comparison, say left and right
#'
#' @param left_path path of files in left directory
#' @param right_path path of files in right directory
#' @return list of hashes of left paths and hashes of right paths
#' @keywords internal
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

