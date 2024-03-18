
#' @import joyn
#' @import fs
#' @import digest
#' @rawNamespace import(collapse, except = fdroplevels)
#' @rawNamespace import(data.table, except = fdroplevels)


library(fs)
library(fastverse)
library(joyn)

# Directory info ####
# Should we keep and improve this function or get rid of it?

directory_info <- function(dir,
                           recurse = TRUE,
                           ...) {

  # List of files -also in sub-directories
  files <- fs::dir_ls(path = dir,
                      type = "file",
                      recurse = recurse,
                      ...)

  # Filtering out special files
  files <- files[!grepl("^\\.\\.$|^\\.$", files)]

  # Get all dir info available in file_info
  info_df <- fs::file_info(files)

  return(info_df)

}

# Compare individual files ####

compare_files <- function(file1, file2) {
  if (!fs::file_exists(file2)) return(c(new = TRUE, old = FALSE))  # New file in dir1
  if (!fs::file_exists(file1)) return(c(new = FALSE, old = TRUE))   # Old file in dir2

  # Compare creation times
  time1 <- fs::file_info(file1)$modification_time
  time2 <- fs::file_info(file2)$modification_time

  if (time1 > time2) return(c(new = TRUE, old = FALSE))  # Newer file in dir1
  return(c(new = FALSE, old = TRUE))                        # Older file in dir2
}

# compare directories - workhorse function ####
compare_directories <- function(dir1, #path of directory 1
                                dir2, #path of directory 2
                                recurse = TRUE,
                                by = "date",
                                ...) {

  # memo: Add checks on arguments
  #     -> should by match specific options, based on what's available in file_info?

  # Check directory paths
  stopifnot(exprs = {
    fs::dir_exists(dir1)
    fs::dir_exists(dir2)
  })

  # Get info on directory 1
  info_dir1 <- directory_info(dir     = dir1,
                              recurse = recurse) |>
    ftransform(wo_root = gsub(dir1, "", path))

  # Get info on directory 2
  info_dir2 <- directory_info(dir     = dir2,
                                 recurse = recurse) |>
    ftransform(wo_root = gsub(dir2, "", path))

  # Combine info with a full join
  dt_compare <- joyn::joyn(x                = info_dir1,
                           y                = info_dir2,
                           by               = "wo_root",
                           keep_common_vars = TRUE,
                           suffixes         = c("_old", "_new"),
                           match_type       = "1:1",
                           reportvar        = ".joyn",
                           verbose          = FALSE)

  # Track files that are in new but not in old directory
  dir2_only <- dt_compare |>
    fsubset(.joyn == "y", wo_root, path_new) |>
    ftransform(file_name = fs::path_file(wo_root),
               path = path_new,
               path_new = NULL,
               wo_root = NULL)

  dir1_only <- dt_compare |>
    fsubset(.joyn == "x", wo_root, path_old) |>
    ftransform(file_name = fs::path_file(wo_root),
               path = path_old,
               path_old = NULL,
               wo_root = NULL)

  # Do comparison based on by argument -If by date
  if (by == "date") {

    dt_compare <- dt_compare |>
      fsubset(.joyn == "x & y") |>
      fselect(wo_root, modification_time_old, modification_time_new) |>
      ftransform(file_name = fs::path_file(wo_root),
                 wo_root = NULL,
                 is_new = modification_time_new > modification_time_old)

    return(list(
      unique_files = list(
        dir1_only = dir1_only,
        dir2_only = dir2_only
      ),
      dir_compare = dt_compare
    ))

  }

  else if (by == "content") {

    dt_compare <- dt_compare |>
      fsubset(.joyn == "x & y") |>
      fselect(wo_root, path_old, path_new) |>
      ftransform(file_name = fs::path_file(wo_root),
                 wo_root = NULL)

    dt_compare <- dt_compare |>
      ftransform(hash_old = sapply(path_old, rlang::hash_file),
                             hash_new = sapply(path_new, rlang::hash_file)) |>
      ftransform(is_diff = (hash_old != hash_new),
                 hash_old = NULL,
                 hash_new = NULL)

    return(list(
      unique_files = list(
        dir1_only = dir1_only,
        dir2_only = dir2_only
      ),
      dir_compare = dt_compare
    ))


  }

  else {
    # note: to complete
    return(list(
      unique_files = list(
        dir1_only = dir1_only,
        dir2_only = dir2_only
      ),
      dir_compare = dt_compare
    ))

  }

} # close function


