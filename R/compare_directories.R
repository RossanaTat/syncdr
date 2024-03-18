
#' @import joyn
#' @import DT
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

# compare directories ac ####

# compare_directories_ac <- function(dir1, dir2, recurse = FALSE) {
#   # Check directory paths
#   stopifnot(exprs = {
#     fs::dir_exists(dir1)
#     fs::dir_exists(dir2)
#   })
#
#
#   # Initialize results data.table
#   results <- data.table(path1 = character(),
#                         path2 = character(),
#                         new = logical(),
#                         old = logical())
#
#   # Get info of files
#   file_list1 <- fs::dir_ls(dir1,
#                            recurse = recurse,
#                            type = "file") |>
#     fs::file_info() |>
#     # File directory without the root.
#     ftransform(wo_root = gsub(dir1, "", path))
#
#   file_list2 <- fs::dir_ls(dir2,
#                            recurse = recurse,
#                            type = "file") |>
#     fs::file_info() |>
#     # File directory without the root.
#     ftransform(wo_root = gsub(dir2, "", path))
#
#
#
#   dt_compare <- joyn::joyn(file_list1,
#                            file_list2,
#                            by = "wo_root",
#                            suffixes = c("_old", "_new"),
#                            match_type = "1:1")
#
#   # compare files shared in both dirs
#   dt_sf <- dt_compare |>
#     fsubset(.joyn == "x & y")
#
#   comparison <- vector("list", length = nrow(dt_sf))
#   for (i in seq_len(nrow(dt_sf))) {
#
#     file_name <- fs::path_file(file_path)
#
#     # Skip special files (e.g., ., ..)
#     if (fs::file_name(file_name) %in% c(".", "..")) next
#
#     # Check if corresponding file exists in dir2
#
#     # Compare files and add results to data.table
#     comparison[i] <- compare_files(file_list$path_old[i], file_list$path_new[i])
#
#   }
#
#   return(results)
# }


# compare directories - workhorse function ####
compare_directories <- function(dir1,
                                dir2,
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
    fsubset(.joyn == "y", wo_root) |>
    ftransform(file_name = fs::path_file(wo_root),
               wo_root = NULL)

  dir1_only <- dt_compare |>
    fsubset(.joyn == "x", wo_root) |>
    ftransform(file_name = fs::path_file(wo_root),
               wo_root = NULL)

  # Do comparison based on by argument -If by date
  if (by == "date") {

    dt_compare <- dt_compare |>
      fsubset(.joyn == "x & y") |>
      fselect(wo_root, modification_time_old, modification_time_new) |>
      ftransform(file_name = fs::path_file(wo_root),
                 wo_root = NULL,
                 is_new = modification_time_new > modification_time_old)

    # visualization
    table_display <- DT::datatable(dt_compare,
                                   options = list(
                                     pageLength = 10, # number of rows to display per page
                                     columnDefs = list(
                                       list(targets = "is_new",
                                            createdCell = JS(
                                              "function(td, cellData, rowData, row, col) {
                                  if (cellData === true) {
                                    $(td).css({'background-color': '#89CFF0'});
                                  } else {
                                    $(td).css({'background-color': '#E0B0FF'});
                                  }
                                }"
                                            )
                                       )
                                     )))
    return(list(
      unique_files = list(
        dir1_only = dir1_only,
        dir2_only = dir2_only
      ),
      dir_compare = dt_compare,
      display = table_display
    ))

  }

  else if (by == "content") {

    dt_compare <- dt_compare |>
      fsubset(.joyn == "x & y") |>
      fselect(wo_root, path_old, path_new) |>
      ftransform(file_name = fs::path_file(wo_root),
                 wo_root = NULL)

    dt_compare |>
      ftransform(hash_old = sapply(path_old, rlang::hash_file),
                             hash_new = sapply(path_new, rlang::hash_file)) |>
      ftransform(is_diff = (hash_old != hash_new))


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


# My example ####
new <-  "C:/WBG/Packages/pipster"
old <-  "C:/Users/wb621604/OneDrive - WBG/Desktop/pipster"
comparison_results <- compare_directories(dir1, dir2, recurse = TRUE)

dir1 <- "/Users/Rossana/Desktop/pipster-1"
dir2 <- "/Users/Rossana/Desktop/pipster"

