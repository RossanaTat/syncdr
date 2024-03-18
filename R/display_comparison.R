#' @import DT

library(joyn)
library(DT)

# Function to display directory comparison in DT table ####

display_dt <- function(dir1,
                       dir2,
                       dircomp = NULL) {
  #take as input either dir1_path and dir2_path or dircomp

  if (is.null(dircomp)) {
    dircomp <- compare_directories(dir1 = dir1,
                                   dir2 = dir2)
  }
}
