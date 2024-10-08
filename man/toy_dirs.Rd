% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/toy_dirs.R
\name{toy_dirs}
\alias{toy_dirs}
\title{Create toy directories to test syncdr functions}
\usage{
toy_dirs(verbose = FALSE)
}
\arguments{
\item{verbose}{logical: display information. Default is FALSE}
}
\value{
syncdr environment with toy directory paths, i.e., left and right paths
}
\description{
create directories in syncdr environment. Directories are
deleted when a new R session is started
}
\details{
This function is a little slow because it must use \code{\link[=Sys.sleep]{Sys.sleep()}} to save
files with the same name but different time stamp.
}
\examples{

toy_dirs(verbose = TRUE)
}
