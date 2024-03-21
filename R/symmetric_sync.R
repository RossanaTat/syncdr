
# This file contains functions to perform a symmetric synchronization -in other words, two-way synchronization
# this means that you compare both directories and update each other to reflect the latest changes:
# If a file is added, modified, or deleted in one directory, the corresponding action is taken in the other directory.
# This approach is useful when you want both directories to be always up-to-date with the latest changes, regardless of where those changes originate.

#' Full symmetric synchronization
#'
#' This function updates directories in the following way:
#' * For common files:
#'   - if by date: If the file in one directory is newer than the corresponding file in the other directory,
#'                 it will be copied over to update the older version. If modification dates are the same, nothing is done
#'   - if by date and content:
#'   - if by content only
#' * For non common files:
#'   - if a file exists in one but not in the other it is copied to the other directory
#'
