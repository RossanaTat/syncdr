---
date: 2026-04-06
title: "Security Audit Findings — Steps 5, 6 & 7: Permission/Error Handling, Backup Mechanisms, and Path Handling"
category: bugs
status: audit-findings
plan: ".cg-docs/plans/2026-04-05-security-audit-plan.md"
---

# Security Audit Findings — Steps 5, 6 & 7

---

## Step 5: Permission and Error Handling Analysis

### Methodology

For every file-system call in the package, assessed: (1) whether it is wrapped in
`tryCatch`, `try`, or `withCallingHandlers`; (2) what the call returns on failure
vs. what the code does with the return value; (3) what the user experiences when
it fails; (4) what state the directory is left in.

---

### 5.1 Error Handling Coverage Matrix

The following table covers every file-system call in the package. The single `tryCatch`
in the codebase (`utils.R:rs_theme()`) is for UI theming only — it has no file-system
relevance.

#### `R/action_functions.R`

| Call | Location | Wrapped in tryCatch? | On Failure | User Experience | Directory State |
|---|---|---|---|---|---|
| `fs::dir_create(unique_dirs)` | `copy_files_to_right()` L41 | ❌ No | R error propagates; stops before any file is copied | Unhandled error message from `fs` | No files copied; destination dirs may be partially created if `unique_dirs` is a vector |
| `fs::dir_create(unique_dirs)` | `copy_files_to_left()` L104 | ❌ No | Same as above | Same | Same |
| `fs::file_copy(path, new_path, overwrite=TRUE)` | `copy_files_to_right()` L51 | ❌ No | Error on first failing file; loop aborts via `lapply()` propagation | Unhandled `fs` error (e.g., "permission denied", "file not found") | Files 1..i-1 copied; file i and beyond not copied; no log of what succeeded |
| `fs::file_copy(path, new_path, overwrite=TRUE)` | `copy_files_to_left()` L116 | ❌ No | Same as above | Same | Same |

**Note**: `fs::file_copy()` throws an error (not a warning) on failure — unlike `base::file.copy()` which returns `FALSE`. This means failures do propagate visibly, but there is no recovery path.

#### `R/asymmetric_sync.R` — backup block (present in 4 functions)

| Call | Wrapped in tryCatch? | Return Value Used? | On Failure | User Experience |
|---|---|---|---|---|
| `dir.create(backup_dir, recursive=TRUE)` | ❌ No | `FALSE` return ignored | R warning "cannot create dir" if parent missing; no error | Warning printed; sync continues; backup silently absent |
| `file.copy(from=right_path, to=backup_dir, recursive=TRUE)` | ❌ No | Logical vector return **ignored** | Returns `FALSE` for failed files; no error raised | No visible failure; sync proceeds even if backup incomplete |

This is the most dangerous gap in the package: `file.copy()` never throws an error — it silently returns `FALSE` for files it cannot copy. Because the return value is discarded with no check, a completely failed backup is indistinguishable from a successful one. Sync then proceeds to destructive operations.

#### `R/asymmetric_sync.R` — delete loops

| Call | Location | Wrapped in tryCatch? | On Failure | User Experience | Directory State |
|---|---|---|---|---|---|
| `fs::file_delete(files_to_delete$path_right[i])` | `full_asym_sync_to_right()` L219 | ❌ No | Error propagates out of `lapply()`; loop aborts | `fs` error message (e.g., file not found, permission denied) | Files 1..i-1 deleted; file i and beyond NOT deleted; no log of what was deleted |
| `fs::file_delete(files_to_delete$path_right[i])` | `update_missing_files_asym_to_right()` L676 | ❌ No | Same | Same | Same |

`fs::file_delete()` raises an error on non-existent files. In the stale-`sync_status` scenario (SC-02 from Step 4), if a right-only file was externally deleted between compare and sync, the delete loop will error mid-run.

#### `R/symmetric_sync.R` — backup block

| Call | Wrapped in tryCatch? | Return Value Used? | On Failure | User Experience |
|---|---|---|---|---|
| `dir.create(backup_right/left, recursive=TRUE)` | ❌ No | `FALSE` return ignored | Warning if parent missing | Warning; sync continues regardless |
| `file.copy(from=right_path/left_path, to=backup_dir, recursive=TRUE)` | ❌ No | Logical vector **ignored** | Silent `FALSE` per failed file | No visible failure; sync proceeds with incomplete backup |

