# Code Review — `security` branch vs `DEV`

**Package:** syncdr v0.1.1  
**Branch:** `security` — Groups A–F (VUL-01 through VUL-35)  
**Scope:** `git diff DEV..security` — 9 R source files, 8 test files  
**Review depth:** standard (8 agents)  
**Date:** 2026-04-06  
**Test baseline at review:** FAIL 0 | WARN 8 | SKIP 4 | PASS 276  

---

## Priority legend

| Priority | Meaning |
|---|---|
| **P1** | Must fix before merge — correctness bug, data integrity risk, or actively wrong documentation |
| **P2** | Should fix — important quality, reproducibility, or performance concern |
| **P3** | Nice to have — style, minor refactor, advisory |

---

## P1 — Critical (must fix before merge)

### CODE-P1-01 · `copy_files_to_right` uses `recurse == TRUE` (bare `==`)
**File:** `R/action_functions.R` — `copy_files_to_right()`, first `if`  
`copy_files_to_left()` (same file) uses `isTRUE(recurse)`. If `recurse = NA`, the bare `==` errors at the `if` statement; `isTRUE()` safely returns `FALSE`. This is the more frequently called copy worker (all 6 sync functions use it).  
**Fix:**
```r
# change:
if (recurse == TRUE) {
# to:
if (isTRUE(recurse)) {
```

---

### CODE-P1-02 · `save_sync_status` — three interacting bugs
**File:** `R/auxiliary_functions.R` — `save_sync_status()`

**(a) No default for `syncdr.save_format` option:**  
`format <- getOption("syncdr.save_format")` returns `NULL` when the option is unset. `NULL == "fst"` returns `logical(0)`, which silently falls through all branches to `cli_abort()` with a misleading message.  

**(b) `switch()` case-mismatch — `"Rds"` vs `"rds"`:**  
The `if/else` chain produces the string `"Rds"` (capital R) as the fallback. The `switch()` key is `"rds"` (lowercase). `switch("Rds", "rds" = saveRDS(...))` returns `NULL` — the file is **never saved** for the most common fallback format.  

**(c) Dead variable `save_fun`:**  
`save_fun <- switch(format, ...)` — the side-effectful save operations execute inside the switch arms, but the return value assigned to `save_fun` is never used. Confusing and implies a deferred call that never fires.  

**Fix:**
```r
# (a) In zzz.R op.syncdr list, add:
syncdr.save_format = "rds"     # lowercase, consistent with switch

# (b/c) In save_sync_status, drop the dead assignment:
format <- getOption("syncdr.save_format", default = "rds")  # with defensive default
# ... and:
switch(format,
  "fst" = fst::write_fst(sync_status_table, path = file_path),
  "csv" = data.table::fwrite(sync_status_table, file = file_path),
  "rds" = saveRDS(sync_status_table, file = file_path)
)
```

---

### CODE-P1-03 · `filter_common_files` — no guard for missing date columns
**File:** `R/auxiliary_functions.R` — `filter_common_files()`  
When `sync_status` was built without `by_date = TRUE`, `is_new_left`/`is_new_right` columns are absent. If a caller passes `by_date = TRUE` with such an object, `sync_status$is_new_left` is `NULL`, and `fsubset(NULL & TRUE)` gives `logical(0)` or an error — silently wrong results or a cryptic crash.  
**Fix:** Add column-existence guard:
```r
if (by_date && is.null(sync_status$is_new_left)) {
  cli::cli_abort(c(
    "{.arg sync_status} does not contain date-comparison columns.",
    "i" = "Re-run {.fn compare_directories} with {.code by_date = TRUE}."
  ))
}
```

---

### TEST-P1-01 · Stray ` ) -----------------` in test-asym_sync.R
**File:** `tests/testthat/test-asym_sync.R` — `"partial update without recurse places top-level files at root"` test  
```r
  partial_update_missing_files_asym_to_right(
    ...
    force = TRUE
  ) -----------------      # <- runtime error: subtraction of undefined symbol
  expect_true(all(fs::file_exists(fs::path(right, top_files))))
```
The `expect_true(...)` line never executes — the test always errors, providing zero coverage of the assertion.  
**Fix:** Delete ` -----------------`.

---

