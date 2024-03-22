#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @rawNamespace import(collapse, except = droplevels)
#' @rawNamespace import(data.table, except = droplevels)
## usethis namespace: end
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
      ".joyn",
      "hash_left",
      "hash_right",
      "is_diff",
      "is_new_left",
      "is_new_right",
      "modification_time_left",
      "modification_time_right",
      "path",
      "path_left",
      "path_right",
      "runif",
      "sync_status",
      "wo_root_left",
      "wo_root_right"
    ),
    package = utils::packageName()
  )
}
NULL