`full_symmetric_sync()` adds a second `file.copy()` call for the left directory. Both return values are discarded. Total: 2 unverified backup operations before 2 copy operations execute.

`partial_symmetric_sync_common_files()` uses `list.files()` + `file.copy()` instead. The `file.copy()` return value is also discarded — same gap.

#### `R/auxiliary_functions.R`

| Call | Location | Wrapped in tryCatch? | On Failure | User Experience |
|---|---|---|---|---|
| `fs::dir_ls(path=dir, type="file", recurse=recurse)` | `directory_info()` | ❌ No | `fs` error if dir doesn't exist or permission denied | Raw `fs` error propagates to caller (e.g., `compare_directories()`) |
| `fs::file_info(files)` | `directory_info()` | ❌ No | `fs` error on permission denied or file gone | Raw `fs` error |
| `secretbase::siphash13(file=path)` | `hash_files()` | ❌ No | Error if file unreadable (permission/lock) | Raw error; `lapply()` aborts on first failure |
| `digest::digest(p, algo="xxhash32", file=TRUE)` | `hash_files_in_dir()` | ❌ No | Error if file unreadable | Raw error; `lapply()` aborts |
| `dir.create(syncdr_path)` | `save_sync_status()` | ❌ No | R warning if dir exists (harmless); error if parent missing | Warning or error; save aborted |
| `fst::write_fst()` / `fwrite()` / `saveRDS()` | `save_sync_status()` | ❌ No | Error if path invalid or disk full | Raw error |

`save_sync_status()` does not validate that `dir_path` exists before calling `hash_files_in_dir(dir_path)` and `directory_info(dir_path)`. If `dir_path` does not exist, `fs::dir_ls()` will error with a raw message that does not mention `dir_path` validation.

#### `R/display_functions.R`

| Call | Location | Wrapped in tryCatch? | On Failure | Notes |
|---|---|---|---|---|
| `fs::dir_tree(path_left/path_right)` | `display_dir_tree()` | ❌ No | `fs` error if path doesn't exist | Called before validation in STRUCT-01; could error before user sees validation message |

---

### 5.2 Error Handling Finding Matrix

| Finding ID | Description | Severity | Affected Functions |
|---|---|---|---|
| EH-01 | `file.copy()` return value never checked — silent backup failure | **Critical** | All 6 sync functions (backup block) |
| EH-02 | `dir.create()` return value never checked in backup block — silent dir creation failure | **High** | All 6 sync functions |
| EH-03 | No `tryCatch` around `fs::file_copy()` in copy loops — partial copy on any failure | **High** | `copy_files_to_right()`, `copy_files_to_left()` |
| EH-04 | No `tryCatch` around `fs::file_delete()` in delete loops — partial delete on any failure | **High** | `full_asym_sync_to_right()`, `update_missing_files_asym_to_right()` |
| EH-05 | No `tryCatch` around `fs::dir_create()` in copy workers — if dir creation fails, copy never runs but no cleanup of earlier created dirs | Medium | `copy_files_to_right()`, `copy_files_to_left()` |
| EH-06 | No pre-flight permission check on source (read) or destination (write) before starting multi-file operations | **High** | All sync functions, `copy_files_to_right/left()` |
| EH-07 | `save_sync_status()` does not validate `dir_path` existence before calling `hash_files_in_dir()` and `directory_info()` | Medium | `save_sync_status()` |
| EH-08 | `hash_files_in_dir()` / `hash_files()`: `lapply()` over file reads with no `tryCatch` — one unreadable file aborts the entire operation | Medium | `hash_files_in_dir()`, `hash_files()`, `search_duplicates()`, `save_sync_status()` |
| EH-09 | `compare_directories()` calls `directory_info()` for both dirs before any `tryCatch` — a permission error on right dir surfaces after left dir is already fully read (wasted work, confusing error) | Low | `compare_directories()` |
| EH-10 | `display_dir_tree()` called before input validation in 3 of 4 asym sync functions (STRUCT-01) — `fs::dir_tree()` can error on non-existent path before the validation abort runs | Medium | `full_asym_sync_to_right()`, `update_missing_files_asym_to_right()`, `partial_update_missing_files_asym_to_right()` |
| EH-11 | Zero `tryCatch` wrappers anywhere in the package around file-system operations (one exists in `utils.R` for UI theming only) | **High** | Package-wide |
| EH-12 | No post-operation verification — no re-compare or checksum after sync to confirm all files were transferred correctly | Medium | All sync functions |