### TEST-P1-02 · Backwards assertion in backup test
**File:** `tests/testthat/test-symm_sync.R` — `"full_symmetric_sync creates backup with correct contents"`  
```r
backed_up_file <- file.path(backup_subdirs[1], "testfile.txt")
expect_false(file.exists(backed_up_file))   # asserts file does NOT exist — wrong
```
This always passes vacuously. The correct path inside a `file.copy(from = right_path, recursive = TRUE)` backup is `backup_subdirs[1]/<basename(right)>/testfile.txt`.  
**Fix:**
```r
backed_up_file <- file.path(backup_subdirs[1], basename(right), "testfile.txt")
expect_true(file.exists(backed_up_file))
```

---

### DOC-P1-01 · `@param overwrite` in both copy workers says "silently skipped"
**File:** `R/action_functions.R` — `copy_files_to_right()` and `copy_files_to_left()`  
`@param overwrite` reads: *"If FALSE, existing destination files are preserved and the copy is skipped."*  
`fs::file_copy(overwrite = FALSE)` **throws an error** on an existing destination file. The `tryCatch` converts this to a `cli::cli_warn()` — so the file is skipped **with a warning**, not silently. Users who pass `overwrite = FALSE` expecting quiet no-ops will be surprised by warning streams.  
**Fix (both functions):**
```r
#' @param overwrite Logical, default is TRUE. If TRUE, existing files at the
#'   destination are overwritten. If FALSE, any attempt to copy a file that
#'   already exists at the destination triggers a per-file warning and that
#'   file is skipped; copying continues for all remaining files.
```

---

### DOC-P1-02 · `@param force` in `partial_update_missing_files_asym_to_right` documents old default
**File:** `R/asymmetric_sync.R` — `partial_update_missing_files_asym_to_right()`  
The `@param force` description reads *"If TRUE (by default)"* — but the new signature has `force = FALSE`. The docs state the opposite of the actual behavior.  
**Fix:**
```r
#' @param force Logical. If FALSE (default), displays a preview of actions and
#'   prompts the user for confirmation before proceeding. Synchronization is
#'   aborted if the user does not agree. If TRUE, directly performs
#'   synchronization without prompting.
```

---

### DOC-P1-03 · `common_files_asym_sync_to_right` — five parameters undocumented
**File:** `R/asymmetric_sync.R` — `common_files_asym_sync_to_right()`  
The parameters `force`, `backup`, `backup_dir`, `overwrite`, `verbose`, and `@return` are entirely absent from the roxygen block. They will not appear in the generated help page.  
**Fix:** Add the missing `@param` and `@return` lines after `@param recurse` (standard wording as in `update_missing_files_asym_to_right`).

---

### DOC-P1-04 · `full_symmetric_sync` — broken `@examples` block
**File:** `R/symmetric_sync.R` — `full_symmetric_sync()`  
The `@param force` description runs on without a closing tag; example code appears inside the `@param` text. The `@examples`, `@return`, `@export` tags are missing from the roxygen block. The generated help page will show code as part of the parameter description.  
**Fix:** Restructure the roxygen block — add a proper `@return`, `@export`, and `\donttest{...}` `@examples` block, and close the `@param force` sentence correctly.

---

## P2 — Important (should fix)

### CODE-P2-01 · `full_symmetric_sync` drops `recurse` from `copy_files_to_right` call
**File:** `R/symmetric_sync.R` — `full_symmetric_sync()`  
```r
copy_files_to_right(left_dir      = sync_status$left_path,
                    right_dir     = sync_status$right_path,
                    files_to_copy = files_to_right,
                    overwrite     = overwrite)   # recurse not passed!
```
`copy_files_to_left()` in the same function does receive `recurse = recurse`. A caller passing `recurse = FALSE` gets different behavior for the two copy directions — the left→right copy silently defaults to `recurse = TRUE`.  
**Fix:** Add `recurse = recurse` to the `copy_files_to_right()` call.

---

### CODE-P2-02 · Six `if (Ask == FALSE | is.na(Ask))` blocks use `|` instead of `||`
**Files:** `R/asymmetric_sync.R` (4×), `R/symmetric_sync.R` (2×)  
`|` is vectorised and does not short-circuit. `||` is the correct scalar boolean operator. Also inconsistent with `isFALSE()` used elsewhere.  
**Fix:** Replace all 6 occurrences with:
```r
if (isFALSE(Ask) || is.na(Ask)) {
```

---

