
# Function to copy from new to old (in same sub-directory if recurse is TRUE) ####

copy_to_old <- function(dir1,
                        dir2,
                        by      = "date",
                        dircomp = NULL,
                        overwrite = TRUE,
                        recurse = TRUE) {

  if (is.null(dircomp)) {

    dircomp <- compare_directories(dir1 = dir1,
                                   dir2 = dir2,
                                   by = by)

  }

  # Path of files to copy -files that are in new dir but not in old

  to_copy <- dircomp$unique_files$dir2_only[, "path"]

  if (recurse = TRUE) {

    #NOTE: Add checks! recurse TRUE should be valid only if
    #      the same subdirectory in destination folder exists

    # if recurse is TRUE, copy the file from new directory to old directory
    #   -moving the file to the same sub directory as it is in source

    # first get directory portion of new path to look for sub directories
    new_path_dirs <- fs::path_dir(to_copy_R)
    new_path_dirs <- gsub(new, "", new_path_dirs)

    # combine old path with sub directories takem
    destination_path <- fs::path(old, new_path_dirs)

    # check path exists
    if (!dir_exists(destination_path) {
      stop("One or more directories do not exist. Choose recurse = FALSE")
    }

    # Copy file
    fs::file_copy(path = path_to_copy,
                  new_path = destination_path,
                  overwrite = overwrite)
  } else {

    # if recurse is FALSE, copy the file from new dir to old directory

    fs::file_copy(path = path_to_copy,
                  new_path = dir1,
                  overwrite = overwrite)

  }





}


# Function to copy from old to new ####


# Delete files in old that are not available in new ####
