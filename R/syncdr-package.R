#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @rawNamespace import(collapse, except = fdroplevels)
#' @rawNamespace import(data.table, except = fdroplevels)
## usethis namespace: end
.datatable.aware = TRUE
# standard data.table variables
if (getRversion() >= "2.15.1") {
  utils::globalVariables(
    names = c(
      ".",
      ".I",
      ".N",
      ".SD",
      ".",
      "!!",
      ":=",
      "x",
      "y",
      ".joyn",
      "hash_left",
      "hash_right",
      "directory_info",
      "is_diff",
      "is_new_left",
      "is_new_right",
      "modification_time",
      "modification_time_left",
      "modification_time_right",
      "path",
      "path_left",
      "path_right",
      "runif",
      "sync_status",
      "sync_status_date",
      "sync_status_content",
      "wo_root_left",
      "wo_root_right"
    ),
    package = utils::packageName()
  )
}
NULL
