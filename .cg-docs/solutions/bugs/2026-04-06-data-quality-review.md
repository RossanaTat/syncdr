---
date: 2026-04-06
title: "syncdr — Data Quality & Correctness Review"
category: bugs
status: final
reviewer: "@cg-data-quality"
scope: "DEV branch — sync correctness, file routing, edge cases"
---

# syncdr — Data Quality & Correctness Review

**Package:** syncdr v0.1.1  
**Branch:** DEV  
**Review date:** 2026-04-06  
**Scope:** `R/action_functions.R`, `R/asymmetric_sync.R`, `R/symmetric_sync.R`, `R/auxiliary_functions.R`, `R/compare_directories.R`

Data quality in a file-sync package means: are the right files copied, are the right files deleted, and are there edge cases that leave directories in a corrupt or inconsistent state?

---

## Summary

| Priority | Count |
|---|---|
| P1 | 1 |
| P2 | 3 |
| P3 | 2 |
| **Total** | **6** |

---

## DQ-01 — `full_asym_sync_to_right`: delete preview shown when `delete_in_right = FALSE` (misleading, not a correctness bug)

| Field | Detail |
|---|---|
| **Priority** | P2 |
| **File** | `R/asymmetric_sync.R` |
| **Lines** | 157–165 |
| **Function** | `full_asym_sync_to_right()` |

**Description.** The force preview block unconditionally shows the delete table whenever `nrow(files_to_delete) > 0`, regardless of whether `delete_in_right = TRUE`:

```r
# asymmetric_sync.R ~L157-165
if (nrow(files_to_delete) > 0) {
  display_file_actions(path_to_files = files_to_delete,
                       directory     = right_path,
                       action        = "delete"
  )
}
```

Unlike `update_missing_files_asym_to_right()` (which shows the message "if delete is TRUE" as a hedge), `full_asym_sync_to_right()` shows the deletion list with no such qualifier. A user calling with `delete_in_right = FALSE` (the default) sees a list of files that will supposedly be deleted — and they will not be. The deletion only executes inside `if (isTRUE(delete_in_right))` further below (~L195).

This is not a correctness bug (no wrong files are actually deleted), but it is a user-facing data integrity issue: the operator is shown a false picture of what the sync will do, which erodes trust in the tool and can cause incorrect decisions.

**Recommended fix.** Gate the preview on `delete_in_right`:

```r
if (isTRUE(delete_in_right) && nrow(files_to_delete) > 0) {
  display_file_actions(path_to_files = files_to_delete,
                       directory     = right_path,
                       action        = "delete"
  )
}
```

**Note:** This same issue is flagged in the architecture review (ARC-04) for `update_missing_files_asym_to_right()`. The `full_asym_sync_to_right()` instance is more severe because it shows no hedging text at all.

---

## DQ-02 — `recurse = FALSE` with basename collisions silently overwrites files with no warning

| Field | Detail |
|---|---|
| **Priority** | P2 |
| **File** | `R/action_functions.R` |
| **Lines** | 41–44 (`copy_files_to_right`, `else` branch) |
| **Function** | `copy_files_to_right()` |

**Description.** When `recurse = FALSE`, all source files are flattened to `right_dir`:

```r
# action_functions.R ~L41-44
else {
  files_to_copy <- files_to_copy |>
    ftransform(path_from = path_left,
               path_to   = right_dir)
}
```

`fs::file_copy(path, new_path)` where `new_path` is a directory copies `path` into that directory using its basename. If two files from different subdirectories share the same basename (e.g., `A/config.yaml` and `B/config.yaml`), the second copy silently overwrites the first, because `overwrite = TRUE` is the default.

The test at `test-asym_sync.R:703` ("recurse = FALSE with basename collisions: last-writer deterministic") confirms this scenario exists but makes **no assertion about which file wins** and no assertion that a warning was issued. The test documents the collision is *possible* without verifying that the outcome is safe or that the user is informed.

Silent overwrite means:
- One source file is permanently lost from the right directory with no indication of which one.
- The operator cannot determine after the fact which `config.yaml` was kept.

