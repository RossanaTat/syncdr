#' Create toy directories to test syncdr functions
#'
#' create directories in temp path.... (complete documentation). Directories are
#' deleted when a new R session is started
#'
#' This function is a little slow because it must use [Sys.sleep()] to save
#' files with the same name but different time stamp.
#'
#' @param verbose logical: display information. Default is FALSE
#'
#' @return invisible list with toy directory paths for left and right
#' @export
#'
#' @examples
#' l <- toy_dirs()
#' compare_directories(l$left, l$right)
#' toy_dirs(verbose = TRUE)
toy_dirs <- function(verbose = FALSE) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # create temp dirs   ---------
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  left  <- fs::path_temp("left")
  right <- fs::path_temp("right")

  # Create empty env
  sync.env <-  new.env(parent = emptyenv())

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
  for (i in seq_along(tcomb)) {
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


  # Display directory trees
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
         envir = sync.env)

  assign(x     = "right",
         value = right,
         envir = sync.env)

  return(sync.env)

}
