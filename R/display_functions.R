#' Display status of synchronization/comparison info between two directories in DT table
#'
#' @param sync_status_files object of `compare_directories()` output, either common_files or non_common_files
#' @return DT table showing the comparison between the two directories
#'         together with their synchronization status
#' @export
display_sync_status <- function(sync_status_files) {

  # Build DT table
  DT::datatable(sync_status_files,
                options = list(
                  pageLength = 10, # number of rows to display per page
                  columnDefs = list(
                    list(targets = grep("^is_", colnames(sync_status_files), value = TRUE),
                         createdCell = DT::JS(
                           "function(td, cellData, rowData, row, col) {
                            if (cellData === true) {
                              $(td).css({'background-color': '#F8F4FF'});
                            } else {
                              $(td).css({'background-color': '#F0F8FF'});
                            }
                          }"
                         )
                    ),
                    list(targets = grep("sync_status", colnames(sync_status_files), value = TRUE),
                         createdCell = DT::JS(
                           "function(td, cellData, rowData, row, col) {
                             if (cellData.includes('different content') ||
                                 cellData.includes('same date') ||
                                 cellData.includes('only in right')) {
                              $(td).css({'background-color': '#a9def9'});
                            } else {
                              $(td).css({'background-color': '#e4c1f9'});
                            }
                          }"
                         )
                    )
                  )
                )
  )

}

# Example usage:

#Compare directories with 'compare_directories()'
# sync.env <- toy_dirs()
# left <- sync.env$left
# right <- sync.env$right
#
# sync_status <- new_compare_dir(left, right)
# display_sync_status(sync_status$common_files)
# display_sync_status(sync_status$non_common_files)

# sync_status_date_cont <- compare_directories(left,
#                                              right,
#                                              by_content = TRUE)
# display_sync_status(sync_status_date_cont$common_files)
# display_sync_status(sync_status_date_cont$non_common_files)

# sync_status_content <- compare_directories(left,
#                                            right,
#                                            by_content = TRUE,
#                                            by_date = FALSE)
# display_sync_status(sync_status_content$common_files)
# display_sync_status(sync_status_content$non_common_files)


#' Display tree structure of one (or two) directory
#'
#' @param path_left path of left directory
#' @param path_right path of right directory
#' @param recurse logical, default to TRUE: show also sub-directories
#'
#' @return directories tree
#' @export
display_dir_tree <- function(path_left  = NULL,
                             path_right = NULL,
                             recurse = TRUE) {

  if (!is.null(path_left)) {

    style_msgs(color_name = "pink",
               text = paste0("(\u2190)", "Left directory structure:\n"))

    #cat(paste0("\033[1;38;5;170m", "(\u2190)", " Left directory structure:\n", "\033[0m"))
    #fs::dir_tree(sync_status$left_path)
    fs::dir_tree(path_left)
  }

  if (!is.null(path_right)) {

    style_msgs(color_name = "pink",
               text = paste0("(\u2192)", "Right directory structure:\n"))

    #cat(paste0("\033[1;38;5;170m", "(\u2192)", " Right directory structure :\n", "\033[0m"))

    #fs::dir_tree(sync_status$right_path)
    fs::dir_tree(path_right)

  }

  invisible(TRUE)

}