---

### 5.3 Pre-Flight Permission Check Gap

No sync function or copy worker performs any pre-flight test before beginning multi-file operations. A permission-denied error on file N leaves files 1..N-1 in an intermediate state with no log and no rollback.

Concrete scenarios:
- Destination directory is read-only (e.g., network share with insufficient privileges): `fs::file_copy()` succeeds for locally-cached files but fails at the network boundary.
- Source file is locked by another process (Windows file locking): `fs::file_copy()` errors mid-loop.
- Destination disk is full: first files copy successfully, then `fs::file_copy()` throws "no space left on device" for all subsequent files.

In all three cases: partial copy, no log, no rollback, no informative error referencing which file failed or what was already done.

---

## Step 6: Backup Mechanism Analysis

### Methodology

Compared the backup implementation across all 6 sync functions. For each: documented
backup timing (before/after force prompt), backup strategy (recursive `file.copy` vs.
flat `file.copy`), success verification, directory naming, and consistency gaps.

---

### 6.1 Backup Implementation Comparison

| Sync Function | Backup Timing | Relative to Force Prompt | Backup Strategy | Dir Naming | Verify Success? |
|---|---|---|---|---|---|
| `full_asym_sync_to_right()` | After `files_to_delete` computed | **AFTER** force prompt | `file.copy(from=right_path, recursive=TRUE)` | `backup_dir` (whole dir copied in) | ❌ No |
| `common_files_asym_sync_to_right()` | After `files_to_copy` computed | **BEFORE** force prompt | `file.copy(from=right_path, recursive=TRUE)` | `backup_dir` | ❌ No |
| `update_missing_files_asym_to_right()` | After `files_to_delete` computed | **BEFORE** force prompt | `file.copy(from=right_path, recursive=TRUE)` | `backup_dir` | ❌ No |
| `partial_update_missing_files_asym_to_right()` | After `files_to_copy` computed | **AFTER** force prompt ⚠️ | `file.copy(from=right_path, recursive=TRUE)` | `backup_dir` | ❌ No |
| `full_symmetric_sync()` | After force prompt check | **AFTER** force prompt ⚠️ | `file.copy(from=right_path, recursive=TRUE)` + `file.copy(from=left_path, ...)` | `backup_right` / `backup_left` | ❌ No |
| `partial_symmetric_sync_common_files()` | After `by_content_only` abort check | After force prompt ⚠️ | `list.files()` + `file.copy(copy.date=TRUE)` flat copy | `backup_right` / `backup_left` | ❌ No |

---

### 6.2 Backup Timing Inconsistency

**Expected sequence:** force prompt → user confirms → backup → sync.

This ensures backup only happens if the user agrees to proceed, and that backup is complete before any destructive operation begins.

**Actual sequences across functions:**

```
full_asym_sync_to_right():                      common_files_asym_sync_to_right():
  [compute files_to_delete]                        [compute files_to_copy]
  [backup] ← BEFORE force prompt                   [backup] ← BEFORE force prompt
  [force prompt if force==FALSE]                   [force prompt if force==FALSE]
  [copy]                                           [copy]
  [delete]

update_missing_files_asym_to_right():           partial_update_missing_files_asym_to_right():
  [compute files]                                  [compute files]
  [backup] ← BEFORE force prompt                   [force prompt if force==FALSE] ← FIRST
  [force prompt if force==FALSE]                   [backup] ← AFTER prompt ⚠️
  [copy]                                           [copy]
  [delete]

full_symmetric_sync():                          partial_symmetric_sync_common_files():
  [compute files]                                  [compute files]
  [force prompt if force==FALSE] ← FIRST           [by_content_only abort check]
  [backup] ← AFTER prompt ⚠️                       [force prompt if force==FALSE] ← FIRST
  [content_only abort check]                        [backup] ← AFTER prompt ⚠️
  [copy to right]                                  [copy to right]
  [copy to left]                                   [copy to left]
```

