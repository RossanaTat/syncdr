#' Create toy directories to test syncdr functions
#'
#' create directories in syncdr environment. Directories are
#' deleted when a new R session is started
#'
#' This function is a little slow because it must use [Sys.sleep()] to save
#' files with the same name but different time stamp.
#'
#' @param verbose logical: display information. Default is FALSE
#'
#' @return syncdr environment with toy directory paths, i.e., left and right paths
#' @export
#'
#' @examples
#'
#' toy_dirs(verbose = TRUE)
toy_dirs <- function(verbose = FALSE) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # create temp dirs   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  left  <- fs::path_temp("left")
  right <- fs::path_temp("right")

  set.seed(1123)

  # Combine all combinations using expand.grid and then create temporal object
  tcomb <-
    expand.grid(LETTERS[1:5], c(1:3), stringsAsFactors = FALSE) |>
    apply(MARGIN = 1, FUN = paste, collapse = "")

  robj <- stats::runif(length(tcomb))
  lobj <- stats::runif(length(tcomb))
  names(lobj) <- tcomb
  names(robj) <- tcomb

  # Save objects as independent files according to criteria
  for (i in cli::cli_progress_along(tcomb)) {
    tc <- tcomb[i]
    l  <- substr(tc, 1, 1)
    n  <- substr(tc, 2, 2)
    lname <- fs::dir_create(left, l) |>
      fs::path(tc, ext = "Rds")
    rname <- fs::dir_create(right, l) |>
      fs::path(tc, ext = "Rds")

    # Folder convention:
    # A: Only available in left
    # B: Available in left and right but some files in left are not available in right
    # C: available in left and right, and all files are available in both
    # D: Available in left and right but some files in rigth are not available in left
    # E: Only available in right

    if (l == "A") {
      saveRDS(lobj[i], lname)
    } else if (l == "B") {
      saveRDS(lobj[i], lname)
      if (n <= 2) {
        # wait a little and save in right
        Sys.sleep(1)
        saveRDS(robj[i], rname)
      }
    } else if (l == "C") {
      saveRDS(lobj[i], lname)
      Sys.sleep(1)
      saveRDS(robj[i], rname)
    } else if (l == "D") {
      saveRDS(robj[i], rname)
      if (n <= 2) {
        # wait a little and save in right
        Sys.sleep(1)
        saveRDS(lobj[i], lname)
      }
    } else {
      saveRDS(robj[i], rname)
    }
  }

  # copy some common files from left to right to have some files with same content
  fs::file_copy(path = paste0(left, "/C/C1.Rds") ,
                new_path = paste0(right, "/C/C1.Rds"),
                overwrite = TRUE)

  # Randomly decide where to create the duplicate file
  if (runif(1) > 0.5) {
    # Create a duplicate file in the left directory
    fs::file_copy(
      path = paste0(left, "/C/C1.Rds"),
      new_path = paste0(left, "/C/C1_duplicate.Rds"),
      overwrite = TRUE
    )
  } else {
    # Create a duplicate file in the right directory
    fs::file_copy(
      path = paste0(right, "/C/C1.Rds"),
      new_path = paste0(right, "/C/C1_duplicate.Rds"),
      overwrite = TRUE
    )
  }

  # Display directory trees if verbose is TRUE
  if (verbose) {
    fs::dir_tree(left)
    fs::dir_tree(right)

  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Return   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # Assign to environment
  assign(x     = "left",
         value = left,
         envir = .syncdrenv)

  assign(x     = "right",
         value = right,
         envir = .syncdrenv)

  return(invisible(.syncdrenv))

}

#' Create a temporary copy of .syncdrenv to test functions
#'
#' This function creates a copy of the original environment, allowing tests to be executed without modifying the original environment.
#'
#' @return A list of temporary paths `left` and `right`.
#' @export
copy_temp_environment <- function() {

  # Ensure the original environment is created
  if (!exists(".syncdrenv")) {
    cli::cli_abort(message = "Original environment not found. Please run toy_dirs() first.")
  }

  original_left  <- .syncdrenv$left
  original_right <- .syncdrenv$right

  # Create new temporary directories
  temp_left  <- fs::path_temp(paste0("copy_left_",
                                 as.integer(Sys.time())))
  temp_right <- fs::path_temp(paste0("copy_right_",
                                 as.integer(Sys.time())))

  fs::dir_create(temp_left)
  fs::dir_create(temp_right)

  # Copy the contents of the original directories to the new temporary directories
  fs::dir_copy(original_left,
           temp_left,
           overwrite = TRUE)
  fs::dir_copy(original_right,
           temp_right,
           overwrite = TRUE)

  return(list(left = temp_left,
              right = temp_right))
}