### CODE-P2-03 · Mixed guard styles in `update_missing_files_asym_to_right`
**File:** `R/asymmetric_sync.R`  
The same function uses `if (copy_to_right == TRUE)` (bare `==`), `if (verbose)` (bare truthy), and `if (isTRUE(delete_in_right))` (correct) in the same function body.  
**Fix:** Standardise to `isTRUE()`/`isFALSE()` throughout:
```r
if (isTRUE(copy_to_right)) { ... }
if (isTRUE(verbose)) cli::cli_alert_info(...)
```

---

### CODE-P2-04 · `search_duplicates` uses `stopifnot` instead of `validate_path_arg`
**File:** `R/auxiliary_functions.R`  
Inconsistent with the rest of the package (which uses `cli::cli_abort()` via helpers). Users get a raw expression dump on failure.  
**Fix:** Replace with `validate_path_arg(dir_path, "dir_path")`.

---

### CODE-P2-05 · `filter_common_files` / `filter_non_common_files` use `stopifnot` for arg validation
**File:** `R/auxiliary_functions.R`  
Same issue as P2-04 — raw expression errors visible in stack traces to end users.  
**Fix:** Replace with `cli::cli_abort()` using descriptive messages.

---

### TEST-P2-01 · Top-level test pollution — broken test isolation
**Files:** `tests/testthat/test-asym_sync.R`, `tests/testthat/test-symm_sync.R`  
Substantial setup code (including actual sync operations) runs at file parse time, outside any `test_that()` block. This means:
- A single top-level failure silently breaks all subsequent tests in the file.
- Tests cannot be run individually via filter.
- Tests share mutable temp directories — test order matters.

**Fix:** Each `test_that()` block should own its fixture:
```r
test_that("...", {
  syncdr_temp <- copy_temp_environment()
  left <- syncdr_temp$left; right <- syncdr_temp$right
  # ... setup + assertions
})
```
This is a significant refactor. Flag as P2; address before 1.0.0.

---

### TEST-P2-02 · `common_files_to_copy empty still returns TRUE` has no assertion
**File:** `tests/testthat/test-asym_sync.R`  
`res` is assigned but never asserted. The test always passes vacuously.  
**Fix:** Add `expect_true(isTRUE(res))`.

---

### TEST-P2-03 · `handles missing common_files gracefully` uses fragile R-internal regexp
**File:** `tests/testthat/test-symm_sync.R`  
`regexp = "object .* not found|NULL"` matches an R version-dependent internal error. Will fail if the function is hardened with a package-level `cli_abort()` message.  
**Fix:** Match the package's own error message or use `class = "rlang_error"`.

---

### TEST-P2-04 · Missing positive case for `overwrite = FALSE` on new files
**File:** `tests/testthat/test-asym_sync.R`  
The `overwrite = FALSE` test only covers the "file exists, do not overwrite" case. A broken implementation that skips all copies when `overwrite = FALSE` would pass the existing test.  
**Fix:** Add a test that verifies `overwrite = FALSE` still copies files that do not yet exist at the destination.

---

### DOC-P2-01 · VUL-25 concurrent-use note is an orphaned topic
**File:** `R/syncdr-package.R`  
The concurrent-use section uses `@name syncdr-concurrent` which creates a **separate** help topic (`?syncdr-concurrent`), not a section in `?syncdr`. Users reading the package help page will never see it.  
**Fix:** Remove the `@name syncdr-concurrent` sentinel and either fold the `@section` directly into the `"_PACKAGE"` block above, or add `@rdname syncdr-package`.

---

### ARCH-P2-01 · `update_missing_files_asym_to_right` delete preview shown when `delete_in_right = FALSE`
**File:** `R/asymmetric_sync.R`  
The force preview always shows the delete table even when `delete_in_right = FALSE`. In `full_asym_sync_to_right` there is no qualifier at all; in `update_missing_files_asym_to_right` the message says "if delete is TRUE" but still shows the table. Users see a misleading picture.  
**Fix:** Gate the delete preview on `isTRUE(delete_in_right)`.

---

### ARCH-P2-02 · `partial_update_missing_files_asym_to_right` backup order inconsistency
**File:** `R/asymmetric_sync.R`  
This function runs backup **after** the force prompt (correct — no orphan backup on cancel). All other 5 sync functions run backup **before** the force prompt. This function is the reference; the other 5 should be updated to match.

---

