---
date: 2026-04-06
title: "Security Audit Findings — Steps 1 & 2: File-System Inventory and Input Validation"
category: bugs
status: audit-findings
plan: ".cg-docs/plans/2026-04-05-security-audit-plan.md"
---

# Security Audit Findings — Steps 1 & 2

## Step 1: File-System Operations Inventory Verification

### Methodology

Grepped all files in `R/` for the following patterns:
- `fs::file_copy`, `fs::file_delete`, `fs::dir_create`, `fs::dir_ls`, `fs::file_info`, `fs::dir_tree`, `fs::dir_copy`, `fs::file_create`
- `file.copy`, `dir.create`, `file.create`, `dir.exists`, `file.exists`, `unlink`
- `saveRDS`, `readRDS`, `fwrite`, `write_fst`, `list.files`, `list.dirs`
- `gsub(.*path)`, `gsub(.*dir)`, `gsub(left`, `gsub(right`
- `overwrite =`, `recursive = TRUE`, `fixed = TRUE`

### 1.1 Verified: Complete File-System Call Inventory

The inventory in the plan is confirmed accurate with the following additions and refinements:

#### Confirmed entries (no changes needed)

All entries in the plan's Section 1.1 are confirmed present in source code.

#### New findings not in the original plan

| Finding ID | Location | Call | Description |
|---|---|---|---|
| **INV-01** | `asymmetric_sync.R:222` | `fs::file_delete()` in `full_asym_sync_to_right()` | Confirmed — delete loop at L222 |
| **INV-02** | `asymmetric_sync.R:680` | `fs::file_delete()` in `update_missing_files_asym_to_right()` | Confirmed — delete loop at L680 |
| **INV-03** | `asymmetric_sync.R:611` | `fs::path_norm()` in `update_missing_files_asym_to_right()` | Used inside `exclude_delete` path-part splitting — this is the **only** normalized path comparison in the entire package |
| **INV-04** | `symmetric_sync.R:447-448` | `list.files()` in `partial_symmetric_sync_common_files()` | Uses `list.files()` (base R) instead of `fs::dir_ls()` (used everywhere else) — inconsistency noted; `list.files()` returns character, not `fs_path`, so `fs` path methods won't work on the result |
| **INV-05** | `symmetric_sync.R:452-458` | `file.copy(copy.date = TRUE)` | `partial_symmetric_sync_common_files()` uniquely copies modification dates with files — other backup functions do NOT use `copy.date = TRUE`, so backups elsewhere do not preserve timestamps |
| **INV-06** | `symmetric_sync.R:217-222` | `file.copy()` for backup in `full_symmetric_sync()` | Uses `from = right_path` and `from = left_path` (copies the directory itself as a child of `to`) rather than the directory's contents — behavior differs from `partial_symmetric_sync_common_files()` which copies individual files |
| **INV-07** | `auxiliary_functions.R:127` | `gsub(dir, "", path)` in `directory_info()` | `dir` used directly as regex pattern with no `fixed = TRUE` |
| **INV-08** | `action_functions.R:28,92` | `gsub(left_dir, ...)`, `gsub(right_dir, ...)` in `copy_files_to_right/left()` | Path directory strings used as unescaped regex patterns |
| **INV-09** | `display_functions.R:15-16,128` | `gsub()` in `display_sync_status()`, `display_file_actions()` | Display-only, but still uses unescaped regex |
| **INV-10** | `print.R:95` | `gsub(fs::path_dir(root_path), "", new_path)` in `remove_root()` | Only `gsub()` in the codebase where the pattern is computed at runtime from another path function |

#### Notable absence: `unlink()`

`unlink()` is **not present** in any source file. All directory deletion (in tests) uses `unlink()` but the package itself only uses `fs::file_delete()` for targeted file removal. This is correct practice.

#### Notable absence: `tryCatch()` around file operations

The **only** `tryCatch()` in the entire package is in `utils.R:21` around `rstudioapi::getThemeInfo()` — a display utility. There is **zero error handling** around any file-system operation (`fs::file_copy`, `fs::file_delete`, `file.copy`, `dir.create`). This is confirmed across all source files.

