
# functions to create temp folders and sub folders

# function to create a temporary folder with 1 or more sub-folders
#  -with folder being created into the current working directory

create_temp_folders <- function(num_subfolders = 1,
                                name = "temp_folder") {


  # Create a temporary directory inside the working directory
  temp_dir <- file.path(getwd(), name)
  dir.create(temp_dir)


  # Create folders
  folder_names <- paste0("subfolder", "_", seq_len(num_subfolders))
  folder_paths <- file.path(temp_dir, folder_names)
  lapply(folder_paths, dir.create)

  # Return the path to the temporary directory
  return(temp_dir)
}


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

    # Write data in file

    writeLines(sprintf("sample_data <- c(%s)", paste(sample_data, collapse = ",")), file_path)
    return(print("file(s) succesfully written"))
}

## Example usage ####

# #create temporary folder 1 with 1 subfolder
# create_temp_folders(name = "temp_folder_1")
#
# # create temporary folder 2 with 2 subfolders
# create_temp_folders(name = "temp_folder_2", num_subfolders = 2)
#
# # add files
# create_temp_file(folder_path = paste0(getwd(), "/temp_folder_1"),
#                  file_name = "A")
#
# create_temp_file(folder_path = paste0(getwd(), "/temp_folder_2"),
#                  file_name = "A")
#
# create_temp_file(folder_path = paste0(getwd(), "/temp_folder_2"),
#                  file_name = "C")
#
# create_temp_file(folder_path = paste0(getwd(), "/temp_folder_1"),
#                  file_name = "B")
#
# create_temp_file(folder_path = paste0(getwd(), "/temp_folder_1/subfolder_1"),
#                  file_name = "D")
#
# create_temp_file(folder_path = paste0(getwd(), "/temp_folder_2/subfolder_1"),
#                  file_name = "D")
#
#
# # write file with some data
# write_temporary_files(file_path = paste0(getwd(), "/temp_folder_1/file_A.R"),
#                       num_data_points = 10, random = FALSE)
#
# write_temporary_files(file_path = paste0(getwd(), "/temp_folder_2/file_A.R"),
#                       num_data_points = 10, random = FALSE)
#
# write_temporary_files(file_path = paste0(getwd(), "/temp_folder_1/subfolder_1/file_D.R"),
#                       num_data_points = 10, random = TRUE)
#
# write_temporary_files(file_path = paste0(getwd(), "/temp_folder_2/subfolder_1/file_D.R"),
#                       num_data_points = 10, random = TRUE)






## TODO: #######################################################################
### Add one wrapper function to create folder-subfolder-file ####
### Make these functions vectorized ####
### Add examples on how to use these functions ####


