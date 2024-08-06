#' Display status of synchronization/comparison info between two directories in DT table
#'
#' @param sync_status_files object of `compare_directories()` output, either common_files or non_common_files
#' @param left_path A character string specifying the path to left directory.
#' @param right_path A character string specifying the path to right directory.
#' @return DT table showing the comparison between the two directories
#'         together with their synchronization status
#' @export
display_sync_status <- function(sync_status_files,
                                left_path,
                                right_path) {

  # clean display of paths
  sync_status_files <- sync_status_files |>
    fmutate(path_left = gsub(left_path, "", path_left)) |>
    fmutate(path_right = gsub(right_path, "", path_right))

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
    fs::dir_tree(path_left)

  }

  if (!is.null(path_right)) {
    style_msgs(color_name = "pink",
               text = paste0("(\u2192)", "Right directory structure:\n"))
    fs::dir_tree(path_right)

  }


  invisible(TRUE)
}

# AUX FUNCTION TO DISPLAY FILES TO COPY OR DELETE

# show_action_on_files <- function(path_to_files,
#                                  directory,
#                                  action = c("copy",
#                                             "delete")) {
#
#
#   action <- match.arg(action) |>
#     switch("copy"    = "To be copied from left to right",
#             "delete" = "To be deleted from right")
#
#   path_to_files$Action <- action
#
#   colnames(path_to_files) <- c("Paths",
#                                "Action")
#
#   path_to_files <- path_to_files |>
#     fmutate(Paths = gsub(directory, "", Paths))
#
#   # Determine the background color based on the action
#   bg_color <- if (action == "To be copied from left to right") {
#     "#cbf3f0"
#   } else {
#     "#ffbf69"
#   }
#
#   datatable <- DT::datatable(path_to_files,
#                 colnames = c("Files",
#                              #"Files in Left",
#                              "Action")) |>
#     DT::formatStyle(
#       'Action',
#       backgroundColor = bg_color
#     )
#
#   return(datatable)
#
#
# }
#
#

# option 2
show_action_on_files <- function(path_to_files,
                                 directory,
                                 action = c("copy", "delete")) {
  action <- match.arg(action) |>
    switch("copy" = "To be copied from left to right",
           "delete" = "To be deleted from right")

  path_to_files$Action <- action

  colnames(path_to_files) <- c("Paths", "Action")

  path_to_files <- path_to_files |>
    fmutate(Paths = gsub(directory, "", Paths))

  # Print the table using knitr::kable for console-friendly formatting
  print(kable(path_to_files, format = "pipe", col.names = c("Files", "Action")))
}

