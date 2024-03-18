#' @import DT

library(DT)

# Function to display directory comparison in DT table ####

display_dt <- function(dir1, # path of dir1
                       dir2, # path of dir2
                       by = "date",
                       dircomp = NULL) {

  #take as input either dir1_path and dir2_path or dircomp

  if (is.null(dircomp)) {

    dircomp <- compare_directories(dir1 = dir1,
                                   dir2 = dir2,
                                   by = by)$dir_compare

  } else (dircomp <- dircomp$dir_compare)

  # Build DT table

  DT::datatable(dircomp,
                options = list(
                  pageLength = 10, # number of rows to display per page
                  columnDefs = list(
                  list(targets = grep("^is_", colnames(dircomp), value = TRUE),
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