---

### 1.2 Backup Ordering Analysis (Critical Finding)

The plan noted backup ordering as a concern. Code inspection reveals an inconsistency:

| Function | Backup Position Relative to Destructive Ops |
|---|---|
| `full_asym_sync_to_right()` | Backup at L127–L145 → **before** `files_to_copy/delete` computation and **before** sync. ✅ Correct order. |
| `common_files_asym_sync_to_right()` | Backup at L363–L387 → **after** `files_to_copy` computation, **before** sync. ✅ Correct order. |
| `update_missing_files_asym_to_right()` | Backup at L571–L591 → **after** `files_to_delete` computation but **before** `force` prompt and sync. ✅ Correct order. |
| `partial_update_missing_files_asym_to_right()` | Backup at L835–L858 → **after** `force` prompt, **before** sync. ⚠️ Backup occurs AFTER user confirmation — if user confirms, backup runs before file operations. But backup placement is after the `force` prompt, which means if user denies, backup still runs unnecessarily. Minor ordering issue. |
| `full_symmetric_sync()` | Backup at L186–L224 → **before** sync. ✅ But see **INV-06** — directory copy semantics differ. |
| `partial_symmetric_sync_common_files()` | Backup at L432–L459 → **after** `force` prompt. ⚠️ Same issue as `partial_update_missing_files_asym_to_right()`. |

