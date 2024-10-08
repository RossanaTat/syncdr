
<!-- README.md is generated from README.Rmd. Please edit that file -->

# syncdr

<!-- badges: start -->
<!-- badges: end -->

{syncdr} is an R package designed to facilitate the process of directory
comparison and synchronization. This package provides essential tools
for users who need to manage and synchronize their directories
effectively.

With {syncdr}, users can:

- Visualize Directory Structures: Gain a comprehensive view of directory
  contents, including the tree structure, common files, and files unique
  to each directory.

- Manage Files with Ease: Perform content-based and modification
  date-based file comparisons, and handle tasks like identifying
  duplicates, copying, moving, and deleting files seamlessly within the
  R environment. By incorporating {syncdr} into their workflow, users
  can achieve a more organized and up-to-date file system, simplifying
  the overall management and synchronization of directories.

## Installation

You can install the development version of syncdr from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("RossanaTat/syncdr")
```

## Usage example

``` r

library(syncdr)

# Generate toy directories to show package usage

# --- Create .syncdrenv --- #
.syncdrenv <- toy_dirs()
left       <- .syncdrenv$left
right      <-  .syncdrenv$right

# --- Compare synchronization status of the two directories --- #
# comparing by date of last modification
sync_status <- compare_directories(left_path   = left,
                                   right_path  = right)

# --- Display synchronization status --- #
#  TO BE COMPLETED
```
