
# functions to create temp folders and sub folders

# function to create temporary folders with subfolders and R files
create_temp_folders <- function(num_folders = 3,
                                num_subfolders = 2,
                                name = "temp_folder") {

  # Create a temporary directory
  #temp_dir <- tempdir()

  # Create a temporary directory inside the working directory
  temp_dir <- file.path(getwd(), name)
  dir.create(temp_dir)


  # Create folders
  folder_names <- paste0("folder", "_", seq_len(num_folders))
  folder_paths <- file.path(temp_dir, folder_names)
  lapply(folder_paths, dir.create)

  # Call create_subfolders function for each folder
  lapply(folder_paths, create_subfolders, num_subfolders)

  # Return the path to the temporary directory
  return(temp_dir)
}

# Function to create subfolders and R files within a folder
create_subfolders <- function(folder_path, num_subfolders) {

  subfolder_names <- paste0("subfolder", "_", 1:num_subfolders)


  subfolder_paths <- file.path(folder_path, subfolder_names)

  lapply(subfolder_paths, dir.create)

  lapply(subfolder_paths,
         function(subfolder_path) file.create(file.path(subfolder_path, paste0("file", "_", letters[seq_len(num_subfolders)], ".R"))))
}

# TODO: Add function to add data to files/create files with data

# Add sample data to R files in folders
write_temporary_files <- function(folder_path, num_data_points, random = TRUE) {

  #check path
  stopifnot(expr =
              fs::dir_exists(folder_path))

  # Get all R files in the specified folder and subfolders
  r_files <- list.files(folder_path, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)

  if (random == TRUE) {

    sample_data <- runif(num_data_points)

  } else

    {sample_data <- seq(1, num_data_points)}

    # Write random data to each R file
  lapply(r_files, function(file) {
    writeLines(sprintf("data <- c(%s)", paste(sample_data, collapse = ",")), file)
  })

  return(print("files succesfully written"))
}



