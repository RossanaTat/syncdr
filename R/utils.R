#' Validate a sync_status argument
#'
#' Checks that a `sync_status` argument is an object of class `"syncdr_status"`.
#' Throws an informative `cli::cli_abort()` if not.
#'
#' @param sync_status The value to validate.
#' @return Invisibly returns `sync_status` if the check passes.
#' @keywords internal
validate_sync_status_arg <- function(sync_status) {
  if (!inherits(sync_status, "syncdr_status")) {
    cli::cli_abort(
      c(
        "{.arg sync_status} must be an object of class {.cls syncdr_status}.",
        "x" = "Got an object of class {.cls {class(sync_status)}}.",
        "i" = "Create one with {.fn compare_directories}."
      )
    )
  }
  invisible(sync_status)
}


#' Validate a backup_dir argument against the sync directories
#'
#' Checks that `backup_dir` (when user-supplied) is not identical to, or
#' nested inside, `left_path` or `right_path`.
#'
#' @param backup_dir The backup directory path supplied by the user (or
#'   `"temp_dir"` sentinel which is skipped).
#' @param left_path  Absolute path of the left sync directory.
#' @param right_path Absolute path of the right sync directory.
#' @return Invisibly returns `backup_dir` if all checks pass.
#' @keywords internal
validate_backup_dir <- function(backup_dir, left_path, right_path) {
  # "temp_dir" is the internal sentinel meaning tempdir(); skip validation
  if (identical(backup_dir, "temp_dir")) return(invisible(backup_dir))

  # cast to plain character so fs_path / path objects compare correctly
  b <- as.character(fs::path_norm(backup_dir))
  l <- as.character(fs::path_norm(left_path))
  r <- as.character(fs::path_norm(right_path))

  for (sync_path in c(l, r)) {
    if (identical(b, sync_path) ||
        startsWith(b, paste0(sync_path, "/")) ||
        startsWith(sync_path, paste0(b, "/"))) {
      cli::cli_abort(
        c(
          "{.arg backup_dir} must not overlap with the directories being synced.",
          "x" = "{.path {backup_dir}} overlaps with {.path {sync_path}}.",
          "i" = "Use a separate, unrelated backup location."
        )
      )
    }
  }
  invisible(backup_dir)
}


#' Validate a single directory path argument
#'
#' Checks that a path argument is a non-NA, non-empty, length-1 character
#' string that refers to an existing directory. Throws an informative
#' `cli::cli_abort()` if any check fails.
#'
#' @param path The value to validate.
#' @param arg_name A string naming the argument (used in error messages).
#' @return Invisibly returns `path` if all checks pass.
#' @keywords internal
validate_path_arg <- function(path, arg_name = "path") {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    cli::cli_abort(
      c(
        "{.arg {arg_name}} must be a single non-empty character string.",
        "x" = "Got: {.val {path}}"
      )
    )
  }
  if (!fs::dir_exists(path)) {
    cli::cli_abort(
      c(
        "{.arg {arg_name}} does not exist or is not a directory.",
        "x" = "Path: {.path {path}}"
      )
    )
  }
  invisible(path)
}


#' Set theme for colorDF
#'
#' @return invisible RStudio theme
#' @keywords internal
rs_theme <- function() {
  # set display options ------
  # Check if running in RStudio
  rstudio_theme <- template <-
    list(editor     = "",
         global     = "",
         dark       = FALSE,
         foreground = "",
         background = "")

  if (Sys.getenv("RSTUDIO") == "1") {
    # Attempt to infer theme or notify the user to set the theme if using a
    # newer RStudio version without `rstudioapi` support
    # If possible, use `rstudioapi` to get theme information (works only in certain versions)

    if (requireNamespace("rstudioapi", quietly = TRUE)) {
  rstudio_theme <- tryCatch(rstudioapi::getThemeInfo(),
                            error = \(e) template,
                            silent = TRUE)
}
  }
  # return
  invisible(rstudio_theme)
}