### ARCH-P2-03 · `copy_files_to_right` / `copy_files_to_left` are 120 lines of duplicate code
**Files:** `R/action_functions.R`  
The only structural difference is which side is source/dest. Any future change must be applied twice. Current divergence (bare `==` vs `isTRUE()` in the `recurse` guard — see CODE-P1-01) is a direct consequence.  
**Fix:** Extract a private `copy_files_impl(src_dir, dest_dir, files_to_copy, src_col, dest_col, ...)` helper. Flag for a separate sprint.

---

### PERF-P2-01 · O(n²) failure-vector growth in copy loops
**File:** `R/action_functions.R` — both copy workers  
`failures <<- c(failures, path)` in the error handler creates a new vector on every failure — O(n²) for n failures. Harmless normally; catastrophic under mass-failure conditions (e.g., disconnected network share, permission denied on 10,000 files).  
**Fix:**
```r
failed <- logical(nrow(files_to_copy))
# in error handler:
failed[[i]] <<- TRUE
# after loop:
failures <- files_to_copy$path_from[failed]
```

---

### REPRO-P2-01 · `syncdr.staleness_threshold_secs` not registered in `zzz.R`
**File:** `R/zzz.R`  
`check_sync_status_staleness()` uses `getOption("syncdr.staleness_threshold_secs", 3600L)` with a defensive fallback — correct in production. But the option is not in the `op.syncdr` list in `.onLoad`, so `options()` doesn't show it, and any test reading the option without the fallback gets `NULL`.  
**Fix:** Add `syncdr.staleness_threshold_secs = 3600L` to `op.syncdr`.

---

### REPRO-P2-02 · `tempfile()` backup dirs created without cleanup in 3 test sites
**Files:** `tests/testthat/test-asym_sync.R` (lines ~574, ~900), `tests/testthat/test-symm_sync.R` (~177)  
`tempfile()` directories are created (via backup logic) but never deleted. Accumulates across test runs.  
**Fix:** Use `withr::local_tempdir()` or add `on.exit(fs::dir_delete(backup_dir), add = TRUE)`.

---

### REPRO-P2-03 · `format` variable shadows `base::format()` in `save_sync_status`
**File:** `R/auxiliary_functions.R`  
After reassignment, `format` holds a string. A later call to `format(Sys.time(), ...)` works today only because it appears before the shadowing reassignment. One line reorder → cryptic `"rds"(...)` error.  
**Fix:** Rename to `save_fmt`.

---

### VC-P2-01 · `NEWS.md` `0.1.1` entry is empty
**File:** `NEWS.md`  
All security fixes from Groups A–F are absent from the changelog. CRAN reviewers will see an empty `# syncdr 0.1.1` heading.  
**Fix:** Add a user-facing security/correctness summary under `# syncdr 0.1.1`.

---

### DQ-P2-01 · Delete preview shown in `full_asym_sync_to_right` even when `delete_in_right = FALSE`
**File:** `R/asymmetric_sync.R`  
Same as ARCH-P2-01 — listed here for DQ tracking. The `force = FALSE` preview shows files that will be deleted, but with default `delete_in_right = FALSE` no deletion occurs. The user is shown a misleading preview.

---

### DQ-P2-02 · `recurse = FALSE` silently overwrites on basename collisions — no warning
**File:** `R/action_functions.R`  
When multiple source files share a basename (e.g., `A/cfg.yaml` and `B/cfg.yaml`), `recurse = FALSE` flattens them to the same destination path — the second silently overwrites the first. No warning is issued.  
**Fix:** Detect duplicate basenames before copying and emit `cli::cli_warn()` listing the colliders.

---

## P3 — Minor (advisory)

