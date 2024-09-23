.onLoad <- function(libname, pkgname) {
  op <- options()
  op.syncdr <- list(
    syncdr.verbose     = FALSE,
    syncdr.save_format = "fst"
    #syncdr.short_paths = FALSE
  )
  toset <- !(names(op.syncdr) %in% names(op))


  if(any(toset)) {
    options(op.syncdr[toset])
  }


  invisible()
}
