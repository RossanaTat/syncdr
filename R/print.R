#' Title
#'
#' @param x obbject of syncdr_status class created in [compare_directories]
#' @param ...
#'
#' @return prints syncdr_status object
#' @export
print.syncdr_status <- function(x, ...) {


  # clean ---------

  ## common files -----------
  ##


  cli::cli_h1("Common files")
  x$common_files |>
    fmutate(path = gsub(x$left_path, "", path_left)) |>
    fmutate(modified = fcase(is_new_right == TRUE, "right",
                           is_new_left == TRUE, "left",
                           default = "same date"))  |>
    fselect(path, modified, modification_time_left, modification_time_right) |>
    print()

  ## non-common files -----------
  cli::cli_h1("Non-common files")

  ncf <- x$non_common_files |>
    fmutate(path_left = remove_root(x$left_path, path_left)) |>
    fmutate(path_right = remove_root(x$right_path, path_right))

  cli::cli_h2("Only left")
  ncf |>
    fselect(path_left) |>
    fsubset(!is.na(path_left)) |>
    print()

  cat("\n")

  cli::cli_h2("Only right")
  ncf |>
    fselect(path_right) |>
    fsubset(!is.na(path_right)) |>
    print()

  invisible(x)
}

remove_root <- \(root_path, new_path) {
  gsub(fs::path_dir(root_path), "", new_path)
}
