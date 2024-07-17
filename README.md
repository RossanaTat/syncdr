
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
#> ■■■■■■■■■                         27% | ETA:  8s
#> ■■■■■■■■■■■■■■■■■■■               60% | ETA:  5s
```

``` r
left       <- .syncdrenv$left
right      <-  .syncdrenv$right

# --- Compare synchronization status of the two directories --- #
# comparing by date of last modification
sync_status <- compare_directories(left_path   = left,
                                   right_path  = right)

# --- Display synchronization status --- #
# visualize sync status in nice table -for example, of common files
display_sync_status(sync_status$common_files,
                    left_path  = left,
                    right_path = right)
```

<div class="datatables html-widget html-fill-item" id="htmlwidget-66ae68e0399aa5849e19" style="width:100%;height:auto;"></div>
<script type="application/json" data-for="htmlwidget-66ae68e0399aa5849e19">{"x":{"filter":"none","vertical":false,"data":[["1","2","3","4","5","6","7"],["/B/B1.Rds","/B/B2.Rds","/C/C1.Rds","/C/C2.Rds","/C/C3.Rds","/D/D1.Rds","/D/D2.Rds"],["/B/B1.Rds","/B/B2.Rds","/C/C1.Rds","/C/C2.Rds","/C/C3.Rds","/D/D1.Rds","/D/D2.Rds"],["2024-07-17T15:36:59Z","2024-07-17T15:37:02Z","2024-07-17T15:37:00Z","2024-07-17T15:37:03Z","2024-07-17T15:37:05Z","2024-07-17T15:37:02Z","2024-07-17T15:37:05Z"],["2024-07-17T15:37:00Z","2024-07-17T15:37:03Z","2024-07-17T15:37:06Z","2024-07-17T15:37:04Z","2024-07-17T15:37:06Z","2024-07-17T15:37:01Z","2024-07-17T15:37:04Z"],[false,false,false,false,false,true,true],[true,true,true,true,true,false,false],["older in left, newer in right dir","older in left, newer in right dir","older in left, newer in right dir","older in left, newer in right dir","older in left, newer in right dir","newer in left, older in right dir","newer in left, older in right dir"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>path_left<\/th>\n      <th>path_right<\/th>\n      <th>modification_time_left<\/th>\n      <th>modification_time_right<\/th>\n      <th>is_new_left<\/th>\n      <th>is_new_right<\/th>\n      <th>sync_status<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"pageLength":10,"columnDefs":[{"targets":[5,6],"createdCell":"function(td, cellData, rowData, row, col) {\n                            if (cellData === true) {\n                              $(td).css({'background-color': '#F8F4FF'});\n                            } else {\n                              $(td).css({'background-color': '#F0F8FF'});\n                            }\n                          }"},{"targets":7,"createdCell":"function(td, cellData, rowData, row, col) {\n                             if (cellData.includes('different content') ||\n                                 cellData.includes('same date') ||\n                                 cellData.includes('only in right')) {\n                              $(td).css({'background-color': '#a9def9'});\n                            } else {\n                              $(td).css({'background-color': '#e4c1f9'});\n                            }\n                          }"},{"orderable":false,"targets":0},{"name":" ","targets":0},{"name":"path_left","targets":1},{"name":"path_right","targets":2},{"name":"modification_time_left","targets":3},{"name":"modification_time_right","targets":4},{"name":"is_new_left","targets":5},{"name":"is_new_right","targets":6},{"name":"sync_status","targets":7}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":["options.columnDefs.0.createdCell","options.columnDefs.1.createdCell"],"jsHooks":[]}</script>

``` r

# --- Perform synchronization action --- #
# asymmetric snchronization from left to right 
#full_asym_sync_to_right(sync_status)
```