This is a real data integrity risk for any non-trivial use of `recurse = FALSE`.

**Recommended fix.** Before copying, detect basename collisions and emit a `cli::cli_warn()` listing the affected files and their sources:

```r
else {
  # Detect basename collisions
  basenames <- basename(files_to_copy$path_left)
  dupes <- basenames[duplicated(basenames)]
  if (length(dupes) > 0) {
    dup_paths <- files_to_copy$path_left[basenames %in% dupes]
    cli::cli_warn(c(
      "{length(dupes)} basename collision{?s} detected with {.arg recurse = FALSE}.",
      "!" = "Only the last copy of each name will survive in {.path {right_dir}}.",
      "i" = "Colliding files: {.path {dup_paths}}"
    ))
  }
  files_to_copy <- files_to_copy |>
    ftransform(path_from = path_left, path_to = right_dir)
}
```

Update the test to `expect_warning()` when collisions are present.

---

## DQ-03 — `exclude_delete` null-guards run unconditionally before the `delete_in_right` gate

| Field | Detail |
|---|---|
| **Priority** | P3 |
| **File** | `R/asymmetric_sync.R` |
| **Lines** | 550–557 |
| **Function** | `update_missing_files_asym_to_right()` |

**Description.** The two null-coercion guards for `files_to_delete` execute unconditionally before the `if (isTRUE(delete_in_right))` block:

```r
# asymmetric_sync.R ~L550-557
if (is.null(files_to_delete)) {
  files_to_delete <- data.frame(path_right = character())
}
if (!is.data.frame(files_to_delete)) {
  files_to_delete <- data.frame(path_right = as.character(files_to_delete))
}
```

`filter_non_common_files(dir = "right") |> fselect(path_right)` always returns a `data.frame` (never `NULL`, never a bare vector) when the pipeline is healthy, so these guards never trigger in practice. They add confusion because a reader must ask: "when could `files_to_delete` be NULL here?" and can find no answer in the code path above.

More importantly, they create a subtle asymmetry: `full_asym_sync_to_right()` (which also uses `files_to_delete`) has **no such guards**. If the guards are actually needed for defensive correctness, they should be present in both functions; if they are not needed, they should be removed from `update_missing_files_asym_to_right()`.

**Assessment.** The guards are not needed. `fsubset() |> fselect()` on a `data.frame` returns an empty `data.frame` (zero rows), not `NULL`, when no rows match.

**Recommended fix.** Remove both guards. If defensive code is desired, add a single `stopifnot(is.data.frame(files_to_delete))` assertion to catch unexpected pipeline breakage in both functions — that makes the intent clear (it is an assertion, not a recovery).

---

## DQ-04 — `exclude_delete` `%in%` direction is reversed from the readable form (subtle readability/maintenance risk)

| Field | Detail |
|---|---|
| **Priority** | P3 |
| **File** | `R/asymmetric_sync.R` |
| **Lines** | 585–591 |
| **Function** | `update_missing_files_asym_to_right()` |

**Description.** The exclusion logic checks whether a file should be kept:

```r
keep_idx <- vapply(files_to_delete$path_right, function(p) {
  fname      <- basename(p)
  path_parts <- strsplit(fs::path_norm(p), .Platform$file.sep)[[1]]
  any(exclude_delete %in% fname) || any(exclude_delete %in% path_parts)
}, logical(1))
```

`any(exclude_delete %in% fname)` reads as "is any element of `exclude_delete` a member of `fname`?" — but `fname` is a scalar (length-1 character), so this is functionally identical to `fname %in% exclude_delete` (the natural reading: "is this filename in the exclusion list?"). The logic is **correct** for scalar `fname`, but the inverted direction is semantically unusual and could mislead a maintainer.

For `path_parts` (a vector), `any(exclude_delete %in% path_parts)` is correct: "does any exclusion pattern appear as a path segment?" Both forms are equivalent because `%in%` has `anyDuplicated`-like set semantics, but the `path_parts` form is the more natural write direction (needle on the left).

