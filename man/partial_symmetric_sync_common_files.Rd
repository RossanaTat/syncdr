% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/symmetric_sync.R
\name{partial_symmetric_sync_common_files}
\alias{partial_symmetric_sync_common_files}
\title{Partial symmetric synchronization -common files only}
\usage{
partial_symmetric_sync_common_files(
  left_path = NULL,
  right_path = NULL,
  sync_status = NULL,
  by_date = TRUE,
  by_content = FALSE,
  recurse = TRUE,
  force = TRUE,
  backup = FALSE,
  backup_dir = "temp_dir",
  verbose = getOption("syncdr.verbose")
)
}
\arguments{
\item{left_path}{Path to the left/first directory.}

\item{right_path}{Path to the right/second directory.}

\item{sync_status}{Object of class "syncdr_status", output of \code{compare_directories()}.}

\item{by_date}{logical, TRUE by default}

\item{by_content}{logical, FALSE by default}

\item{recurse}{logical, TRUE by default.
If recurse is TRUE: when copying a file from source folder to destination folder, the file will be copied into the corresponding (sub)directory.
If the sub(directory) where the file is located does not exist in destination folder (or you are not sure), set recurse to FALSE,
and the file will be copied at the top level}

\item{force}{Logical. If TRUE (by default), directly perform synchronization of the directories.
If FALSE, displays a preview of actions and prompts the user for confirmation before proceeding. Synchronization is aborted if the user does not agree.}

\item{backup}{Logical. If TRUE, creates a backup of the right directory before synchronization. The backup is stored in the location specified by \code{backup_dir}.}

\item{backup_dir}{Path to the directory where the backup of the original right directory will be stored. If not specified, the backup is stored in temporary directory (\code{tempdir}).}

\item{verbose}{logical. If TRUE, display directory tree before and after synchronization. Default is FALSE}
}
\value{
Invisible TRUE indicating successful synchronization.
}
\description{
This function updates directories in the following way:
\itemize{
\item For common files:
\itemize{
\item if by date: If the file in one directory is newer than the corresponding file in the other directory,
it will be copied over to update the older version. If modification dates are the same, nothing is done
\item if by date and content: If the file in one directory is newer AND different than the corresponding file in the other directory,
it will be copied over to update the older version. If modification dates/contents are the same, nothing is done
\item if by content only: this option is not active
}
\item For non common files: unchanged, i.e.,
\itemize{
\item keep in right those that are only in right
\item keep in left those that are only in left
}
}
}
\examples{
# Create syncdr environment with toy directories
e <- toy_dirs()

# Get left and right directories' paths
left  <- e$left
right <- e$right

# Synchronize directories, e.g., by date
# Option 1 - providing left and right paths
full_symmetric_sync(left_path  = left,
                    right_path = right,
                    by_date    = TRUE)
# Option 2 - Providing sync_status object
sync_status = compare_directories(left_path  = left,
                                  right_path = right)
full_symmetric_sync(sync_status = sync_status)
}