**New finding (INV-11)**: In `partial_update_missing_files_asym_to_right()` and `partial_symmetric_sync_common_files()`, the backup block runs **after** the `force = FALSE` confirmation prompt. If the user says "No", the function aborts via `cli::cli_abort()` — but in `partial_update_missing_files_asym_to_right()`, the backup has NOT yet run (it's after the `force` block), so no unnecessary backup. However: if `force = TRUE`, the backup runs correctly before sync. The ordering in these two functions is: `force prompt` → `backup` → `sync`. In the other four functions it is: `backup` → `force prompt` → `sync`.

This asymmetry is documented but not a critical safety issue.

---

### 1.3 `gsub()` Regex Injection — Complete Catalog

Every `gsub()` call that operates on file paths, confirmed with no `fixed = TRUE` in any case:

| ID | File | Line | Pattern Source | Risk Scenario |
|---|---|---|---|---|
| GSUB-01 | `auxiliary_functions.R` | 127 | `dir` (user-supplied directory path) | Path `C:/Users/user.name/` — the `.` matches any character, so `gsub("user.name", "", "/home/username/data/file.csv")` removes `"username"` from unintended positions |
| GSUB-02 | `auxiliary_functions.R` | 327 | `dir_path` (user-supplied) | Same as above, affects display in `search_duplicates()` |
| GSUB-03 | `action_functions.R` | 28 | `left_dir` (user-supplied) | Used to compute `wo_root_left` — the relative path for destination. A wrong relative path leads to files being copied to wrong locations |
| GSUB-04 | `action_functions.R` | 92 | `right_dir` (user-supplied) | Same, for `copy_files_to_left()` |
| GSUB-05 | `display_functions.R` | 15 | `left_path` | Display only, lower severity |
| GSUB-06 | `display_functions.R` | 16 | `right_path` | Display only, lower severity |
| GSUB-07 | `display_functions.R` | 128 | `directory` | Display only, lower severity |
| GSUB-08 | `print.R` | 95 | `fs::path_dir(root_path)` | Pattern derived from a path — doubly indirect |

**Severity ranking**: GSUB-03 and GSUB-04 are the highest severity because they affect the computed destination path for actual file copy operations. A path like `C:/data (1)/project+files/` could cause files to be copied to wrong locations or trigger errors.

**Platform note (Windows-specific)**: Windows paths use `\` as separator, but `fs` normalizes to `/`. Paths with backslashes may produce unexpected `gsub()` behavior due to regex escape sequences.

---

## Step 2: Input Validation Gap Analysis

### Methodology

For each exported function, validated:
1. Every parameter and its expected type/constraints
2. Every validation check present in the code
3. Every missing validation

### 2.1 Exported Function Validation Matrix

---

#### `compare_directories()`

**Parameters:**

| Parameter | Expected Type/Constraints | Validated? | Missing |
|---|---|---|---|
| `left_path` | character(1), existing directory | `fs::dir_exists()` ✅ | Non-NULL, non-NA, non-`""`, length-1, not equal to `right_path`, not nested in `right_path` |
| `right_path` | character(1), existing directory | `fs::dir_exists()` ✅ | Same as `left_path` |
| `recurse` | logical(1) or positive integer | None ❌ | Not validated; if `NA` or negative integer is passed, `fs::dir_ls()` will fail with an opaque error |
| `by_date` | logical(1) | None ❌ | `NA` causes silent wrong results in `compare_modification_times()` |
| `by_content` | logical(1) | None ❌ | Same |
| `verbose` | logical(1) | None ❌ | `NA` causes `if (verbose == TRUE)` to silently evaluate as `FALSE` (no error, but unexpected) |

**New finding (VAL-01)**: `if (verbose == TRUE)` is used throughout (not `isTRUE(verbose)`). If `verbose = NA`, the condition silently evaluates to `NA`, which R treats as `FALSE` in an `if` statement — no error is thrown, and verbose output is silently suppressed. This affects all 6 sync functions and `compare_directories()`.

---

#### `full_asym_sync_to_right()`

**Parameters:**

| Parameter | Expected Type/Constraints | Validated? | Missing |
|---|---|---|---|
| `left_path` | character(1) or NULL | `!is.null()` + `fs::dir_exists()` ✅ | Non-NA, non-`""`, not equal to `right_path`, not nested |
| `right_path` | character(1) or NULL | Same ✅ | Same |
| `sync_status` | `syncdr_status` S3 object or NULL | `!is.null()` check only ✅ | **No class check** — any named list passes the NULL check. Downstream error on `sync_status$common_files$is_new_right` access |
| `by_date` | logical(1) | None ❌ | `NA` → wrong filtering in `filter_common_files()` |
| `by_content` | logical(1) | None ❌ | Same |
| `recurse` | logical(1) | None ❌ | Passed to `compare_directories()` which passes to `fs::dir_ls()` |
| `delete_in_right` | logical(1) | None ❌ | `NA` → `if (delete_in_right == TRUE)` evaluates to `NA` → not treated as TRUE or FALSE → delete block skipped silently |
| `force` | logical(1) | None ❌ | `NA` → `if (force == FALSE)` evaluates to `NA` → confirmation prompt skipped silently, sync proceeds |
| `backup` | logical(1) | None ❌ | `NA` → backup block skipped silently |
| `backup_dir` | character(1) or `"temp_dir"` | None ❌ | Not validated against `left_path` or `right_path`; no existence check |
| `verbose` | logical(1) | None ❌ | See VAL-01 |

**New finding (VAL-02)**: `sync_status` is never checked with `inherits(sync_status, "syncdr_status")`. Any named list with `$left_path`, `$right_path`, `$common_files`, `$non_common_files` passes silently. A malformed list (e.g., `common_files = "not_a_dataframe"`) causes an error deep inside `filter_common_files()` with no useful context about which argument was wrong.

**New finding (VAL-03)**: `force = NA` silently skips the confirmation prompt — the condition `if (force == FALSE)` evaluates to `NA` in R (not `TRUE`), so the `if` body is not entered. The sync proceeds without confirmation, as if `force = TRUE`. This is identical to the `verbose = NA` issue (VAL-01) but with much higher impact because it bypasses the safety confirmation.

**New finding (VAL-04)**: `delete_in_right = NA` silently skips deletion — the condition `if (delete_in_right == TRUE)` evaluates to `NA`, so deletion is skipped. The user would expect deletion to occur (or not) but gets neither, with no warning.

---

#### `common_files_asym_sync_to_right()`

Identical validation pattern to `full_asym_sync_to_right()` (minus `delete_in_right`). All findings VAL-01 through VAL-03 apply.

---

#### `update_missing_files_asym_to_right()`

All findings from `full_asym_sync_to_right()` apply, plus:

| Parameter | Validated? | Notes |
|---|---|---|
| `copy_to_right` | None ❌ | `NA` → `if (copy_to_right == TRUE)` evaluates to `NA` → copy silently skipped |
| `delete_in_right` | None ❌ | Same as VAL-04 |
| `exclude_delete` | `is.character()` + `length() == 0` ✅ | This is the **only** parameter in the entire package with a type check beyond `!is.null()`. Uses base `stop()` rather than `cli::cli_abort()` — inconsistent error style |

**New finding (VAL-05)**: `exclude_delete` matching uses `basename(p)` and path-part splitting on `fs::path_norm(p)`. If a user passes a full path (e.g., `exclude_delete = "/data/right/keep/file.csv"`) instead of a file/folder name, the match will fail silently — no error, the file will be deleted anyway. The parameter expects names or folder-name fragments, but this constraint is nowhere documented in the function signature or `@param` docs.

---

#### `partial_update_missing_files_asym_to_right()`

Identical to `full_asym_sync_to_right()` minus `delete_in_right`, `copy_to_right`, `exclude_delete`. All findings VAL-01 through VAL-04 apply.

---

#### `full_symmetric_sync()`

Identical validation pattern to `full_asym_sync_to_right()` (minus `delete_in_right`). All findings VAL-01 through VAL-04 apply.

**New finding (VAL-06)**: `by_date = FALSE, by_content = TRUE` combination triggers `cli::cli_abort()` — but this check occurs **after** the backup has already been executed (L229 vs. backup at L186–L224). Backup is wasted and the error message says "no action will be executed, directories unchanged" — but backup action was already taken.

---

#### `partial_symmetric_sync_common_files()`

Same as `full_symmetric_sync()`. VAL-06 applies.

---

#### `search_duplicates()`

| Parameter | Expected Type/Constraints | Validated? | Missing |
|---|---|---|---|
| `dir_path` | character(1), existing directory | `fs::dir_exists()` ✅ | Non-NA, non-`""`, length-1 |
| `verbose` | logical(1) | None ❌ | See VAL-01 |

---

#### `save_sync_status()`

| Parameter | Expected Type/Constraints | Validated? | Missing |
|---|---|---|---|
| `dir_path` | character(1), existing directory | **None** ❌ | No existence check at all — proceeds to `hash_files_in_dir()` then `directory_info()` which calls `fs::dir_ls()`. If path doesn't exist, error is thrown inside `directory_info()` with no user-friendly message |

**New finding (VAL-07)**: `save_sync_status()` is the **only** exported function with path argument that has zero validation. It calls internal functions that will error on bad paths, but with no context about `save_sync_status()` being the entry point.

---

#### `display_sync_status()`

| Parameter | Expected Type/Constraints | Validated? | Missing |
|---|---|---|---|
| `sync_status_files` | data frame with `path_left`, `path_right` columns | None ❌ | Column existence not checked; will fail on `fmutate()` with unclear error |
| `left_path` | character(1) | None ❌ | Not validated; used directly in `gsub()` |
| `right_path` | character(1) | None ❌ | Same |

---

#### `display_dir_tree()`

| Parameter | Expected Type/Constraints | Validated? | Missing |
|---|---|---|---|
| `path_left` | character(1) or NULL | None ❌ | No existence check — `fs::dir_tree()` errors if path doesn't exist |
| `path_right` | character(1) or NULL | None ❌ | Same |
| `recurse` | logical(1) | None ❌ | Unused in current implementation (not passed to `fs::dir_tree()`) — dead parameter |

**New finding (VAL-08)**: `display_dir_tree()` accepts a `recurse` parameter but does not pass it to `fs::dir_tree()`. The parameter is documented but silently ignored.

---

#### `compare_directories()` — Nested path check

**New finding (VAL-09)**: None of the path-accepting functions check whether `left_path` is a parent or ancestor of `right_path` (or vice versa). With `recurse = TRUE`, `directory_info()` calls `fs::dir_ls(path = left_path, recurse = TRUE)`, which would enumerate files inside `right_path` as part of the left directory listing. This causes `compare_directories()` to include right-directory files in the left-directory file list, leading to:
- Phantom "only in left" files that are actually in right
- Potentially copying those files back to right (no-ops) or triggering incorrect deletion

This is confirmed by the `joyn::joyn()` merge on `wo_root` — the `wo_root` for a nested path would be computed relative to `left_path`, making the right directory's files appear as left-only.

---

### 2.2 Summary: Complete Gap Matrix

| Gap ID | Affected Functions | Parameter | Issue | Severity |
|---|---|---|---|---|
| VAL-01 | All 6 sync + `compare_directories()` | `verbose` | `NA` silently suppresses output via `if (verbose == TRUE)` | Low |
| VAL-02 | All 4 asym + 2 symm sync | `sync_status` | No `inherits(sync_status, "syncdr_status")` check; any list passes | Medium |
| VAL-03 | All 6 sync | `force` | `NA` silently skips confirmation prompt; sync proceeds unconfirmed | **High** |
| VAL-04 | `full_asym_sync_to_right()`, `update_missing_files_asym_to_right()` | `delete_in_right` | `NA` silently skips deletion with no warning | **High** |
| VAL-05 | `update_missing_files_asym_to_right()` | `exclude_delete` | Full paths silently fail to match; files deleted despite exclusion intent | **High** |
| VAL-06 | `full_symmetric_sync()`, `partial_symmetric_sync_common_files()` | `by_date`/`by_content` combo | Backup runs before `by_content-only` abort check; wasted/confusing | Medium |
| VAL-07 | `save_sync_status()` | `dir_path` | Zero path validation; opaque downstream error | Medium |
| VAL-08 | `display_dir_tree()` | `recurse` | Documented parameter silently ignored | Low |
| VAL-09 | All path-accepting functions | `left_path`/`right_path` | No nested path check; nested dirs cause phantom file differences | **Critical** |
| VAL-10 | All path-accepting functions | `left_path`/`right_path` | No self-sync check (`left_path == right_path`) | **Critical** |
| VAL-11 | All path-accepting functions | `left_path`/`right_path` | No NA/empty-string/length check on paths | **High** |
| VAL-12 | All sync functions | `backup_dir` | Not validated against `left_path`/`right_path`; backup to same dir corrupts | **High** |
| GSUB-03 | `copy_files_to_right()` | `left_dir` | Regex injection in relative path computation — wrong copy destinations | **High** |
| GSUB-04 | `copy_files_to_left()` | `right_dir` | Same as GSUB-03 | **High** |
| GSUB-01 | `directory_info()` | `dir` | Regex injection in `wo_root` computation — wrong file matching | **High** |

---

### 2.3 Structural Validation Issues

**Finding (STRUCT-01): Validation runs AFTER verbose display**

In `full_asym_sync_to_right()`, `update_missing_files_asym_to_right()`, `partial_update_missing_files_asym_to_right()`, `full_symmetric_sync()`, and `partial_symmetric_sync_common_files()`:

```r
# verbose block runs first (L58-L70)
if (verbose == TRUE) {
  display_dir_tree(path_left = left_path, path_right = right_path)
}

# THEN argument validation (L72+)
if (!(is.null(sync_status) && ...)) { ... }
```

`display_dir_tree()` calls `fs::dir_tree()` on the paths. If the paths are invalid (NULL when `sync_status` is provided, or non-existent), `fs::dir_tree()` will crash **before** the argument validation logic runs. This produces a confusing error from inside `display_dir_tree()` rather than a clear argument-validation message.

**Finding (STRUCT-02): Inconsistent error signaling**

The codebase uses at least three different error mechanisms:
- `cli::cli_abort()` — used by sync functions
- `stopifnot()` — used for path existence checks
- `stop()` — used for `exclude_delete` type check in `update_missing_files_asym_to_right()`

This makes it harder to mock errors in tests and produces inconsistent error messages for users.

**Finding (STRUCT-03): `NA` comparison with `==`**

Throughout all sync functions, conditions like `if (force == FALSE)`, `if (delete_in_right == TRUE)`, `if (verbose == TRUE)`, `if (backup)` use `==` comparison instead of `isTRUE()`/`isFALSE()`. In R, `NA == FALSE` evaluates to `NA` (not `TRUE`), so `if(NA)` signals an error: "argument is not interpretable as logical". However, `NA == TRUE` also evaluates to `NA`, so `if (verbose == TRUE)` with `verbose = NA` behaves as `if (NA)` and R raises: _"Error in if (verbose == TRUE) : argument is not interpretable as logical"_. This means `NA` logical inputs DO produce an error — but only when the condition is actually evaluated.

However: `if (force == FALSE)` with `force = NA` → `NA` → R raises an error. But the error comes from the `if` statement, not from argument validation, and the message is generic. The current tests confirm this raises an error (see `test-asym_sync.R`: `"by_date = NA or by_content = NA errors"`), but the validation happens implicitly via R's `if` mechanics rather than explicit guards.

**Revised severity for VAL-03/VAL-04**: These produce errors (rather than silently proceeding) only when the code path that checks the condition is actually reached. If the condition is not evaluated (e.g., early return), `NA` values could persist silently.

---

## Summary of New Findings

The following findings are **additions** to what was documented in the plan:

| ID | Type | Severity | Description |
|---|---|---|---|
| INV-03 | Inventory | Info | `fs::path_norm()` used only once, in `exclude_delete` matching |
| INV-04 | Inventory | Medium | `list.files()` used in `partial_symmetric_sync_common_files()` backup — inconsistent with `fs::dir_ls()` used elsewhere |
| INV-05 | Inventory | Medium | `copy.date = TRUE` only in `partial_symmetric_sync_common_files()` backup — other backups don't preserve timestamps |
| INV-06 | Inventory | Medium | `full_symmetric_sync()` copies directory-as-child rather than contents — semantics differ from `partial_symmetric_sync_common_files()` |
| INV-10 | Inventory | Medium | `gsub()` in `print.R` uses a runtime-computed pattern (`fs::path_dir(root_path)`) — doubly indirect |
| INV-11 | Inventory | Low | Backup-after-force ordering in `partial_update_missing_files_asym_to_right()` and `partial_symmetric_sync_common_files()` |
| VAL-01 | Validation | Low | `if (verbose == TRUE)` pattern across all functions |
| VAL-02 | Validation | Medium | No `inherits(sync_status, "syncdr_status")` check |
| VAL-03 | Validation | High | `force = NA` behavior (error from R's `if`, not explicit guard) |
| VAL-04 | Validation | High | `delete_in_right = NA` behavior |
| VAL-05 | Validation | High | `exclude_delete` silent failure when full paths passed |
| VAL-06 | Validation | Medium | Backup runs before `by_content-only` abort in symmetric sync |
| VAL-07 | Validation | Medium | `save_sync_status()` has zero path validation |
| VAL-08 | Validation | Low | `display_dir_tree()` `recurse` parameter silently ignored |
| VAL-09 | Validation | **Critical** | No nested path check — nested dirs cause phantom file differences |
| VAL-10 | Validation | **Critical** | No self-sync check |
| VAL-11 | Validation | High | No NA/empty-string/length check on paths |
| VAL-12 | Validation | High | `backup_dir` not validated against sync paths |
| GSUB-01 | Path handling | High | `gsub(dir, ...)` in `directory_info()` — regex injection |
| GSUB-03 | Path handling | **High** | `gsub(left_dir, ...)` in `copy_files_to_right()` — wrong copy destinations |
| GSUB-04 | Path handling | **High** | `gsub(right_dir, ...)` in `copy_files_to_left()` — wrong copy destinations |
| STRUCT-01 | Structure | Medium | Verbose display runs before argument validation in 5 functions |
| STRUCT-02 | Structure | Low | Three different error signaling mechanisms (`cli_abort`, `stopifnot`, `stop`) |
| STRUCT-03 | Structure | Medium | `NA` logical inputs produce generic R `if()` errors rather than informative validation messages |
