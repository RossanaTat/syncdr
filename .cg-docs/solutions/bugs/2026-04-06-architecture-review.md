---
date: 2026-04-06
title: "syncdr — Architecture Review"
category: bugs
status: final
reviewer: "@cg-architecture"
scope: "DEV branch — 9 source files in R/"
---

# syncdr — Architecture Review

**Package:** syncdr v0.1.1  
**Branch:** DEV  
**Review date:** 2026-04-06  
**Scope:** `R/action_functions.R`, `R/asymmetric_sync.R`, `R/symmetric_sync.R`, `R/auxiliary_functions.R`, `R/compare_directories.R`, `R/display_functions.R`, `R/print.R`, `R/utils.R`, `R/styling_functions.R`

Findings focus on DRY violations, responsibility boundaries, API consistency, parameter proliferation, and structural patterns that will cause maintenance problems. Security/correctness issues already catalogued in the vulnerability report are referenced but not repeated.

---

## Summary

| Priority | Count |
|---|---|
| P2 | 5 |
| P3 | 2 |
| **Total** | **7** |

No P1 findings. All correctness/security issues were addressed in the vulnerability report. Issues here are architectural and will cause maintenance debt if unaddressed.

---

## ARC-01 — `copy_files_to_right` / `copy_files_to_left` are near-identical (DRY violation)

| Field | Detail |
|---|---|
| **Priority** | P2 |
| **File** | `R/action_functions.R` |
| **Affected functions** | `copy_files_to_right()`, `copy_files_to_left()` |

**Description.** Both functions are ~120 lines long and structurally identical. The only differences are:

- Which column is the source path (`path_left` vs `path_right`)
- Which directory is the root for `fs::path_rel()` (`left_dir` vs `right_dir`)
- Which directory is the destination (`right_dir` vs `left_dir`)
- The label used in error messages and the `cli_progress_along()` name

Every other line — the `recurse` branch, the permission pre-check, the subdirectory creation, the `tryCatch`-wrapped copy loop, the failure collection, the summary warning — is duplicated verbatim. Any future change (e.g., adding a `dry_run` parameter, changing the progress label, adjusting error message wording) must be applied in both functions manually.

**Recommended approach.** Extract a private `copy_files_impl(src_dir, dest_dir, files_to_copy, src_col, recurse, overwrite)` helper. Both public functions become thin wrappers that set `src_col` and `dest_dir` and delegate:

```r
copy_files_to_right <- function(left_dir, right_dir, files_to_copy, recurse = TRUE, overwrite = TRUE) {
  copy_files_impl(
    src_dir       = left_dir,
    dest_dir      = right_dir,
    files_to_copy = files_to_copy,
    src_col       = "path_left",
    recurse       = recurse,
    overwrite     = overwrite
  )
}
```

---

## ARC-02 — All 6 top-level sync functions repeat the same orchestration pattern

| Field | Detail |
|---|---|
| **Priority** | P2 |
| **Files** | `R/asymmetric_sync.R`, `R/symmetric_sync.R` |
| **Affected functions** | `full_asym_sync_to_right()`, `common_files_asym_sync_to_right()`, `update_missing_files_asym_to_right()`, `partial_update_missing_files_asym_to_right()`, `full_symmetric_sync()`, `partial_symmetric_sync_common_files()` |

**Description.** Every sync function follows an identical control flow in the same order:

1. Validate the `sync_status` / path XOR argument rule  
2. Call `compare_directories()` or extract paths from `sync_status`  
3. Verbose "BEFORE" tree  
4. Backup  
5. Compute files to copy/delete  
6. Force prompt  
7. Execute copy/delete  
8. Verbose "AFTER" tree  
9. Green "✔ synchronized" message  

Steps 1–3 and 8–9 are copy-pasted across all 6 functions with only the variable names varying. This results in ~60–80 lines of near-identical boilerplate per function. Currently the functions diverge at step 4 (backup ordering — see ARC-05 below) and step 5 (what files are computed), which are the only legitimate differences.

Any change to the argument-validation error message, the verbose block, or the success message must be applied in 6 places. The backup ordering inconsistency (VUL-35 in the vulnerability report) is a direct consequence of this pattern: there is no shared orchestrator to enforce a canonical order.

**Recommended approach.** Flag now; do not redesign in this PR. A future refactor could extract a private `resolve_sync_inputs(left_path, right_path, sync_status, by_date, by_content, recurse)` helper for steps 1–2, and a `sync_bookends(verbose, left_path, right_path, phase)` helper for steps 3/8–9. This is a non-trivial refactor that requires updating tests; schedule as a separate work item.

