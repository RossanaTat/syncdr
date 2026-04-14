setwd("c:/WBG/Packages/syncdr")
res <- rcmdcheck::rcmdcheck(args = "--as-cran", error_on = "never", quiet = TRUE)
lines <- c(
  paste("ERRORS  :", length(res$errors)),
  paste("WARNINGS:", length(res$warnings)),
  paste("NOTES   :", length(res$notes))
)
if (length(res$errors))   lines <- c(lines, "=ERRORS=",   res$errors)
if (length(res$warnings)) lines <- c(lines, "=WARNINGS=", res$warnings)
if (length(res$notes))    lines <- c(lines, "=NOTES=",    res$notes)
writeLines(lines, "c:/WBG/Packages/syncdr/check_summary.txt")
