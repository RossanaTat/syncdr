
# Copy files between directories ####

copy_files_to_right <- function(left_dir,
                                right_dir,
                                files_to_copy) {


  # Check/create source and destination path

  files_to_copy <- files_to_copy |>
    ftransform(wo_root_left = gsub(left_dir, "", path_left)) |>
    ftransform(path_from    = path_left,
               path_to      = fs::path(right_dir, wo_root_left))

  # Copy files
  mapply(fs::file_copy,
         files_to_copy$path_from,
         files_to_copy$path_to,
         MoreArgs = list(overwrite = TRUE))

  invisible(TRUE)
}


# Delete file auxiliary function - not sure is needed ####





