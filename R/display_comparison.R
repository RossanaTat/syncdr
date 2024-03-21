#' @import DT

library(DT)

#' Display status of synchronization/comparison info between two directories in DT table
#'
#' @param sync_status object of class `"syncdr_status"`, result of `compare_directories()`
#' @return DT table showing the comparison between the two directories
#'         together with their synchronization status
#' @examples
#' # Compare directories with 'compare_directories()'
#' sync_status <- compare_directories(left_path, right_path)
#' display_sync_status(sync_status$common_files)
#' display_sync_status(sync_status$non_common_files)
#'
#' sync_status_date_cont <- compare_directories(left,
#'                                              right,
#'                                              by_content = TRUE)
#' display_sync_status(sync_status_date_cont$common_files)
#' display_sync_status(sync_status_date_cont$non_common_files)
#'
#' sync_status_content <- compare_directories(left,
#'                                            right,
#'                                            by_content = TRUE,
#'                                            by_date = FALSE)
#' display_sync_status(sync_status_content$common_files)
#' display_sync_status(sync_status_content$non_common_files)
#'
#'
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
                            var is_new = rowData[3];
                            var is_diff = rowData[4];
                            if (is_new == true | is_diff == true | cellData.includes('only in left') ) {
                              $(td).css({'background-color': '#90EE90'});
                            } else {
                              $(td).css({'background-color': '#FBEC5D'});
                            }
                          }"
                         )
                    )
                  )
                )
  )


}
