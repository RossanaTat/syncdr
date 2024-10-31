.onLoad <- function(libname, pkgname) {
  op <- options()
  op.syncdr <- list(
    syncdr.verbose     = FALSE,
    syncdr.save_format = "fst"
  )
  toset <- !(names(op.syncdr) %in% names(op))

  #store them in .joynenv
  # rlang::env_bind(.syncdrenv, op.syncdr = op.syncdr)

  if(any(toset)) {
    options(op.syncdr[toset])
  }


  invisible()
}