**Key finding (BK-01)**: Three of six functions run backup AFTER the force prompt. This means:
- If `force = FALSE`, user sees the preview, confirms — then backup runs. This is the correct order.
- If `force = TRUE` (default), the force block is skipped entirely, and backup runs just before sync. This is also safe.
- **However**: in `full_symmetric_sync()`, the backup runs BEFORE the `by_content_only` abort check (L186 backup vs. L229 abort). If `by_date = FALSE, by_content = TRUE`, the backup is created and then the function immediately aborts with an error. The user now has an unwanted backup directory and their directories are unchanged. (**BK-01b**)

---

### 6.3 Backup Strategy Inconsistency

#### `file.copy(from = right_path, to = backup_dir, recursive = TRUE)`

Used by 5 of 6 functions. This copies the **directory itself** (not its contents) into `backup_dir`. Result:

```
backup_dir/
  └─ <basename(right_path)>/     ← entire right dir becomes a subdirectory
       ├─ file_a.csv
       └─ subdir/
            └─ file_b.csv
```

When `backup_dir == "temp_dir"` (default), resolves to `file.path(tempdir(), "backup_directory")`. On repeated calls, subsequent backups overwrite the previous backup because `backup_dir` is always the same name. **There is no timestamping on backup directories.**

**Finding BK-02**: Multiple sync operations with the default `backup_dir` accumulate to a single backup directory, each call overwriting the previous. Only the most recent backup is retained.

#### `list.files() + file.copy(copy.date = TRUE)` (flat copy)

Used only by `partial_symmetric_sync_common_files()`. This copies **file contents** (not directory structure) into flat `backup_right` / `backup_left` directories:

```
backup_right/
  ├─ file_a.csv
  └─ file_b.csv     ← subdir/file_b.csv becomes backup_right/file_b.csv (flat!)
```

`list.files(full.names = TRUE, recursive = TRUE)` collects all files including subdirectory contents. `file.copy(to = backup_right)` writes them flat. **Subdirectory structure is lost.** If two files in different subdirs have the same name, the second overwrites the first in the backup.

**Finding BK-03 (High)**: `partial_symmetric_sync_common_files()` backup is structurally different from all other functions — it produces a flat backup that loses subdirectory hierarchy and silently drops files with duplicate names across subdirs.

---

### 6.4 `full_symmetric_sync()` Dual-Backup Path Bug

```r
backup_right <- fifelse(backup_dir == "temp_dir",
                        file.path(tempdir(), "backup_right"),
                        backup_dir)   # ← same user-provided path!

backup_left  <- fifelse(backup_dir == "temp_dir",
                        file.path(tempdir(), "backup_left"),
                        backup_dir)   # ← same user-provided path!
```

When `backup_dir == "temp_dir"` (default): `backup_right = tempdir()/backup_right`, `backup_left = tempdir()/backup_left` — **correct**.

When `backup_dir` is a user-provided custom path (e.g., `"C:/backups/today"`):
- `backup_right = "C:/backups/today"`
- `backup_left  = "C:/backups/today"`  ← **identical**

Both `file.copy()` calls write into the same directory:
1. `file.copy(right_path → "C:/backups/today")` → creates `C:/backups/today/<basename(right_path)>/...`
2. `file.copy(left_path → "C:/backups/today")` → creates `C:/backups/today/<basename(left_path)>/...`

If `left_path` and `right_path` have the same basename (e.g., both are named `data`), the second `file.copy()` overwrites the first backup.

**Finding BK-04 (High)**: When a custom `backup_dir` is provided to `full_symmetric_sync()`, both `backup_right` and `backup_left` resolve to the same path. If left and right directories share the same basename, the right backup is silently overwritten by the left backup.

---

### 6.5 Backup Completeness

**Default `backup_dir = "temp_dir"` → `tempdir()`**:
- `tempdir()` is a per-session temporary directory. It is deleted when the R session ends.
- The user may be unaware that their backup is ephemeral. There is no warning in the documentation or console output that the default backup location is temporary.

**Finding BK-05 (Medium)**: Default backup to `tempdir()` is ephemeral — it is lost when the R session ends. There is no user-facing warning about this.

