#' Display status of synchronization/comparison info between two directories in DT table
#'
#' @param sync_status object of class `"syncdr_status"`, result of `compare_directories()`
#' @return DT table showing the comparison between the two directories
#'         together with their synchronization status
#' @export
display_sync_status <- function(
                       sync_status) {

  # Build DT table
  DT::datatable(sync_status,
                options = list(
                  pageLength = 10, # number of rows to display per page
                  columnDefs = list(
                    list(targets = grep("^is_", colnames(sync_status), value = TRUE),
                         createdCell = JS(
                           "function(td, cellData, rowData, row, col) {
                            if (cellData === true) {
                              $(td).css({'background-color': '#c7f9cc'});
                            } else {
                              $(td).css({'background-color': '#fdffb6'});
                            }
                          }"
                         )
                    ),
                    list(targets = grep("sync_status", colnames(sync_status), value = TRUE),
                         createdCell = JS(
                           "function(td, cellData, rowData, row, col) {
                            var is_new_left = rowData[3];
                            var is_new_right = rowData[4];
                            if (is_new_left == true | is_new_right == true | cellData.includes('only in left') ) {
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

# Compare directories with 'compare_directories()'
# left <- paste0(getwd(), "/temp_folder_1")
# right <- paste0(getwd(), "/temp_folder_2")
# sync_status <- compare_directories(left, right)
# display_sync_status(sync_status$common_files)
# display_sync_status(sync_status$non_common_files)
#
# sync_status_date_cont <- compare_directories(left,
#                                              right,
#                                              by_content = TRUE)
# display_sync_status(sync_status_date_cont$common_files)
# display_sync_status(sync_status_date_cont$non_common_files)
#
# sync_status_content <- compare_directories(left,
#                                            right,
#                                            by_content = TRUE,
#                                            by_date = FALSE)
# display_sync_status(sync_status_content$common_files)
# display_sync_status(sync_status_content$non_common_files)


#' Display tree structure of two directories under comparison
#'
#' @param path_left path of left directory
#' @param path_right path of right directory
#' @param recurse logical, default to TRUE: show also sub-directories
display_dir_tree <- function(path_left,
                             path_right,
                             recurse = TRUE) {

  cat("Left directory structure:\n")
  fs::dir_tree(sync_status$left_path)

  cat("\nRight directory structure :\n")
  fs::dir_tree(sync_status$right_path)

  invisible(TRUE)

}

##### NEW DISPLAY SYNC STATUS - ATTEMPT 1 #####################################
# display_new <- function(
#     sync_status) {
#
#   # Build DT table
#   DT::datatable(sync_status,
#                 options = list(
#                   pageLength = 10, # number of rows to display per page
#                   columnDefs = list(
#                     list(targets = grep("^is_", colnames(sync_status), value = TRUE),
#                          createdCell = JS(
#                            "function(td, cellData, rowData, row, col) {
#                             if (cellData === true) {
#                               $(td).css({'background-color': '#c7f9cc'});
#                             } else {
#                               $(td).css({'background-color': '#fdffb6'});
#                             }
#                           }"
#                          )
#                     ),
#                     list(targets = grep("^sync", colnames(sync_status), value = TRUE),
#                          createdCell = JS(
#                            "function(td, cellData, rowData, row, col) {
#                             if ( cellData.includes('content') | cellData.includes('only in left') ) {
#                               $(td).css({'background-color': '#a9def9'});
#                             } else {
#                               $(td).css({'background-color': '#e4c1f9'});
#                             }
#                           }"
#                          )
#                     )
#                   )
#                 )
#   )
#
# }
