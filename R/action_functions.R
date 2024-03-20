
# Lower level functions to:
#   1. Copy files between directories
#   2. Delete files in one directory


# Copy files between directories ####

copy_files <- function(path_from, #Path of files to copy
                       path_to) #Path of folder where files are copied
  {

  # Check paths exist
  stopifnot(expr = {
    fs::dir_exists(dirname(path_from))
    fs::dir_exists(path_to)
  })

  # Get destination path
  # Call auxiliary function


#TODO ??
  # memo: destination path should be the combination of file path without root and path_to

}


# Create destination path auxiliary function ? ####

# Delete file auxiliary function ####





