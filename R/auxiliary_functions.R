
#' Filter files that are present in both directories under comparison
#'
#' This function filters the common_files in "syncdr_status" object (resulting from 'compare_directories()') in the following way:
#' (note that filtering is based on left (right) directory depending on the 'dir' argument)
#' * by date only: filter files that are new in left (right)
#' * by date and content: filter files that are new in left(right) AND different
#' * by content only: filter files that are different between the two directories
#'
#' @param sync_status object of class 'syncdr_status' with info on sync status
#'                    and comparison of directories
#' @param by_date logical, TRUE by default
#' @param by_content logical, FALSE by default
#' @return 'syncdr_status' object filtered accordingly
#' @keywords internal

filter_common_files <- function(sync_status,
                                 by_date    = TRUE,
                                 by_content = FALSE,
                                 dir = "left") {
  # check arg
  stopifnot(expr = {
    dir %in% c("left", "right" , "all")
  })

  # Filter by date only #######################################################
  if ((isTRUE(by_date) & isFALSE(by_content))) {

    if(dir == "left") {

      sync_status <- sync_status |>
        fsubset(is_new_left == TRUE) |>
        fselect(path_left, path_right, sync_status)

    } else if (dir == "right") {
      sync_status <- sync_status |>
        fsubset(is_new_right == TRUE) |>
        fselect(path_left, path_right, sync_status)
    }

    else {
      sync_status <- sync_status |>
        fsubset(is_new_right == TRUE | is_new_left == TRUE) |>
        fselect(path_left, path_right, sync_status)
    }

  }

  # Filter by date & content ##################################################
  else if (isTRUE(by_date) & isTRUE(by_content)) {

    if (dir == "left") {
      sync_status <- sync_status |>
        fsubset(is_new_left == TRUE & is_diff == TRUE) |>
        fselect(path_left, path_right, sync_status)
    }

    else if (dir == "right") {
      sync_status <- sync_status |>
        fsubset(is_new_right == TRUE & is_diff == TRUE) |>
        fselect(path_left, path_right, sync_status)
    }

    else {
      sync_status <- sync_status |>
        fsubset((is_new_right == TRUE | is_new_left == TRUE) & is_diff == TRUE) |>
        fselect(path_left, path_right, sync_status)
    }

  }

  # Filter by content only ####################################################
  else if (isFALSE(by_date) & isTRUE(by_content)) {

    sync_status <- sync_status |>
      fsubset(is_diff == TRUE) |>
      fselect(path_left, path_right, sync_status)

  } else

    {sync_status <- sync_status |>
      fselect(path_left, path_right, sync_status)} # if both by_date and content are FALSE

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

# Hash contents TEST ! ################################################

hash_files_contents <- function(left_path, right_path) {

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