toy_dirs_v2 <- function(n_subdirs = 20,
                        n_files   = 50,
                        file_size = 100,   # KB
                        verbose   = FALSE) {

  # create .syncdrenv if not present (safe-guard)
  if (!exists(".syncdrenv", envir = .GlobalEnv)) {
    assign(".syncdrenv", new.env(), envir = .GlobalEnv)
  }

  left  <- fs::path_temp("left_big")
  right <- fs::path_temp("right_big")

  set.seed(1123L)

  groups <- LETTERS[1:5]
  # combinations: "A_1_1", "A_1_2", ..., "E_n_subdirs_n_files"
  combos <- expand.grid(
    group   = groups,
    subdir  = seq_len(n_subdirs),
    file_id = seq_len(n_files),
    stringsAsFactors = FALSE
  )
  tcomb <- apply(combos, 1, function(x) paste(x, collapse = "_"))

  # random numeric content seeds (so left / right can differ)
  lobj <- stats::runif(length(tcomb))
  robj <- stats::runif(length(tcomb))

  # helper to write a binary blob of approx `size_kb` kilobytes
  write_blob <- function(path, size_kb, value) {
    # produce a single byte value 0-255
    byte_val <- as.integer(floor(value * 255))
    if (is.na(byte_val) || byte_val < 0L) byte_val <- 0L
    if (byte_val > 255L) byte_val <- 255L

    # create a raw vector and write it
    raw_data <- as.raw(rep(byte_val, size_kb * 1024L))
    con <- file(path, "wb")
    on.exit(close(con), add = TRUE)
    writeBin(raw_data, con)
  }

  # iterate with progress
  for (i in cli::cli_progress_along(tcomb, name = "Creating toy dirs")) {
    tc <- tcomb[i]
    parts <- strsplit(tc, "_", fixed = TRUE)[[1]]
    g     <- parts[1]              # group A-E
    s_num <- as.integer(parts[2])  # subdir number
    # file_id <- as.integer(parts[3]) # not used below, but available

    # create directories
    ldir <- fs::dir_create(fs::path(left,  g, paste0("sub", s_num)))
    rdir <- fs::dir_create(fs::path(right, g, paste0("sub", s_num)))

    lname <- fs::path(ldir, paste0(tc, ".bin"))
    rname <- fs::path(rdir, paste0(tc, ".bin"))

    # apply folder conventions analogous to your original toy_dirs()
    if (g == "A") {
      write_blob(lname, file_size, lobj[i])
    } else if (g == "B") {
      write_blob(lname, file_size, lobj[i])
      if (!is.na(s_num) && s_num <= (n_subdirs / 2)) {
        Sys.sleep(0.01)
        write_blob(rname, file_size, robj[i])
      }
    } else if (g == "C") {
      write_blob(lname, file_size, lobj[i])
      Sys.sleep(0.01)
      write_blob(rname, file_size, robj[i])
    } else if (g == "D") {
      write_blob(rname, file_size, robj[i])
      if (!is.na(s_num) && s_num <= (n_subdirs / 2)) {
        Sys.sleep(0.01)
        write_blob(lname, file_size, lobj[i])
      }
    } else { # E
      write_blob(rname, file_size, robj[i])
    }
  }

  # ensure at least one identical file for 'same content' test
  cfile_left  <- fs::path(left, "C", "sub1", "C_1_1.bin")
  cfile_right <- fs::path(right, "C", "sub1", "C_1_1.bin")
  if (fs::file_exists(cfile_left)) {
    fs::file_copy(cfile_left, cfile_right, overwrite = TRUE)
  }

  # add duplicate either on left or right
  if (fs::file_exists(cfile_left)) {
    if (runif(1) > 0.5) {
      fs::file_copy(cfile_left,
                    fs::path(left,  "C", "sub1", "C_1_1_duplicate.bin"),
                    overwrite = TRUE)
    } else {
      fs::file_copy(cfile_left,
                    fs::path(right, "C", "sub1", "C_1_1_duplicate.bin"),
                    overwrite = TRUE)
    }
  }

  if (verbose) {
    fs::dir_tree(left,  recurse = 2)
    fs::dir_tree(right, recurse = 2)
  }

  assign("left",  left,  envir = .syncdrenv)
  assign("right", right, envir = .syncdrenv)

  invisible(.syncdrenv)
}