The real risk is a future maintainer changing `fname` from a scalar to a vector (e.g., to support batch processing) and not noticing that `any(exclude_delete %in% fname)` would then produce wrong results — it would check if any exclusion term appears anywhere in `fname` rather than if the specific filename is excluded.

**Recommended fix.** Standardise to the readable direction:

```r
keep_idx <- vapply(files_to_delete$path_right, function(p) {
  fname      <- basename(p)
  path_parts <- strsplit(fs::path_norm(p), .Platform$file.sep)[[1]]
  fname %in% exclude_delete || any(path_parts %in% exclude_delete)
}, logical(1))
```

This is equivalent for current inputs and is more defensively correct if `fname` ever becomes a vector.

---

## DQ-05 — `full_symmetric_sync`: `files_to_left` uses `fselect(2)` in the force preview — positional column selection is fragile

| Field | Detail |
|---|---|
| **Priority** | P2 |
| **File** | `R/symmetric_sync.R` |
| **Lines** | ~L168-174 (force preview block) |
| **Function** | `full_symmetric_sync()`, `partial_symmetric_sync_common_files()` |

**Description.** In both symmetric sync functions, the force preview selects the source path for the "copy to left" display using positional column selection:

```r
# symmetric_sync.R
display_file_actions(path_to_files = files_to_left |> fselect(2),
                     directory     = right_path,
                     action        = "copy"
)
```

`fselect(2)` selects column 2 of `files_to_left`. The data frame produced by `filter_non_common_files()` / `filter_common_files()` has columns `[path_left, path_right, sync_status]`. Column 2 is `path_right`, which is correct — files being copied *to* left originate from `path_right`.

However, this is positional coupling: if the column order in `filter_common_files()` or `filter_non_common_files()` ever changes (e.g., `sync_status` is moved before `path_right`, or a new column is prepended), column 2 silently becomes the wrong column. The copy-to-right preview uses `fselect(1)` for `path_left` (column 1) — same fragility.

In contrast, `full_asym_sync_to_right()` also uses `fselect(1)` for its copy preview. The issue is consistent across functions but is most dangerous in the symmetric case because both sides are involved and the column meaning differs by direction.

**Recommended fix.** Use named column selection:

```r
display_file_actions(path_to_files = files_to_right |> fselect(path_left),
                     directory     = left_path,
                     action        = "copy"
)

display_file_actions(path_to_files = files_to_left |> fselect(path_right),
                     directory     = right_path,
                     action        = "copy"
)
```

This is self-documenting and robust to column reordering.

---

## DQ-06 — `full_symmetric_sync`: snapshot-based sync does not re-check after first copy batch completes

| Field | Detail |
|---|---|
| **Priority** | P1 |
| **File** | `R/symmetric_sync.R` |
| **Lines** | ~L205-216 (synchronization block) |
| **Function** | `full_symmetric_sync()` |

**Description.** The symmetric sync function computes both `files_to_right` and `files_to_left` from a single `sync_status` snapshot taken at the start, then executes the two copy batches sequentially:

```r
# symmetric_sync.R
copy_files_to_right(...)  # batch 1: left → right
copy_files_to_left(...)   # batch 2: right → left
```

`files_to_left` was computed before batch 1 executed. Under normal conditions this is safe: `is_new_left` and `is_new_right` are mutually exclusive for any common file (a file cannot be newer in both directions simultaneously), so no common file appears in both `files_to_right` and `files_to_left`.

However, there are two real edge cases that can produce a corrupted outcome:

**Edge case A — Clock skew between batch 1 and batch 2.**  
If `copy_files_to_right` writes a file whose filesystem timestamp slightly differs from the source (e.g., due to filesystem resolution, NFS clock drift, or a copy implementation that does not preserve mtime), that file will appear "modified" when batch 2's `files_to_left` data was already computed. The snapshot cannot reflect this. The file may be overwritten in the wrong direction in batch 2 based on stale metadata.

**Edge case B — External modification during sync.**  
If an external process modifies a file in `right_dir` while batch 1 is running (copying from left to right), batch 2 may overwrite the externally-modified version with the stale snapshot version from `files_to_left`.

