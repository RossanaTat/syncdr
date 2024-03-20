#' @import DT

library(DT)

# Function to display directory comparison in DT table ####

# Example usage below:
# sync_status <- compare_directories(left, right)
# display_sync_status(sync_status$common_files)
# display_sync_status(sync_status$non_common_files)



display_sync_status <- function(
                       sync_status) {

  # Build DT table

  #sync_status = sync_status$common_files

  # DT::datatable(sync_status,
  #               options = list(
  #                 pageLength = 10, # number of rows to display per page
  #                 columnDefs = list(
  #                 list(targets = grep("^is_", colnames(sync_status), value = TRUE),
  #                      createdCell = JS(
  #                      "function(td, cellData, rowData, row, col) {if (cellData === true) {
  #                                   $(td).css({'background-color': '#89CFF0'});
  #                                 } else {
  #                                   $(td).css({'background-color': '#E0B0FF'});
  #                                 }
  #                               }")
  #                      )
  #                 )))

  # DT::datatable(sync_status,
  #               options = list(
  #                 pageLength = 10, # number of rows to display per page
  #                 columnDefs = list(
  #                   list(targets = grep("^is_", colnames(sync_status), value = TRUE),
  #                        createdCell = JS(
  #                          "function(td, cellData, rowData, row, col) {
  #                           if (cellData === true) {
  #                             $(td).css({'background-color': '#c7f9cc'});
  #                           } else {
  #                             $(td).css({'background-color': '#fdffb6'});
  #                           }
  #                         }"
  #                        )
  #                   ),
  #                   list(targets = grep("sync_status", colnames(sync_status), value = TRUE),
  #                        createdCell = JS(
  #                          "function(td, cellData, rowData, row, col) {
  #                           if (cellData.includes('missing') || cellData.startsWith('older')) {
  #                             $(td).css({'background-color': '#FBEC5D'});
  #                           } else if (cellData.includes('only') || cellData.startsWith('newer')) {
  #                             $(td).css({'background-color': '#90EE90'});
  #                           }
  #                         }"
  #                        )
  #                   )
  #                 )
  #               )
  #)

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
