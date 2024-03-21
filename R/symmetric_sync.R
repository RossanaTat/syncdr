
# This file contains functions to perform a symmetric synchronization -in other words, two-way synchronization
# this means that you compare both directories and update each other to reflect the latest changes:
# If a file is added, modified, or deleted in one directory, the corresponding action is taken in the other directory.
# This approach is useful when you want both directories to be always up-to-date with the latest changes, regardless of where those changes originate.

#' Full symmetric synchronization
#'