Neither edge case triggers under normal single-user single-machine usage with local filesystems that preserve mtime. The risk is elevated in:
- Network-mounted directories (NFS, SMB, cloud-synced folders like OneDrive/Dropbox)
- Directories monitored by backup or indexing services
- Multi-user environments

**Current state:** No documentation warns callers about this limitation. No test covers either edge case.

**Recommended mitigations (in order of increasing safety):**

1. **(Minimal — document)** Add a `@section Warning` to `full_symmetric_sync()` and `partial_symmetric_sync_common_files()` noting that the sync is snapshot-based and is not safe for concurrently-modified directories.

2. **(Better — detect)** After `copy_files_to_right` completes and before executing `copy_files_to_left`, re-stat the files in `files_to_left` and drop any whose `path_right` mtime has changed since the snapshot was taken:

```r
copy_files_to_right(...)

# Re-validate files_to_left before executing
files_to_left <- files_to_left |>
  fsubset(vapply(path_right, function(p) {
    identical(fs::file_info(p)$modification_time,
              <snapshot_mtime_right>)
  }, logical(1)))

copy_files_to_left(...)
```

3. **(Strongest — atomic)** Acquire an exclusive lock on both directories before the snapshot and release it after all copies. This is complex and platform-dependent; document as out of scope for current version.

Mitigation 1 is the minimum acceptable change. Mitigation 2 is recommended.

---

## Correctness Verification: Scenarios from Review Brief

| Scenario | Finding |
|---|---|
| 1. `filter_non_common_files(dir="left")` then `fselect(path_left)` — does any code accidentally reference `path_right`? | **No issue.** All copy operations read `path_left` via `copy_files_to_right`, which assigns `path_from = path_left`. No code dereferences `path_right` for left-only files. |
| 2. `full_asym_sync_to_right` delete path: `filter_non_common_files(dir="right") \|> fselect(path_right)` | **No issue.** Filter is `!is.na(path_right)`, selection is `path_right`. Both correct. |
| 3. `copy_files_to_right(recurse=FALSE)` baseline collision | **Issue filed as DQ-02 (P2).** Silent overwrite, no warning. |
| 4. `common_files_asym_sync_to_right` backup-before-copy ordering | **No issue.** Backup at ~L307 precedes `copy_files_to_right` at ~L338. |
| 5. `partial_update_missing_files_asym_to_right` backup-after-force | **Confirmed correct** (backup after force prompt). Inconsistency with other functions is an architecture concern (ARC-05), not a data integrity issue. |
| 6. `full_symmetric_sync` snapshot-based two-pass copy | **Issue filed as DQ-06 (P1).** Snapshot staleness under concurrent modification. |
| 7. `update_missing_files_asym_to_right` `files_to_delete` null-guards | **Issue filed as DQ-03 (P3).** Guards never trigger; create asymmetry with `full_asym_sync_to_right`. |
| 8. `exclude_delete` `%in%` direction | **Issue filed as DQ-04 (P3).** Logic correct today; fragile under vector refactor. |

---

## Remediation Order

| ID | Priority | Effort | Can be done now? |
|---|---|---|---|
| DQ-06 | P1 | Small–Medium (doc + optional re-stat) | Yes (doc); Next sprint (re-stat) |
| DQ-01 | P2 | Trivial — add `isTRUE(delete_in_right)` gate | Yes |
| DQ-02 | P2 | Small — collision detection + warn + test update | Yes |
| DQ-05 | P2 | Trivial — replace `fselect(1/2)` with named columns | Yes |
| DQ-03 | P3 | Trivial — remove 4 lines | Yes |
| DQ-04 | P3 | Trivial — swap `%in%` direction | Yes |

DQ-01, DQ-03, DQ-04, DQ-05 are safe to fix immediately with no logic change.  
DQ-02 requires adding a warning and updating `test-asym_sync.R:703`.  
DQ-06 minimum fix (documentation) is immediate; the re-stat mitigation requires a new internal helper and test.