---

## ARC-03 — Sync function parameter proliferation makes the API hard to use and test

| Field | Detail |
|---|---|
| **Priority** | P2 |
| **Files** | `R/asymmetric_sync.R`, `R/symmetric_sync.R` |
| **Affected functions** | All 6 exported sync functions |

**Description.** Every sync function carries the same 11-parameter signature:

```
left_path, right_path, sync_status, by_date, by_content, recurse,
force, backup, backup_dir, overwrite, verbose
```

Plus function-specific extras (`delete_in_right`, `copy_to_right`, `exclude_delete`). This creates several problems:

- **Cognitive load**: callers must know which of the 11 parameters apply to which function. `by_date`/`by_content` are meaningless in `update_missing_files_asym_to_right()` but still appear in the signature (they are silently ignored — no documentation note).
- **Test combinatorics**: 11 boolean-or-path parameters means the test space is enormous. In practice only a small fraction of combinations are covered.
- **Future parameters**: adding any new cross-cutting option (e.g., `dry_run`, `log_file`) requires touching all 6 function signatures and all 6 documentation blocks.

**Recommended approach.** Flag now; do not redesign in this PR. A `syncdr_options` list-object pattern (analogous to `httr::config()`) or a dedicated `sync_options()` constructor would reduce the per-call signature to `(left_path, right_path, sync_status, opts)`. Schedule as a separate API-design work item, as it is a breaking change.

---

## ARC-04 — `update_missing_files_asym_to_right` force preview is misleading when `delete_in_right = FALSE`

| Field | Detail |
|---|---|
| **Priority** | P2 |
| **File** | `R/asymmetric_sync.R` |
| **Affected function** | `update_missing_files_asym_to_right()` |

**Description.** The `force = FALSE` preview block always shows the delete preview when `nrow(files_to_delete) > 0`, regardless of the value of `delete_in_right`:

```r
if (nrow(files_to_delete) > 0) {
  style_msgs("orange", text = "These files will be DELETED in right if delete is TRUE")
  display_file_actions(...)
}

if (copy_to_right == TRUE && nrow(files_to_copy) > 0) {  # bare == TRUE
  ...
}
```

The message text acknowledges this with "if delete is TRUE", but showing the delete table at all when `delete_in_right = FALSE` is actively misleading — the user sees a deletion preview for an action that will not happen, then must interpret the parenthetical to understand no deletion is planned. Additionally, the copy guard uses bare `== TRUE` (a style inconsistency flagged as VUL-07 in the vulnerability report, but architecturally it signals the force block was not written with a consistent conditional style).

The correct behaviour is: show the delete preview only when `delete_in_right = TRUE`.

**Recommended fix.** Gate the delete preview on `delete_in_right`:

```r
if (isTRUE(delete_in_right) && nrow(files_to_delete) > 0) {
  style_msgs("orange", text = "These files will be DELETED in right")
  display_file_actions(...)
}

if (isTRUE(copy_to_right) && nrow(files_to_copy) > 0) {
  ...
}
```

---

## ARC-05 — `partial_update_missing_files_asym_to_right` runs backup after the force prompt

| Field | Detail |
|---|---|
| **Priority** | P2 |
| **File** | `R/asymmetric_sync.R` |
| **Affected function** | `partial_update_missing_files_asym_to_right()` |

**Description.** In the other 5 sync functions, the backup block runs **before** the force prompt. In `partial_update_missing_files_asym_to_right()`, the backup block runs **after** the force prompt:

```
# All other functions:        validate → get status → verbose → BACKUP → compute files → FORCE PROMPT → sync

# partial_update_...:         validate → get status → verbose → compute files → FORCE PROMPT → BACKUP → sync
```

When `force = FALSE` and `backup = TRUE`, a user who sees the preview and chooses "No" at the prompt will:
- In all other functions: have triggered a backup (unexpected orphan backup dir) — already flagged as VUL-35.
- In `partial_update_missing_files_asym_to_right()`: get exactly the expected behaviour (no backup created on cancel).

The ordering in `partial_update_missing_files_asym_to_right()` is arguably **more correct**, but it is inconsistent with the rest of the package. The package should adopt one canonical ordering and apply it everywhere. The vulnerability report (VUL-35) recommends: backup after user confirmation. This function should be used as the reference implementation.

