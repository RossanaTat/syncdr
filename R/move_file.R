# MEMO: Add documentation comments

# Function to move files from left to right
#   if left is newer than right

move_file_r <- function(old,
                          new,
                          by = "date",
                          recurse = TRUE,
                          dircomp = NULL) {

  # Q: think about how to handle arguments like recurse

  # Add checks: either provide old and new or provide dircomp
  if (is.null(dircomp)) {

    dircomp <- compare_directories(old = old,
                                   new = new,
                                   by = by,
                                   recurse = recurse)

  }

  # files that are newer in left (old) than in right (new)
  to_update <- dircomp$dir_compare |>
    fsubset(is_new != TRUE) |>
    fselect(file_name)

  # check fs::file_move


}
