% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/display_functions.R
\name{display_sync_status}
\alias{display_sync_status}
\title{Display status of synchronization/comparison info between two directories in DT table}
\usage{
display_sync_status(sync_status_files, left_path, right_path)
}
\arguments{
\item{sync_status_files}{object of \code{compare_directories()} output, either common_files or non_common_files}

\item{left_path}{A character string specifying the path to left directory.}

\item{right_path}{A character string specifying the path to right directory.}
}
\value{
DT table showing the comparison between the two directories
together with their synchronization status
}
\description{
Display status of synchronization/comparison info between two directories in DT table
}
