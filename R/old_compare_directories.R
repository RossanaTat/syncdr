# old compare directories
old_compare_directories <- function(left_path,
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
      (is.na(path_left) & !is.na(path_right)), "only in right",
      "only in left")
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
      # ftransform(hash_left = hash_files_contents(path_left,
      #                                            path_right)$left_hash,
      #            hash_right = hash_files_contents(path_left,
      #                                             path_right)$right_hash) |>

      ftransform(hash_left = hash_files(path_left),
                 hash_right = hash_files(path_right)) |>
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
      # ftransform(hash_left = hash_files_contents(path_left,
      #                                            path_right)$left_hash,
      #            hash_right = hash_files_contents(path_left,
      #                                             path_right)$right_hash) |>

      ftransform(hash_left = hash_files(path_left),
                 hash_right = hash_files(path_right)) |>


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


