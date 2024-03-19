
# functions to create temp folders and sub folders

# function to create a temporary folder with 1 or more sub-folders
#  -with folder being created into the current working directory

create_temp_folders <- function(num_subfolders = 1,
                                #num_subfolders = 2,
                                name = "temp_folder") {

  # Create a temporary directory
  #temp_dir <- tempdir()

  # Create a temporary directory inside the working directory
  temp_dir <- file.path(getwd(), name)
  dir.create(temp_dir)


  # Create folders
  folder_names <- paste0("subfolder", "_", seq_len(num_subfolders))
  folder_paths <- file.path(temp_dir, folder_names)
  lapply(folder_paths, dir.create)

  # Call create_subfolders function for each folder
  #lapply(folder_paths, create_subfolders, num_subfolders)

  # Return the path to the temporary directory
  return(temp_dir)
}

# Function to create subfolders and R files within a folder
# create_subfolders <- function(folder_path, num_subfolders, file_name) {
#
#   subfolder_names <- paste0("subfolder", "_", 1:num_subfolders)
#
#
#   subfolder_paths <- file.path(folder_path, subfolder_names)
#
#   lapply(subfolder_paths, dir.create)
#
#   lapply(subfolder_paths,
#          function(subfolder_path) file.create(file.path(subfolder_path, paste0("file", "_", file_name, ".R"))))
# }


# Function to create file in folder ####
create_temp_file <- function(folder_path, file_name) {

  stopifnot(expr = {
    fs::dir_exists(folder_path)
  })

  file_path <- file.path(folder_path, paste0("file", "_", file_name, ".R"))
  file.create(file_path)

  # Return the path of the created file
  return(file_path)

}
# Add sample data to R file in temp dir
write_temporary_files <- function(file_path, num_data_points, random = TRUE) {

  #check path
  stopifnot(expr =
              fs::dir_exists(dirname(file_path))
            )

  # Get all R files in the specified folder and subfolders
  #r_files <- list.files(folder_path, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)

  if (random == TRUE) {

    sample_data <- runif(num_data_points)

  } else

    {sample_data <- seq(1, num_data_points)}

    # Write random data to each R file

    writeLines(sprintf("data <- c(%s)", paste(sample_data, collapse = ",")), file_path)
    return(print("file(s) succesfully written"))
}

## Example usage ####
# create folder with no subfolders

# create folder with 2 subfolders

# create file within specified folder

# write file with random data

# write file with det. data


## TODO: #######################################################################
### Add one wrapper function to create folder-subfolder-file ####
### Make these functions vectorized ####
### Add examples on how to use these functions ####


