
#' @import joyn
#' @import DT
#' @import fs
#' @import digest
#' @rawNamespace import(collapse, except = fdroplevels)
#' @rawNamespace import(data.table, except = fdroplevels)

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

# compare directories - workhorse function ####
compare_directories <- function(old,
                                new,
                                recurse = TRUE,
                                by = "date",
                                ...) {

  # memo: Add checks on arguments
  #     -> should by match specific options, based on what's available in file_info?


  # Get info on directory 1
  old_dir_info <- directory_info(dir     = old,
                                 recurse = recurse) |>
    ftransform(wo_root = gsub(old, "", path))

  # Get info on directory 2
  new_dir_info <- directory_info(dir     = new,
                                 recurse = recurse) |>
    ftransform(wo_root = gsub(new, "", path))

  # Combine info with a full join
  dt_compare <- joyn::joyn(x                = old_dir_info,
                           y                = new_dir_info,
                           by               = "wo_root",
                           keep_common_vars = TRUE,
                           suffixes         = c("_old", "_new"),
                           match_type       = "1:1",
                           reportvar        = ".joyn",
                           verbose          = FALSE)

  # Track files that are in new but not in old directory
  new_only <- dt_compare |>
    fsubset(.joyn == "y", wo_root) |>
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
    return(list(new_files = new_only, dir_compare = dt_compare, display = table_display))

  }

  else if (by == "content") {

    dt_compare <- dt_compare |>
      fsubset(.joyn == "x & y") |>
      fselect(wo_root, path_old, path_new) |>
      ftransform(file_name = fs::path_file(wo_root),
                 wo_root = NULL)

    dt_compare |>
      ftransform(hash_old = sapply(path_old, digest::digest),
                             hash_new = sapply(path_new, digest::digest)) |>
      ftransform(is_diff = (hash_old != hash_new))


  }

  else {
    # note: to complete
    return(list(new_files = new_only, dir_compare = dt_compare))

  }

} # close function

# Move a file from old to new dir or vice versa

# Re think this function -too general!
update_dir <- function(file_name,
                       source_path,
                       destination_path) {

  compare_dirs <- compare_directories(old = source_path,
                                      new = destination_path)



  # Check if the file is newer in source or destination path


  # If the file is newer in destination than in source, move the file:
  #  source >> destination





}

# My example ####
new <-  "C:/WBG/Packages/pipster"
old <-  "C:/Users/wb621604/OneDrive - WBG/Desktop/pipster"

