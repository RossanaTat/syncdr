
# Filter files -common files only ####
# Filter by date only; by date & content, by content only

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

# Aux function to filter non common files

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