**No success verification**: As documented in EH-01, `file.copy()` returns a logical vector that is never checked. A completely failed backup (e.g., backup dir on full disk) is not detected.

**Finding BK-06 (Critical)**: Backup success is never verified. A failed backup (silent `file.copy() → FALSE`) is indistinguishable from a successful backup. Subsequent destructive operations proceed regardless.

---

### 6.6 Backup Finding Matrix

| Finding ID | Description | Severity | Affected Functions |
|---|---|---|---|
| BK-01 | Backup timing inconsistent across functions — 3 of 6 run backup AFTER force prompt | Medium | `partial_update_missing_files_asym_to_right()`, `full_symmetric_sync()`, `partial_symmetric_sync_common_files()` |
| BK-01b | `full_symmetric_sync()`: backup runs BEFORE `by_content_only` abort check — backup created then immediately discarded on abort | Medium | `full_symmetric_sync()` |
| BK-02 | No timestamp on backup dir name — repeated calls overwrite the same backup location | **High** | All 6 sync functions |
| BK-03 | `partial_symmetric_sync_common_files()` uses flat `file.copy()` — subdirectory structure lost; duplicate-name files silently overwritten in backup | **High** | `partial_symmetric_sync_common_files()` |
| BK-04 | `full_symmetric_sync()` with custom `backup_dir`: both `backup_right` and `backup_left` resolve to same path — right backup overwritten by left backup if basenames match | **High** | `full_symmetric_sync()` |
| BK-05 | Default `backup_dir = tempdir()` is ephemeral — no user warning | Medium | All 6 sync functions |
| BK-06 | `file.copy()` return value never checked — silent backup failure | **Critical** | All 6 sync functions |
| BK-07 | `file.copy(from=right_path, recursive=TRUE)` copies the directory as a child of `backup_dir`, not its contents — resulting backup structure depends on OS and whether `backup_dir` already exists | Low | All 5 asym+full-sym functions |

---

## Step 7: Path Handling Analysis

### Methodology

Catalogued every `gsub()` call used for path manipulation. For each: (1) identified
the pattern argument (is it a user-supplied path?), (2) assessed whether regex
metacharacters in real-world paths would break it, (3) compared to the correct
alternative. Also checked for path normalization, trailing slash handling, and
mixed separator usage.

---

### 7.1 Complete `gsub()` Path Manipulation Catalog

| GSUB ID | Location | Code | Pattern Source | `fixed=TRUE`? | Risk |
|---|---|---|---|---|---|
| GSUB-01 | `auxiliary_functions.R:directory_info()` | `gsub(dir, "", path)` | User-supplied `dir` path | ❌ No | **High** |
| GSUB-02 | `auxiliary_functions.R:search_duplicates()` | `gsub(dir_path, "", file_path)` | User-supplied `dir_path` | ❌ No | Medium (display only) |
| GSUB-03 | `action_functions.R:copy_files_to_right()` | `gsub(left_dir, "", path_left)` | User-supplied `left_dir` | ❌ No | **Critical** |
| GSUB-04 | `action_functions.R:copy_files_to_left()` | `gsub(right_dir, "", path_right)` | User-supplied `right_dir` | ❌ No | **Critical** |
| GSUB-05 | `display_functions.R:display_sync_status()` | `gsub(left_path, "", path_left)` | User-supplied `left_path` | ❌ No | Medium (display only) |
| GSUB-06 | `display_functions.R:display_sync_status()` | `gsub(right_path, "", path_right)` | User-supplied `right_path` | ❌ No | Medium (display only) |
| GSUB-07 | `display_functions.R:display_file_actions()` | `gsub(directory, "", Paths)` | User-supplied `directory` | ❌ No | Medium (display only) |
| GSUB-08 | `print.R:remove_root()` | `gsub(fs::path_dir(root_path), "", new_path)` | `fs::path_dir()` of user path | ❌ No | Low (print only) |

**Zero** `gsub()` calls use `fixed = TRUE`. All treat the first argument as a regex pattern.

---

### 7.2 GSUB-01: `directory_info()` — `wo_root` as Join Key

```r
info_df <- fs::file_info(files) |>
  ftransform(wo_root = gsub(dir, "", path), ...)
```

`wo_root` is the **join key** used by `joyn::joyn()` in `compare_directories()` to match files between left and right directories. If `dir` contains regex metacharacters:

