% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/auxiliary_functions.R
\name{filter_common_files}
\alias{filter_common_files}
\title{Filter common files in a syncdr_status object based on specified criteria}
\usage{
filter_common_files(
  sync_status,
  by_date = TRUE,
  by_content = FALSE,
  dir = "left"
)
}
\arguments{
\item{sync_status}{An object of class 'syncdr_status' containing synchronization status and directory comparison results (common files only).}

\item{by_date}{Logical; if TRUE, filters based on new files in the specified directory. Default is TRUE.}

\item{by_content}{Logical; if TRUE, filters based on new or different files in the specified directory. Default is FALSE.}

\item{dir}{Character vector specifying the primary directory for comparison ('left', 'right', or 'all').}
}
\value{
A 'syncdr_status' object filtered according to the specified criteria.
}
\description{
This function filters common files within a "syncdr_status" object, which is the result of 'compare_directories()',
according to the specified filtering criteria:
Filtering is dependent on the 'dir' argument, determining the primary directory for comparison
}
\details{
Filtering Options:
\itemize{
\item by_date: Filters files that are new in the specified primary directory ('left', 'right', or both).
\item by_date_and_content: Filters files that are either new or different in the specified primary directory ('left', 'right', or both).
\item by_content_only: Filters files that are different between the two directories.
}
}
\examples{
\dontrun{
# Assuming sync_status is a syncdr_status object
filtered_status <- filter_sync_status(sync_status, by_date = TRUE, by_content = TRUE, dir = "left")
}

}
\seealso{
\code{\link{compare_directories}} for directory comparison and sync status creation.
}
\keyword{internal}
