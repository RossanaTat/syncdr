#' Print Synchronization Status
#'
#' @param x object of syncdr_status class created in [compare_directories]
#' @param ... additional arguments
#'
#' @return prints syncdr_status object
#' @export
print.syncdr_status <- function(x, ...) {

  # clean ---------

  cli::cli_h1("Synchronization Summary")
  cli::cli_text("Left Directory: {.path {x$left_path}}")
  cli::cli_text("Right Directory: {.path {x$right_path}}")
  cli::cli_text("Total Common Files: {.strong {nrow(x$common_files)}}")
  cli::cli_text("Total Non-common Files: {.strong {nrow(x$non_common_files)}}")
  cli::cli_rule()

  ## common files -----------

  cli::cli_h1("Common files")

  x$common_files <- x$common_files |>
    fmutate(path = remove_root(x$left_path, path_left)) |>
    fselect(-c(path_left, path_right))

#
  if ("is_new_right" %in% colnames(x$common_files) ||
       "is_new_left" %in% colnames(x$common_files)) {

    x$common_files <- x$common_files |>
      fmutate(modified = fcase(is_new_right == TRUE, "right",
                               is_new_left == TRUE, "left",
                               default = "same date"))  |>
      fselect(path, modified, modification_time_left, modification_time_right, sync_status)
    #fselect(-c(is_new_right, is_new_left))
  } else {
    x$common_files <- x$common_files |>
      fselect(path, is_diff, sync_status)

  }

  print(x$common_files)

  ## non-common files -----------
  cli::cli_h1("Non-common files")

  ncf <- x$non_common_files |>
    fmutate(path_left = remove_root(x$left_path, path_left)) |>
    fmutate(path_right = remove_root(x$right_path, path_right))

  cli::cli_h2("Only in left")
  ncf |>
    fselect(path_left) |>
    fsubset(!is.na(path_left)) |>
    print()

  cat("\n")

  cli::cli_h2("Only in right")
  ncf |>
    fselect(path_right) |>
    fsubset(!is.na(path_right)) |>
    print()

  invisible(x)
}

remove_root <- \(root_path, new_path) {
  gsub(fs::path_dir(root_path), "", new_path)
}
