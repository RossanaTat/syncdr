
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
#> Using github PAT from envvar GITHUB_PAT
#> Downloading GitHub repo RossanaTat/syncdr@HEAD
#> xfun       (0.47         -> 0.49        ) [CRAN]
#> rlang      (1.1.3        -> 1.1.4       ) [CRAN]
#> glue       (1.7.0        -> 1.8.0       ) [CRAN]
#> cli        (3.6.2        -> 3.6.3       ) [CRAN]
#> Rcpp       (1.0.13       -> 1.0.13-1    ) [CRAN]
#> fastmap    (1.1.1        -> 1.2.0       ) [CRAN]
#> digest     (0.6.34       -> 0.6.37      ) [CRAN]
#> promises   (1.2.1        -> 1.3.0       ) [CRAN]
#> fs         (1.6.3        -> 1.6.5       ) [CRAN]
#> cachem     (1.0.8        -> 1.1.0       ) [CRAN]
#> tinytex    (0.52         -> 0.54        ) [CRAN]
#> evaluate   (0.24.0       -> 1.0.1       ) [CRAN]
#> rmarkdown  (2.28         -> 2.29        ) [CRAN]
#> collapse   (15f2d3be7... -> 6f2515d4e...) [GitHub]
#> httpuv     (1.6.14       -> 1.6.15      ) [CRAN]
#> rstudioapi (0.15.0       -> 0.17.1      ) [CRAN]
#> secretbase (1.0.1        -> 1.0.3       ) [CRAN]
#> Installing 16 packages: xfun, rlang, glue, cli, Rcpp, fastmap, digest, promises, fs, cachem, tinytex, evaluate, rmarkdown, httpuv, rstudioapi, secretbase
#> Installing packages into 'C:/Users/wb621604/AppData/Local/Temp/RtmpUff3hS/temp_libpath7df0176d6287'
#> (as 'lib' is unspecified)
#> 
#>   There is a binary version available but the source version is later:
#>           binary source needs_compilation
#> rmarkdown   2.28   2.29             FALSE
#> 
#> package 'xfun' successfully unpacked and MD5 sums checked
#> package 'rlang' successfully unpacked and MD5 sums checked
#> package 'glue' successfully unpacked and MD5 sums checked
#> package 'cli' successfully unpacked and MD5 sums checked
#> package 'Rcpp' successfully unpacked and MD5 sums checked
#> package 'fastmap' successfully unpacked and MD5 sums checked
#> package 'digest' successfully unpacked and MD5 sums checked
#> package 'promises' successfully unpacked and MD5 sums checked
#> package 'fs' successfully unpacked and MD5 sums checked
#> package 'cachem' successfully unpacked and MD5 sums checked
#> package 'tinytex' successfully unpacked and MD5 sums checked
#> package 'evaluate' successfully unpacked and MD5 sums checked
#> package 'httpuv' successfully unpacked and MD5 sums checked
#> package 'rstudioapi' successfully unpacked and MD5 sums checked
#> package 'secretbase' successfully unpacked and MD5 sums checked
#> 
#> The downloaded binary packages are in
#>  C:\Users\wb621604\AppData\Local\Temp\Rtmp4mcE3K\downloaded_packages
#> installing the source package 'rmarkdown'
#> Downloading GitHub repo SebKrantz/collapse@HEAD
#> 
#> ── R CMD build ─────────────────────────────────────────────────────────────────
#>          checking for file 'C:\Users\wb621604\AppData\Local\Temp\Rtmp4mcE3K\remotes796857ac340e\SebKrantz-collapse-6f2515d/DESCRIPTION' ...  ✔  checking for file 'C:\Users\wb621604\AppData\Local\Temp\Rtmp4mcE3K\remotes796857ac340e\SebKrantz-collapse-6f2515d/DESCRIPTION' (859ms)
#>       ─  preparing 'collapse': (11.7s)
#>    checking DESCRIPTION meta-information ...     checking DESCRIPTION meta-information ...   ✔  checking DESCRIPTION meta-information
#> ─  cleaning src
#>       ─  checking for LF line-endings in source and make files and shell scripts (1.1s)
#>       ─  checking for empty or unneeded directories (335ms)
#>       ─  building 'collapse_2.0.17.tar.gz'
#>      
#> 
#> Installing package into 'C:/Users/wb621604/AppData/Local/Temp/RtmpUff3hS/temp_libpath7df0176d6287'
#> (as 'lib' is unspecified)
#> ── R CMD build ─────────────────────────────────────────────────────────────────
#>          checking for file 'C:\Users\wb621604\AppData\Local\Temp\Rtmp4mcE3K\remotes79681bb55ce6\RossanaTat-syncdr-653222f/DESCRIPTION' ...     checking for file 'C:\Users\wb621604\AppData\Local\Temp\Rtmp4mcE3K\remotes79681bb55ce6\RossanaTat-syncdr-653222f/DESCRIPTION' ...   ✔  checking for file 'C:\Users\wb621604\AppData\Local\Temp\Rtmp4mcE3K\remotes79681bb55ce6\RossanaTat-syncdr-653222f/DESCRIPTION' (769ms)
#>       ─  preparing 'syncdr': (11.2s)
#>    checking DESCRIPTION meta-information ...     checking DESCRIPTION meta-information ...   ✔  checking DESCRIPTION meta-information
#>       ─  checking for LF line-endings in source and make files and shell scripts (705ms)
#>       ─  checking for empty or unneeded directories
#>      Omitted 'LazyData' from DESCRIPTION
#>       ─  building 'syncdr_0.0.2.9001.tar.gz'
#>      
#> 
#> Installing package into 'C:/Users/wb621604/AppData/Local/Temp/RtmpUff3hS/temp_libpath7df0176d6287'
#> (as 'lib' is unspecified)
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
#> C:/Users/wb621604/AppData/Local/Temp/Rtmp4mcE3K/left
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
#> C:/Users/wb621604/AppData/Local/Temp/Rtmp4mcE3K/right
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
#> • Left Directory: 'C:/Users/wb621604/AppData/Local/Temp/Rtmp4mcE3K/left'
#> • Right Directory: 'C:/Users/wb621604/AppData/Local/Temp/Rtmp4mcE3K/right'
#> • Total Common Files: 7
#> • Total Non-common Files: 9
#> • Compare files by: date
#> 
#> ── Common files ────────────────────────────────────────────────────────────────
#>             path modification_time_left modification_time_right  modified
#> 1 /left/B/B1.Rds    2024-11-04 15:09:19     2024-11-04 15:09:20     right
#> 2 /left/B/B2.Rds    2024-11-04 15:09:22     2024-11-04 15:09:23     right
#> 3 /left/C/C1.Rds    2024-11-04 15:09:20     2024-11-04 15:09:20 same date
#> 4 /left/C/C2.Rds    2024-11-04 15:09:23     2024-11-04 15:09:24     right
#> 5 /left/C/C3.Rds    2024-11-04 15:09:25     2024-11-04 15:09:26     right
#> 6 /left/D/D1.Rds    2024-11-04 15:09:22     2024-11-04 15:09:21      left
#> 7 /left/D/D2.Rds    2024-11-04 15:09:25     2024-11-04 15:09:24      left
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