**Recommended fix.** Standardise all 6 functions: backup block always runs after the force prompt and before the file operations. Update VUL-35 remediation to note `partial_update_missing_files_asym_to_right()` already has the correct ordering.

---

## ARC-06 — `save_sync_status` dead variable obscures control flow

| Field | Detail |
|---|---|
| **Priority** | P3 |
| **File** | `R/auxiliary_functions.R` |
| **Affected function** | `save_sync_status()` |

**Description.** The function assigns the result of `switch()` to `save_fun` but never uses it:

```r
save_fun <- switch(format,
  "fst" = fst::write_fst(x = sync_status_table, path = file_path),
  "csv" = fwrite(x = sync_status_table, file = file_path),
  "rds" = saveRDS(object = sync_status_table, file = file_path)
)
```

The save operations happen as **side effects inside the switch arms**, not by calling `save_fun()`. `save_fun` is bound to the return value of the matched arm (e.g., `fst::write_fst()` returns the written path invisibly; `saveRDS()` returns `NULL`). The variable is then abandoned.

This pattern is confusing because it looks like `save_fun` will be called later (as a function), but it is not. A reader unfamiliar with R's `switch()` evaluation semantics may assume the save has not yet occurred.

**Recommended fix.** Remove the assignment:

```r
switch(format,
  "fst" = fst::write_fst(x = sync_status_table, path = file_path),
  "csv" = fwrite(x = sync_status_table, file = file_path),
  "rds" = saveRDS(object = sync_status_table, file = file_path)
)
```

Or, if the intent is to call a saved function, restructure as:

```r
save_fun <- switch(format,
  "fst" = function() fst::write_fst(x = sync_status_table, path = file_path),
  "csv" = function() fwrite(x = sync_status_table, file = file_path),
  "rds" = function() saveRDS(object = sync_status_table, file = file_path)
)
save_fun()
```

The first form (drop the assignment) is simpler for current needs.

---

## ARC-07 — `filter_common_files` and `filter_non_common_files` use `stopifnot()` while the rest of the package uses `cli::cli_abort()`

| Field | Detail |
|---|---|
| **Priority** | P3 |
| **File** | `R/auxiliary_functions.R` |
| **Affected functions** | `filter_common_files()`, `filter_non_common_files()`, `search_duplicates()` |

**Description.** The package-wide convention for argument validation errors is `cli::cli_abort()` with structured messages. Three functions in `auxiliary_functions.R` instead use `stopifnot()`:

```r
# filter_common_files()
stopifnot(dir %in% c("left", "right", "all"))

# filter_non_common_files()
stopifnot(expr = { dir %in% c("left", "right", "all") })

# search_duplicates()
stopifnot(exprs = { fs::dir_exists(dir_path) })
```

`stopifnot()` produces error messages of the form `"dir %in% c("left", "right", "all") is not TRUE"` — a raw expression dump rather than a human-readable message. Because `filter_common_files()` and `filter_non_common_files()` are called from inside all 6 sync functions, a bad `dir` argument surfaces as an opaque error with no reference to the user-facing sync function that triggered it.

This is a lower-priority issue because these are `@keywords internal` functions and the `dir` argument is always set by the package itself, not by users. The `search_duplicates()` case is exported and mildly affects users.

**Recommended fix.** Replace `stopifnot()` with `cli::cli_abort()` in all three functions:

```r
# filter_common_files()
if (!dir %in% c("left", "right", "all")) {
  cli::cli_abort(c(
    "{.arg dir} must be one of {.val left}, {.val right}, or {.val all}.",
    "x" = "Got {.val {dir}}."
  ))
}
```

This is consistent with the validation pattern used in `update_missing_files_asym_to_right()` for `exclude_delete` (after the VUL-29 fix replaces the remaining `stop()` call).

---

## Remediation Order

| ID | Priority | Effort | Can be done now? |
|---|---|---|---|
| ARC-04 | P2 | Small — 2-line gate change | Yes |
| ARC-05 | P2 | Small — move backup block | Yes |
| ARC-06 | P3 | Trivial — remove assignment | Yes |
| ARC-07 | P3 | Small — 3 function edits | Yes |
| ARC-01 | P2 | Medium — extract helper, update tests | Next sprint |
| ARC-02 | P2 | Large — requires design decision | Backlog |
| ARC-03 | P2 | Large — breaking API change | Backlog |

ARC-04 through ARC-07 are safe to fix immediately without risk of regression. ARC-01 requires updating tests. ARC-02 and ARC-03 are architectural observations that should inform the next major version plan.