- `dir = "C:/data/project+2024"` → `gsub("C:/data/project+2024", "", ...)` matches `project2024`, `project+2024`, `projectX2024`, etc. (`+` means "one or more" in regex; `/` matches `/`; `.` matches any char; `:` matches any `:`)
- Result: `wo_root` is computed incorrectly for some files.
- Downstream: `joyn()` uses a wrong `wo_root` as the join key → files that should be "common" are classified as "only in left" or "only in right" → wrong sync decisions → files deleted or not copied.

**Severity: Critical** — affects the correctness of every comparison and sync operation for users with non-trivial directory names.

**Correct replacement**: `gsub(dir, "", path, fixed = TRUE)` or `fs::path_rel(path, start = dir)`.

---

### 7.3 GSUB-03/04: `copy_files_to_right/left()` — Destination Path Computation

```r
files_to_copy <- files_to_copy |>
  ftransform(wo_root_left = gsub(left_dir, "", path_left)) |>
  ftransform(path_to      = fs::path(right_dir, wo_root_left))
```

`wo_root_left` determines where each file is written in the destination directory. If `left_dir` is a regex pattern:

**Example**: `left_dir = "C:/Users/user.name/data (copy)"`
- `gsub("C:/Users/user.name/data (copy)", "", "C:/Users/user.name/data (copy)/subdir/file.csv")`
- Regex interpretation: `.` = any char, `(` and `)` = capture group, `/` = literal
- The pattern may match correctly here, or may match portions it should not match (`.` matches any char, so `user_name` would also match `user.name`)
- Result: `wo_root_left` is incorrect for some files → `path_to` points to wrong destination → file copied to wrong location → **unintended overwrite of a file at the wrong path**

**Severity: Critical** — wrong destination path causes files to be copied to unintended locations, potentially overwriting existing files in the destination directory.

---

### 7.4 Concrete Metacharacter Risk Matrix

Real-world directory names that trigger this bug:

| Character | Common in Path | Regex Meaning | Example Path | Effect on gsub() |
|---|---|---|---|---|
| `.` | Very common (`.gitignore`, `user.name`, `v1.0`) | Any character | `C:/user.name/data` | Pattern matches `user_name` as well as `user.name` |
| `+` | Common (`project+data`, `C++`) | One or more of preceding | `C:/project+data` | `+` is quantifier; pattern is malformed or unexpected |
| `(` / `)` | Common (`data (copy)`, `dir(1)`) | Capture group | `C:/data (copy)` | Capture group affects match; unbalanced parens cause warning |
| `[` / `]` | Less common (`data[2024]`) | Character class | `C:/data[2024]` | `[2024]` matches any of `2`, `0`, `4` |
| `{` / `}` | Rare | Repetition quantifier | `C:/data{v2}` | `{v2}` — quantifier parsing error |
| `^` | Rare (`C:^temp`) | Start of string | `C:^temp` | Anchors match |
| `$` | Rare | End of string | `data$final` | Empty match at end of string |
| `\` | Windows paths use `\` | Escape character | `C:\Users\data` | Escape interpretation; `\U` is not valid regex |
| `*` | Rare | Zero or more | `data*v2` | Quantifier error |

**Windows path separator `\` note**: `fs` normalises paths to `/` on Windows. However, user-supplied paths may contain `\`. If a user passes `"C:\\Users\\data"`, `gsub()` receives `\U`, `\d` etc. — which are regex escapes. `\U` means "convert to uppercase" in PCRE; this causes silent incorrect substitution.

---

### 7.5 Path Normalization Gaps

#### Trailing slashes

`directory_info()` and `compare_directories()` do not normalize trailing slashes on input paths.

```r
dir    = "C:/data/"       # trailing slash
path   = "C:/data/file.csv"
gsub("C:/data/", "", "C:/data/file.csv")   # → "file.csv"   ✓
gsub("C:/data",  "", "C:/data/file.csv")   # → "/file.csv"  ✗ (leading slash)
```

A user who passes `left_path = "C:/data/"` and another who passes `left_path = "C:/data"` get different `wo_root` values. If a `sync_status` is created with one form and a path is compared with the other form, the join key will not match.

**Finding PH-01 (Medium)**: No trailing-slash normalization — `wo_root` is path-form-dependent. Users who pass paths with or without trailing slashes get different `wo_root` keys, causing join mismatches.

#### Relative vs. absolute paths

`compare_directories()` calls `stopifnot(fs::dir_exists(left_path))`. `fs::dir_exists()` resolves relative paths. However, `left_path` is stored as-is in `sync_status$left_path` — not normalized to absolute.

If the user passes `left_path = "../../data"` (relative), `sync_status$left_path` stores `"../../data"`. If this `sync_status` is later passed to a sync function in a different working directory, the path resolves differently — causing wrong file operations.

**Finding PH-02 (Medium)**: Paths stored in `sync_status` are not normalized to absolute paths — relative paths are stored as-is. Reuse of `sync_status` in a different working directory will silently operate on wrong files.

#### Mixed path separators (Windows-specific)

`fs` normalises to `/` on all platforms. However, `gsub()` path manipulation is applied **before** or alongside `fs` functions. If a user-supplied path uses `\` (e.g., `"C:\\Users\\data"`):

- `fs::dir_exists("C:\\Users\\data")` → `TRUE` (fs handles it)
- `gsub("C:\\Users\\data", "", "C:/Users/data/file.csv")` → pattern `C:\\Users\\data` is a regex for `C:\Users\data` where `\U` is regex "uppercase next char" — the substitution produces wrong output

**Finding PH-03 (High)**: Mixed path separators (Windows `\` vs. fs-normalised `/`) interact poorly with `gsub()` regex interpretation, potentially causing wrong path computation on Windows when users pass backslash paths.

---

### 7.6 `fs::path_rel()` as the Correct Replacement

The standard tool for computing a path relative to a root directory is `fs::path_rel(path, start)`, which:
- Uses character-level path decomposition (not regex)
- Handles trailing slashes correctly
- Handles mixed separators
- Works correctly on paths with any characters

```r
# Current (broken for metacharacter paths):
wo_root_left <- gsub(left_dir, "", path_left)