| ID | File | Issue |
|---|---|---|
| CODE-P3-01 | `R/action_functions.R` | `else` on its own line (non-idiomatic) — move to `} else {` |
| CODE-P3-02 | `R/auxiliary_functions.R` | Two hash libraries (`xxhash32` vs `siphash13`) for same job — consolidate on `secretbase::siphash13` |
| CODE-P3-03 | `R/asymmetric_sync.R` | `partial_symmetric_sync_common_files` signature: `right_path` misaligned by 1 space |
| CODE-P3-04 | `R/asymmetric_sync.R` | Residual bare `if (verbose)` in `update_missing_files_asym_to_right` (2×) — use `isTRUE(verbose)` |
| CODE-P3-05 | `R/auxiliary_functions.R` | `save_sync_status` error message `"Save_format option raised an error"` is misleading — replace with actionable `cli_abort` |
| CODE-P3-06 | `R/utils.R` | `validate_backup_dir` uses hardcoded `"/"` separator — replace with `fs::path_has_parent()` |
| TEST-P3-01 | `test-asym_sync.R` | Two `test_that` blocks share name `"update missing file works"` — rename both |
| TEST-P3-02 | `test-symm_sync.R` | `by_content only` abort test duplicated 3× — keep VUL-34 variant, remove the other two |
| TEST-P3-03 | `test-asym_sync.R` | `sync_status_after$is_diff` should be `$common_files$is_diff` — `any(NULL)` always `FALSE` (dead coverage) |
| TEST-P3-04 | `test-utils.R` | `Sys.sleep(1.1)` in timestamp test — slow/flaky; mock `Sys.time()` or rely on sub-second clock |
| TEST-P3-05 | `test-asym_sync.R` | Collision test (`recurse = FALSE, basename collisions`) makes no assertion on which file wins |
| ARCH-P3-01 | `R/auxiliary_functions.R` | `save_fun <- switch(...)` dead variable — drop the assignment |
| ARCH-P3-02 | `R/auxiliary_functions.R` | `filter_*` and `search_duplicates` use `stopifnot()` — use `cli::cli_abort()` for consistency |
| ARCH-P3-03 | All sync files | 6 functions repeat identical 9-step orchestration pattern — extract shared helper (future sprint) |
| ARCH-P3-04 | All sync files | 11-parameter signatures with some silently ignored — consider `sync_options()` builder (breaking change, future sprint) |
| REPRO-P3-01 | `R/zzz.R` | `invisible()` → `invisible(NULL)` |
| REPRO-P3-02 | `test-asym_sync.R:496` | Add comment explaining `tempfile()` is intentionally a non-existent path |
| VC-P3-01 | git history | Group F is one commit for 11 VULs; future security work should match per-group commit pattern |
| VC-P3-02 | git history | Scope `fix(api)` imprecise — use `fix(security)` going forward |
| VC-P3-03 | git | Branch name `security` lacks type prefix — use `fix/security-audit-YYYY` convention in future |
| DQ-P3-01 | `R/asymmetric_sync.R` | `files_to_delete` null-guards in `update_missing_files_asym_to_right` never trigger — remove dead code |
| DQ-P3-02 | `R/asymmetric_sync.R` | `exclude_delete` uses reversed `%in%` direction — use `fname %in% exclude_delete` for clarity |
| DQ-P3-03 | `R/symmetric_sync.R` | Force preview uses `fselect(1)`/`fselect(2)` positional column selection — use named columns |
| PERF-P3-01 | `R/auxiliary_functions.R` | Sequential hashing in `hash_files()` / `hash_files_in_dir()` — backlog item for large directories |

---

## Summary counts

| Priority | Count | Action |
|---|---|---|
| **P1** | 9 | Must fix before merge |
| **P2** | 17 | Should fix before CRAN submission |
| **P3** | 23 | Advisory / backlog |

---

## Immediate action plan (P1s)

1. `R/action_functions.R` — `copy_files_to_right`: `recurse == TRUE` → `isTRUE(recurse)` (CODE-P1-01)
2. `R/auxiliary_functions.R` — `save_sync_status`: fix `"Rds"` vs `"rds"`, remove dead `save_fun`, add default (CODE-P1-02)
3. `R/auxiliary_functions.R` — `filter_common_files`: add missing-column guard (CODE-P1-03)
4. `tests/testthat/test-asym_sync.R` — delete stray ` -----------------` (TEST-P1-01)
5. `tests/testthat/test-symm_sync.R` — fix backwards `expect_false` backup assertion (TEST-P1-02)
6. `R/action_functions.R` — fix `@param overwrite FALSE` docs in both copy workers (DOC-P1-01)
7. `R/asymmetric_sync.R` — fix `@param force` default in `partial_update_missing_files_asym_to_right` (DOC-P1-02)
8. `R/asymmetric_sync.R` — add missing 5 params + `@return` to `common_files_asym_sync_to_right` (DOC-P1-03)
9. `R/symmetric_sync.R` — repair broken `@examples` block in `full_symmetric_sync` (DOC-P1-04)
