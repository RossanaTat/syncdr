
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
#> ■■■■■■■ 20% | ETA: 8s■■■■■■■■■■■■■■■ 47% | ETA: 5s■■■■■■■■■■■■■■■■■ 53% | ETA:
#> 5s■■■■■■■■■■■■■■■■■■■ 60% | ETA: 4s■■■■■■■■■■■■■■■■■■■■■■■■■■■ 87% | ETA: 1s
left       <- .syncdrenv$left
right      <-  .syncdrenv$right

# --- Compare synchronization status of the two directories --- #
display_dir_tree(path_left  = left,
                 path_right = right)
#> (←)Left directory structure:
#> C:/Users/wb621604/AppData/Local/Temp/Rtmpeg8Y3y/left
#> ├── A
#> │   ├── A1.Rds
#> │   ├── A2.Rds
#> │   └── A3.Rds
#> ├── B
#> │   ├── B1.Rds
#> │   ├── B2.Rds
#> │   └── B3.Rds
#> ├── C
#> │   ├── C1.Rds
#> │   ├── C2.Rds
#> │   └── C3.Rds
#> ├── D
#> │   ├── D1.Rds
#> │   └── D2.Rds
#> └── E
#> (→)Right directory structure:
#> C:/Users/wb621604/AppData/Local/Temp/Rtmpeg8Y3y/right
#> ├── A
#> ├── B
#> │   ├── B1.Rds
#> │   └── B2.Rds
#> ├── C
#> │   ├── C1.Rds
#> │   ├── C1_duplicate.Rds
#> │   ├── C2.Rds
#> │   └── C3.Rds
#> ├── D
#> │   ├── D1.Rds
#> │   ├── D2.Rds
#> │   └── D3.Rds
#> └── E
#>     ├── E1.Rds
#>     ├── E2.Rds
#>     └── E3.Rds

# comparing by date of last modification
compare_directories(left_path   = left,
                    right_path  = right)
#> 
#> ── Synchronization Summary ─────────────────────────────────────────────────────
#> • Left Directory: 'C:/Users/wb621604/AppData/Local/Temp/Rtmpeg8Y3y/left'
#> • Right Directory: 'C:/Users/wb621604/AppData/Local/Temp/Rtmpeg8Y3y/right'
#> • Total Common Files: 7
#> • Total Non-common Files: 9
#> • Compare files by: date
#> 
#> ── Common files ────────────────────────────────────────────────────────────────
#>             path modification_time_left modification_time_right  modified
#> 1 /left/B/B1.Rds    2024-11-04 15:13:49     2024-11-04 15:13:50     right
#> 2 /left/B/B2.Rds    2024-11-04 15:13:52     2024-11-04 15:13:53     right
#> 3 /left/C/C1.Rds    2024-11-04 15:13:50     2024-11-04 15:13:50 same date
#> 4 /left/C/C2.Rds    2024-11-04 15:13:53     2024-11-04 15:13:54     right
#> 5 /left/C/C3.Rds    2024-11-04 15:13:55     2024-11-04 15:13:56     right
#> 6 /left/D/D1.Rds    2024-11-04 15:13:52     2024-11-04 15:13:51      left
#> 7 /left/D/D2.Rds    2024-11-04 15:13:55     2024-11-04 15:13:54      left
#> 
#> ── Non-common files ────────────────────────────────────────────────────────────
#> 
#> ── Only in left ──
#> # A tibble: 4 × 1
#>   path_left     
#>   <fs::path>    
#> 1 /left/A/A1.Rds
#> 2 /left/A/A2.Rds
#> 3 /left/A/A3.Rds
#> 4 /left/B/B3.Rds
#> ── Only in right ──
#> # A tibble: 5 × 1
#>   path_right               
#>   <fs::path>               
#> 1 /right/C/C1_duplicate.Rds
#> 2 /right/D/D3.Rds          
#> 3 /right/E/E1.Rds          
#> 4 /right/E/E2.Rds          
#> 5 /right/E/E3.Rds

# --- Perform synchronization action --- #

# asymmetric snchronization from left to right 
 full_asym_sync_to_right(left_path  = left,
                         right_path = right,
                         force      = FALSE)
#> These files will be DELETED in right
#> 
#> |Files               |Action        |
#> |:-------------------|:-------------|
#> |/C/C1_duplicate.Rds |To be deleted |
#> |/D/D3.Rds           |To be deleted |
#> |/E/E1.Rds           |To be deleted |
#> |/E/E2.Rds           |To be deleted |
#> |/E/E3.Rds           |To be deleted |
#> These files will be COPIED (overwriting if present) to right 
#> 
#> 
#> |Files     |Action       |
#> |:---------|:------------|
#> |/D/D1.Rds |To be copied |
#> |/D/D2.Rds |To be copied |
#> |/A/A1.Rds |To be copied |
#> |/A/A2.Rds |To be copied |
#> |/A/A3.Rds |To be copied |
#> |/B/B3.Rds |To be copied |
#> Do you want to proceed? Type your answer (Yes/no/cancel) 
#> ✔ synchronized
```
