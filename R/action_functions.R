
# Copy files between directories ####

copy_files_to_right <- function(left_dir,
                                right_dir,
                                files_to_copy,
                                recurse = TRUE) {

  if (recurse == TRUE) {

    files_to_copy <- files_to_copy |>
      ftransform(wo_root_left = gsub(left_dir, "", path_left)) |>
      ftransform(path_from    = path_left,
                 path_to      = fs::path(right_dir, wo_root_left))
  }

  else {
    files_to_copy <- files_to_copy |>
      ftransform(path_from    = path_left,
                 path_to      = right_dir)
  }

  # Copy files
  mapply(fs::file_copy,
         files_to_copy$path_from,
         files_to_copy$path_to,
         MoreArgs = list(overwrite = TRUE))

  invisible(TRUE)
}

# copy to left - ideally we can keep only one function
# (say, copy_from_source_to_destination), and how you specify the inputs determines the direction of the copy!
# for now, I am keeping both to generate less confusion

copy_files_to_left <- function(left_dir,
                               right_dir,
                               files_to_copy,
                               recurse = TRUE) {


  # Check/create source and destination path

  if (recurse == TRUE) {

    files_to_copy <- files_to_copy |>
      ftransform(wo_root_right = gsub(right_dir, "", path_right)) |>
      ftransform(path_from    = path_right,
                 path_to      = fs::path(left_dir, wo_root_right))

  } else {

    files_to_copy <- files_to_copy |>
      ftransform(path_from    = path_right,
                 path_to      = left_dir)

  }

  # Copy files
  mapply(fs::file_copy,
         files_to_copy$path_from,
         files_to_copy$path_to,
         MoreArgs = list(overwrite = TRUE))

  invisible(TRUE)
}


