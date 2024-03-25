
compare_directories_new <- function(left_path,
                                    right_path,
                                    recurse = TRUE,
                                    by_date = TRUE,
                                    by_content = FALSE) {

  # Check directory paths
  stopifnot(exprs = {
    fs::dir_exists(left_path)
    fs::dir_exists(right_path)
  })

  # Get info on directory 1, i.e. left
  info_left <- directory_info(dir = left_path,
                              recurse = recurse)
  # Get info on directory 2, i.e., right
  info_right <- directory_info(dir = right_path,
                               recurse = recurse)

  # Combine info with a full join to keep all information
  join_info <- joyn::joyn(x = info_left,
                          y = info_right,
                          by = "wo_root",
                          keep_common_vars = TRUE,
                          suffixes = c("_left", "_right"),
                          match_type = "1:1",
                          reportvar = ".joyn",
                          verbose = FALSE)

  # Unique file status
  non_common_files <- as.data.frame(
    join_info |>
    fsubset(.joyn == "y" | .joyn == "x") |>
    fselect(path_left, path_right) |>
    ftransform(sync_status = ifelse(
      (is.na(path_left) & !is.na(path_right)), "missing in left, only in right",
      ifelse(!is.na(path_left), "only in left", "missing in left, only in right"))
    )
    )

  # Compare common files
  common_files <- join_info |>
    fsubset(.joyn == "x & y") |>
    fselect(path_left,
            path_right,
            modification_time_left,
            modification_time_right)

  if (by_date) {
    compared_times <- compare_modification_times(common_files$modification_time_left,
                                                 common_files$modification_time_right)
    common_files <- cbind(common_files,
                          compared_times)
      #fselect(path_left, path_right, is_new_left, is_new_right, modification_time_left,
      #        modification_time_right, sync_status)
  }

  if (by_content) {

    # If by_date TRUE, first filter files that are new in either left or right directory
    if(by_date) {
      common_files <- common_files |>
        fsubset(is_new_left == TRUE | is_new_right == TRUE)
        #to fix first -filter_common_files(dir = "all")
    }

    compared_contents <- compare_file_contents(common_files$path_left,
                                               common_files$path_right)

    common_files <- cbind(common_files,
                          compared_contents)
      #fselect(path_left, path_right, is_diff, sync_status)
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
}


# Example paths ####
left <- left_path <- paste0(getwd(), "/temp_folder_1")
right <- right_path <- paste0(getwd(), "/temp_folder_2")

#Example usage ####
# sync_status_date <- compare_directories(left,
#                                         right)
#
# sync_status_date_cont <- compare_directories(left,
#                                              right,
#                                              by_content = TRUE)
#
# sync_status_content_only <- compare_directories(left,
#                                                 right,
#                                                 by_content = TRUE,
#                                                 by_date = FALSE)
#

