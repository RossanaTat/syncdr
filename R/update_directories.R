
# Function to copy from new to old ####

copy_to_old <- function(dir1,
                        dir2,
                        by      = "date",
                        dircomp = NULL,
                        overwrite = TRUE,
                        recurse = FALSE) {

  if (is.null(dircomp)) {

    dircomp <- compare_directories(dir1 = dir1,
                                   dir2 = dir2,
                                   by = by)

  }

  # Path of files to copy -files that are in new dir but not in old

  dir1 <- dir1
  dir2 <- dir2
  to_copy<- dircomp$unique_files$dir2_only[, "path"]
  to_copy_test <- to_copy[1:2,]


  if (recurse == TRUE) {

    #NOTE: Add checks! recurse TRUE should be valid only if
    #      the same subdirectory in destination folder exists

    # if recurse is TRUE, copy the file from new directory to old directory
    #   -moving the file to the same sub directory as it is in source

    # first get directory portion of new path to look for sub directories
    #new_path_dirs <- fs::path_dir(to_copy_test)
    #new_path_dirs <- gsub(new, "", new_path_dirs)

    to_copy_test <- to_copy_test |>
      ftransform(path_dir = fs::path_dir(to_copy_test$path)) |>
      ftransform(path_dir = gsub(new, "", path_dir)) |>
      # combine old path with sub directories
      ftransform(destination_path = fs::path(old, path_dir))

    if (any(fs::dir_exists(to_copy_test$destination_path)) == FALSE) {
      cli::abort("At least one destination path exists.")
    }



    # Apply copy_files function to each row of the dataframe
    mapply(copy_files, to_copy_test$path, to_copy_test$destination_path)

  } else {

    # if recurse is FALSE, copy the file from new dir to old directory

    purrr::map(to_copy_test$path,
               ~ file_copy(path = .x, new_path = dir1, overwrite = TRUE))

  }

}


# Function to copy from old to new ####


# Delete files in old that are not available in new ####

# Auxiliary functions ####

# Create an auxiliary function to copy files
copy_files <- function(path, destination_path) {
  fs::file_copy(path = path, new_path = destination_path, overwrite = TRUE)
}
