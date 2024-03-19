#' @import DT

library(DT)

# Function to display directory comparison in DT table ####

display_sync_status <- function(
                       sync_status) {

  #take as input either dir1_path and dir2_path or dircomp

  # if (is.null(sync_status)) {
  #
  #   dircomp <- compare_directories(dir1 = dir1,
  #                                  dir2 = dir2,
  #                                  by = by)$dir_compare
  #
  # } else (dircomp <- dircomp$dir_compare)

  # Build DT table

  sync_status = sync_status$common_files

  DT::datatable(sync_status,
                options = list(
                  pageLength = 10, # number of rows to display per page
                  columnDefs = list(
                  list(targets = grep("^is_", colnames(sync_status), value = TRUE),
                       createdCell = JS(
                       "function(td, cellData, rowData, row, col) {if (cellData === true) {
                                    $(td).css({'background-color': '#89CFF0'});
                                  } else {
                                    $(td).css({'background-color': '#E0B0FF'});
                                  }
                                }")
                       )
                  )))
}