# Correct replacement:
wo_root_left <- fs::path_rel(path_left, start = left_dir)
```

`fs::path_rel()` is already a dependency (via the `fs` package which is listed in DESCRIPTION). No new dependency is needed.

---

### 7.7 Path Handling Finding Matrix

| Finding ID | Description | Severity | Affected Functions |
|---|---|---|---|
| GSUB-01 | `directory_info()` `gsub(dir, "")` without `fixed=TRUE` — corrupts `wo_root` join key | **Critical** | `directory_info()` → `compare_directories()` → all sync functions |
| GSUB-02 | `search_duplicates()` `gsub(dir_path, "")` display only — wrong display for metacharacter paths | Low | `search_duplicates()` |
| GSUB-03 | `copy_files_to_right()` `gsub(left_dir, "")` — wrong destination path → overwrites wrong files | **Critical** | `copy_files_to_right()` → all sync functions that copy to right |
| GSUB-04 | `copy_files_to_left()` `gsub(right_dir, "")` — same as GSUB-03, for left direction | **Critical** | `copy_files_to_left()` → symmetric sync functions |
| GSUB-05/06 | `display_sync_status()` `gsub(left/right_path, "")` — wrong display only | Low | `display_sync_status()` |
| GSUB-07 | `display_file_actions()` `gsub(directory, "")` — wrong display only | Low | `display_file_actions()` |
| GSUB-08 | `remove_root()` in `print.R` `gsub(fs::path_dir(root_path), "")` — wrong display only | Low | `print.syncdr_status()` |
| PH-01 | No trailing-slash normalization — `wo_root` join key is path-form-dependent | Medium | `directory_info()`, `compare_directories()` |
| PH-02 | Relative paths stored as-is in `sync_status` — wrong resolution if working directory changes | Medium | All sync functions that accept `sync_status` |
| PH-03 | Windows backslash paths break `gsub()` regex interpretation | **High** | All 8 `gsub()` path calls |

---

## Cross-Reference: Steps 5, 6 & 7 Combined Priority Summary

The following table consolidates all findings across Steps 5–7 and ranks by severity for remediation planning.

### Critical findings

| Finding ID | Description | Step |
|---|---|---|
| EH-01 / BK-06 | `file.copy()` backup return value never checked — silent backup failure before destructive ops | 5/6 |
| GSUB-01 | `directory_info()` regex `gsub` corrupts `wo_root` join key — wrong comparisons for all metacharacter paths | 7 |
| GSUB-03 | `copy_files_to_right()` regex `gsub` computes wrong destination path — files copied to wrong locations | 7 |
| GSUB-04 | `copy_files_to_left()` same as GSUB-03 | 7 |

### High findings

| Finding ID | Description | Step |
|---|---|---|
| EH-03 | No `tryCatch` around copy loop — partial copy on any file failure | 5 |
| EH-04 | No `tryCatch` around delete loop — partial delete on any file failure | 5 |
| EH-06 | No pre-flight permission check before multi-file operations | 5 |
| EH-11 | Zero `tryCatch` wrappers around any file-system operation in package | 5 |
| BK-02 | No timestamp on backup dirs — repeated syncs overwrite the same backup | 6 |
| BK-03 | `partial_symmetric_sync_common_files()` flat backup loses subdirectory structure | 6 |
| BK-04 | `full_symmetric_sync()` with custom `backup_dir` — right backup overwritten by left if basenames match | 6 |
| PH-03 | Windows backslash paths break `gsub()` regex on all 8 path-manipulation sites | 7 |

### Medium findings

| Finding ID | Description | Step |
|---|---|---|
| EH-02 | `dir.create()` return never checked in backup block | 5 |
| EH-05 | No `tryCatch` around `fs::dir_create()` in copy workers | 5 |
| EH-07 | `save_sync_status()` does not validate `dir_path` before proceeding | 5 |
| EH-08 | `hash_files()` / `hash_files_in_dir()` lapply with no tryCatch | 5 |
| EH-10 | `display_dir_tree()` called before validation — can error before abort | 5 |
| EH-12 | No post-operation verification of sync success | 5 |
| BK-01 | Backup timing inconsistent across 6 functions | 6 |
| BK-01b | `full_symmetric_sync()` backup created then immediately wasted on `by_content_only` abort | 6 |
| BK-05 | Default `tempdir()` backup is ephemeral — no user warning | 6 |
| PH-01 | No trailing-slash normalization on input paths | 7 |
| PH-02 | Relative paths not normalized to absolute in `sync_status` | 7 |

---

## Audit Completion Summary

The security audit is now complete across all seven steps. The following table maps all steps to their findings documents.

| Step | Title | Findings Document |
|---|---|---|
| 1 | File-system operations inventory | `.cg-docs/solutions/bugs/2026-04-06-security-audit-steps-1-2.md` |
| 2 | Input validation gap analysis | `.cg-docs/solutions/bugs/2026-04-06-security-audit-steps-1-2.md` |
| 3 | Destructive operation safety analysis | `.cg-docs/solutions/bugs/2026-04-06-security-audit-steps-3-4.md` |
| 4 | Race condition analysis | `.cg-docs/solutions/bugs/2026-04-06-security-audit-steps-3-4.md` |
| 5 | Permission and error handling analysis | `.cg-docs/solutions/bugs/2026-04-06-security-audit-steps-5-6-7.md` (this file) |
| 6 | Backup mechanism analysis | `.cg-docs/solutions/bugs/2026-04-06-security-audit-steps-5-6-7.md` (this file) |
| 7 | Path handling analysis | `.cg-docs/solutions/bugs/2026-04-06-security-audit-steps-5-6-7.md` (this file) |

### Total finding counts

| Severity | Count | Finding IDs |
|---|---|---|
| Critical | 7 | D1-G1, EH-01/BK-06, GSUB-01, GSUB-03, GSUB-04, VAL-09 (Step 2), VAL-10 (Step 2) |
| High | 28 | D1-G2, D1-G3, D1-G4, D1-G7, D1-G8, D2-G1, O1-G1, O1-G2, O1-G3, O2-G1, RC-01, RC-02, SC-01, SC-02, SC-04, RC-04, RC-07, EH-03, EH-04, EH-06, EH-11, BK-02, BK-03, BK-04, PH-03, GSUB-03, GSUB-04 (listed separately from above), plus others from Steps 1–2 |
| Medium | ~20 | See individual step matrices |
| Low | ~10 | See individual step matrices |
