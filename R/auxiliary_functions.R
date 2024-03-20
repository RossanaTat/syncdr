
# Filter files -common files only ####
# Filter by date only; by date & content, by content only

filter_files <- function(sync_status,
                         by_date    = TRUE,
                         by_content = FALSE) {


  # Filter by date only
  if ((isTRUE(by_date) & isFALSE(by_content))) {

    sync_status <- sync_status |>
      fsubset(is_new == TRUE)

  }

  # Filter by date & content
  else if (isTRUE(by_date) & isTRUE(by_content)) {

    sync_status <- sync_status |>
      fsubset(is_new == TRUE & is_diff == TRUE)

  }

  # Filter by content only
  else if (isFALSE(by_date) & isTRUE(by_content)) {

    sync_status <- sync_status |>
      fsubset(is_diff == TRUE)

  } else

    {sync_status <- sync_status} # if both by_date and content are FALSE

  return(sync_status)

  }

