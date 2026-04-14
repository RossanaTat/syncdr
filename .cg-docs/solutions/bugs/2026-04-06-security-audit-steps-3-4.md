---
date: 2026-04-06
title: "Security Audit Findings — Steps 3 & 4: Destructive Operations and Race Conditions"
category: bugs
status: audit-findings
plan: ".cg-docs/plans/2026-04-05-security-audit-plan.md"
---

# Security Audit Findings — Steps 3 & 4

## Step 3: Destructive Operation Safety Analysis

### Methodology

Traced every code path that leads to `fs::file_delete()` or `fs::file_copy(overwrite = TRUE)`.
For each path: documented (1) user-facing safeguards, (2) defaults in effect, (3) backup ordering, (4) atomicity.

---

### 3.1 Deletion Code Paths

There are exactly **two** deletion sites in the entire package, both using `fs::file_delete()`:

#### DELETE PATH D1 — `full_asym_sync_to_right()` (`asymmetric_sync.R:214–228`)

```
full_asym_sync_to_right()
  └─ if (delete_in_right == TRUE)
       └─ if (NROW(files_to_delete) > 0)
            └─ lapply(..., function(i) fs::file_delete(files_to_delete$path_right[i]))
```

**What gets deleted**: every file in `sync_status$non_common_files` that has `sync_status == "only in right"` — i.e., files present in right but absent from left.

**Full decision tree:**

```
User calls full_asym_sync_to_right()
├─ [verbose == TRUE] → display_dir_tree() BEFORE validation (STRUCT-01)
├─ [arg check] → abort if arg combination invalid
├─ [if left/right paths provided] → stopifnot(fs::dir_exists()) for both paths
├─ [backup == TRUE] → file.copy(right → backup_dir) — NO SUCCESS CHECK
├─ [files_to_delete] = filter_non_common_files(dir = "right")
├─ [force == FALSE] → preview table + askYesNo()
│    └─ [No/Cancel/NA] → cli::cli_abort() — sync aborted
├─ copy_files_to_right() ← COPY RUNS FIRST (see DEST-01 below)
└─ [delete_in_right == TRUE]
     └─ [NROW > 0] → lapply(fs::file_delete) — ONE FILE AT A TIME, NO ROLLBACK
```

**Safeguards present:**
- `delete_in_right` flag (defaults `TRUE`)
- `force = FALSE` preview + confirmation (defaults `FALSE` — **confirmation OFF by default**)
- `backup` option (defaults `FALSE` — **backup OFF by default**)

**Safeguard gaps:**

| Gap ID | Description | Severity |
|---|---|---|
| D1-G1 | `force = TRUE` and `delete_in_right = TRUE` are both defaults → deletion occurs with zero user interaction by default | **Critical** |
| D1-G2 | `backup = FALSE` is the default → no safety net unless explicitly enabled | **High** |
| D1-G3 | No maximum deletion threshold — 10,000 files can be deleted with the same defaults as deleting 1 | **High** |
| D1-G4 | No dry-run mode — the only "preview" is the `force = FALSE` mode which is not the default | **High** |
| D1-G5 | **Copy executes before delete** — if copy succeeds for all files but then deletion fails midway, right directory has extra files AND some deleted. Left is unchanged. Partial state is inconsistent but in a safe direction (nothing lost from left). | Medium |
| D1-G6 | `exclude_delete` parameter does not exist in `full_asym_sync_to_right()` (only in `update_missing_files_asym_to_right()`) | Medium |
| D1-G7 | Backup success is not verified — `file.copy()` returns a logical vector; if it returns `FALSE` for some files, backup is incomplete but sync proceeds anyway | **High** |
| D1-G8 | `files_to_delete` is derived from a potentially stale `sync_status` (see Step 4 findings) | **High** |

---

#### DELETE PATH D2 — `update_missing_files_asym_to_right()` (`asymmetric_sync.R:671–685`)

```
update_missing_files_asym_to_right()
  └─ if (delete_in_right == TRUE)
       └─ [exclude_delete applied]
            └─ if (NROW(files_to_delete) > 0)
                 └─ lapply(..., function(i) fs::file_delete(files_to_delete$path_right[i]))
```

**What gets deleted**: right-only files not protected by `exclude_delete`.

**Full decision tree:**

```
User calls update_missing_files_asym_to_right()
├─ [verbose == TRUE] → display_dir_tree() BEFORE validation (STRUCT-01)
├─ [arg check] → abort if arg combination invalid
├─ [if paths provided] → stopifnot(fs::dir_exists())
├─ [files_to_delete] = filter_non_common_files(dir = "right")
├─ [is.null/!is.data.frame check] → normalise files_to_delete to data.frame
├─ [backup == TRUE] → file.copy(right → backup_dir) — NO SUCCESS CHECK
├─ [delete_in_right == TRUE]
│    └─ [exclude_delete validation] → stop() if not character (inconsistent error style)
│         └─ [keep_idx filtering] → excludes matched files from deletion list
├─ [force == FALSE] → preview + askYesNo()
│    └─ [No/Cancel/NA] → cli::cli_abort()
├─ [copy_to_right == TRUE] → copy_files_to_right()
└─ [delete_in_right == TRUE]
     └─ [NROW > 0] → lapply(fs::file_delete) — ONE FILE AT A TIME, NO ROLLBACK
```

**Additional gaps specific to D2:**

| Gap ID | Description | Severity |
|---|---|---|
| D2-G1 | `exclude_delete` matching uses `basename(p)` and path-part splitting — full paths silently fail to match (VAL-05 from Step 2) | **High** |
| D2-G2 | `exclude_delete` type error uses `stop()` not `cli::cli_abort()` — inconsistent with all other errors in this function | Low |
| D2-G3 | `files_to_delete` is normalised to a data.frame with `as.character()` coercion if not already a data.frame — this defensiveness is unique to this function and absent from D1 | Info |
| D2-G4 | Same D1-G1 through D1-G8 gaps apply | Same severity |

---

### 3.2 Overwrite Code Paths

All overwrites flow through `copy_files_to_right()` or `copy_files_to_left()`, which unconditionally pass `overwrite = TRUE`.

#### OVERWRITE PATH O1 — `copy_files_to_right()` (`action_functions.R:43–56`)

```
copy_files_to_right()
  └─ lapply(..., function(i)
       fs::file_copy(
         path     = files_to_copy$path_from[i],
         new_path = files_to_copy$path_to[i],
         overwrite = TRUE          ← HARDCODED
       ))
```

**Called by:** `full_asym_sync_to_right()`, `common_files_asym_sync_to_right()`, `update_missing_files_asym_to_right()`, `partial_update_missing_files_asym_to_right()`, `full_symmetric_sync()`, `partial_symmetric_sync_common_files()`.

**Overwrite safeguard gaps:**

| Gap ID | Description | Severity |
|---|---|---|
| O1-G1 | `overwrite = TRUE` is hardcoded — users have no way to prevent overwriting even if they suspect a conflict | **High** |
| O1-G2 | No pre-copy existence check — if `path_to` exists, it is silently overwritten without any notification | **High** |
| O1-G3 | Destination path is computed via `gsub()` without `fixed = TRUE` (GSUB-03) — a path with regex metacharacters can produce a wrong `path_to`, causing `fs::file_copy()` to overwrite an unintended file | **High** |
| O1-G4 | If `path_to` directory was just created by `fs::dir_create()` (line 41), but `path_to` already existed as a *file* (not a dir), `fs::dir_create()` would fail silently or error — not caught | Medium |
| O1-G5 | No return value from `fs::file_copy()` is checked — `fs::file_copy()` raises an error on failure (unlike `base::file.copy()` which returns logical), so individual failures do abort the loop; however, already-copied files are not rolled back | Medium |

#### OVERWRITE PATH O2 — `copy_files_to_left()` (`action_functions.R:107–120`)

Structurally identical to O1. All gaps O1-G1 through O1-G5 apply verbatim, with `right_dir`/`path_right` substituted for `left_dir`/`path_left`.

Additional gap specific to symmetric sync:

| Gap ID | Description | Severity |
|---|---|---|
| O2-G1 | In `full_symmetric_sync()`: `copy_files_to_right()` runs first, then `copy_files_to_left()`. If the right→left copy fails midway, the right directory already has new files from the first copy, but left is only partially updated. The two-phase copy is not atomic. | **High** |

---

### 3.3 Decision Trees for All Six Sync Functions

The following summarises the **safeguard sequence** for each sync function's destructive operations.

#### `full_asym_sync_to_right()` — Safeguard sequence

| Step | Operation | Safeguard | Default |
|---|---|---|---|
| 1 | Backup right | `backup` flag | `FALSE` (OFF) |
| 2 | Preview + confirm | `force` flag | `TRUE` (skip confirm) |
| 3 | Copy (overwrite) | `overwrite` hardcoded | Always overwrites |
| 4 | Delete right-only | `delete_in_right` flag | `TRUE` (delete) |

**Net default behaviour**: no backup, no confirmation, copy overwrites silently, deletions execute.

#### `common_files_asym_sync_to_right()` — Safeguard sequence

| Step | Operation | Safeguard | Default |
|---|---|---|---|
| 1 | Backup right | `backup` flag | `FALSE` (OFF) |
| 2 | Preview + confirm | `force` flag | `TRUE` (skip confirm) |
| 3 | Copy (overwrite) | `overwrite` hardcoded | Always overwrites |

**Net default behaviour**: no backup, no confirmation, copy overwrites silently. No deletion in this function.

#### `update_missing_files_asym_to_right()` — Safeguard sequence

| Step | Operation | Safeguard | Default |
|---|---|---|---|
| 1 | Backup right | `backup` flag | `FALSE` (OFF) |
| 2 | Exclude files from deletion | `exclude_delete` | `NULL` (no protection) |
| 3 | Preview + confirm | `force` flag | `TRUE` (skip confirm) |
| 4 | Copy (overwrite) | `copy_to_right` + hardcoded overwrite | `TRUE` / always overwrites |
| 5 | Delete right-only | `delete_in_right` flag | `TRUE` (delete) |

**Net default behaviour**: same as `full_asym_sync_to_right()`.

#### `partial_update_missing_files_asym_to_right()` — Safeguard sequence

| Step | Operation | Safeguard | Default |
|---|---|---|---|
| 1 | Preview + confirm | `force` flag | `TRUE` (skip confirm) |
| 2 | Backup right | `backup` flag | `FALSE` (OFF) |
| 3 | Copy (overwrite) | `overwrite` hardcoded | Always overwrites |

**No deletion** in this function. Backup runs after `force` prompt (INV-11).

#### `full_symmetric_sync()` — Safeguard sequence

| Step | Operation | Safeguard | Default |
|---|---|---|---|
| 1 | Preview + confirm | `force` flag | `TRUE` (skip confirm) |
| 2 | Backup right + left | `backup` flag | `FALSE` (OFF) |
| 3 | Copy left→right (overwrite) | `overwrite` hardcoded | Always overwrites |
| 4 | Copy right→left (overwrite) | `overwrite` hardcoded | Always overwrites |

**No deletion.** Two-phase copy not atomic (O2-G1).

#### `partial_symmetric_sync_common_files()` — Safeguard sequence

| Step | Operation | Safeguard | Default |
|---|---|---|---|
| 1 | Preview + confirm | `force` flag | `TRUE` (skip confirm) |
| 2 | Backup right + left | `backup` flag | `FALSE` (OFF) |
| 3 | Copy left→right (overwrite) | `overwrite` hardcoded | Always overwrites |
| 4 | Copy right→left (overwrite) | `overwrite` hardcoded | Always overwrites |

Same structure as `full_symmetric_sync()`.

---

### 3.4 Summary: Destructive Operation Finding Matrix

| Finding ID | Description | Severity | Affects |
|---|---|---|---|
| D1-G1 | `force = TRUE` + `delete_in_right = TRUE` defaults → zero-interaction deletion | **Critical** | `full_asym_sync_to_right()`, `update_missing_files_asym_to_right()` |
| D1-G2 | `backup = FALSE` default → no safety net by default | **High** | All 6 sync functions |
| D1-G3 | No deletion threshold ("abort if >N files") | **High** | Both delete paths |
| D1-G4 | No dry-run mode | **High** | All 6 sync functions |
| D1-G5 | Copy runs before delete — inconsistent post-failure state (safe direction) | Medium | `full_asym_sync_to_right()`, `update_missing_files_asym_to_right()` |
| D1-G6 | `exclude_delete` absent from `full_asym_sync_to_right()` | Medium | `full_asym_sync_to_right()` |
| D1-G7 | Backup success not verified before sync proceeds | **High** | All 6 sync functions |
| D2-G1 | `exclude_delete` full-path silent failure (see VAL-05) | **High** | `update_missing_files_asym_to_right()` |
| O1-G1 | `overwrite = TRUE` hardcoded, not configurable | **High** | `copy_files_to_right/left()` |
| O1-G2 | No pre-copy existence check — silent overwrites | **High** | `copy_files_to_right/left()` |
| O1-G3 | Wrong `path_to` via regex injection (GSUB-03/04) → overwrites unintended files | **High** | `copy_files_to_right/left()` |
| O1-G5 | No rollback after partial copy failure | Medium | `copy_files_to_right/left()` |
| O2-G1 | Two-phase symmetric copy not atomic — partial state if second copy fails | **High** | `full_symmetric_sync()`, `partial_symmetric_sync_common_files()` |

---

## Step 4: Race Condition Analysis

### Methodology

Analysed: (1) the time gap between `compare_directories()` and sync execution; (2) freshness indicators in `sync_status`; (3) `lapply()` loop interruptibility; (4) concurrent access scenarios; (5) partial-completion risk.

---

### 4.1 The Compare-Then-Sync Gap

syncdr's architecture is explicitly two-phase:

```
Phase 1: compare_directories() → sync_status object (snapshot of filesystem state)
Phase 2: sync function(sync_status)  → file operations based on snapshot
```

The gap between Phase 1 and Phase 2 can be seconds, minutes, or hours depending on usage patterns (e.g., user inspects the `sync_status` before deciding to sync). There is no mechanism to detect or warn about this gap.

#### RC-01: No timestamp on `sync_status` objects

The `sync_status` list returned by `compare_directories()` has four fields:
- `common_files` — data frame
- `non_common_files` — data frame
- `left_path` — character
- `right_path` — character

There is **no `created_at` timestamp** and no `snapshot_hash` or `snapshot_checksum` field. A `sync_status` object created days ago is structurally indistinguishable from one created seconds ago. If a user stores a `sync_status` and reuses it later, there is no way to detect staleness.

**Severity: High** — silent wrong operations on changed files.

#### RC-02: No freshness check before sync

All six sync functions accept a `sync_status` argument. None of them perform any freshness check before executing file operations. The validation logic (lines ~70–110 of each sync function) only checks whether the argument combination is valid — not whether the snapshot is current.

A re-scan before sync (an internal call to `compare_directories()` with the same parameters) would detect staleness, but this is not done.

**Severity: High** — could lead to copying a file that was already updated, or deleting a file that was already removed externally.

#### RC-03: Modification time resolution

`compare_directories()` uses `modification_time` from `fs::file_info()`, which has sub-second resolution on modern filesystems. However:
- On FAT32 (common on USB drives and some network shares), modification time resolution is **2 seconds**. Two files modified within 2 seconds of each other may appear to have the same timestamp.
- The `compare_modification_times()` function uses strict `>` comparison — equal timestamps produce `sync_status = "same date"` and are not synced. On FAT32, a genuinely newer file could be reported as "same date" if the difference is under 2 seconds.

**Severity: Medium** — silent missed sync on FAT32 or low-resolution filesystems.

---

### 4.2 Stale `sync_status` Scenarios

#### Scenario SC-01: External modification after compare

```
t=0: compare_directories(left, right) → sync_status
t=1: external process modifies right/file.csv (newer than left version)
t=2: full_asym_sync_to_right(sync_status = sync_status)
       → copies left/file.csv over right/file.csv  (left was "newer" at t=0)
       → right/file.csv reverts to the OLDER version
```

**Result**: silent data loss. The externally updated file in `right` is overwritten with the older `left` version.

#### Scenario SC-02: File deleted externally between compare and sync

```
t=0: compare_directories(left, right) → sync_status
       → sync_status$non_common_files shows right/temp.csv as "only in right"
t=1: external process deletes right/temp.csv
t=2: full_asym_sync_to_right(sync_status = sync_status)
       → delete_in_right == TRUE → fs::file_delete("right/temp.csv")
       → fs::file_delete() errors: file does not exist
```

**Result**: hard error mid-loop. Files processed before `temp.csv` in the `lapply()` have already been deleted. The loop aborts, leaving the right directory in a partially-synced state.

**Note**: `fs::file_delete()` raises an error (not a warning) on non-existent files, so this will surface visibly — but without recovery.

#### Scenario SC-03: New file added to left between compare and sync

```
t=0: compare_directories(left, right) → sync_status
       → left/new_report.csv not in sync_status (didn't exist at t=0)
t=1: new_report.csv is created in left
t=2: full_asym_sync_to_right(sync_status = sync_status)
       → new_report.csv NOT copied to right (not in sync_status)
```

**Result**: silent miss. The new file is silently not synced because it post-dates the comparison. No error, no warning.

#### Scenario SC-04: `sync_status` reused across sessions (cached/serialised)

If a user saves a `sync_status` object with `saveRDS()` and restores it in a later session, the file paths in `$common_files` and `$non_common_files` are absolute and may no longer exist, may point to different files, or may have stale modification timestamps. No class method prevents this misuse.

**Severity: High** — no protection against reuse of serialised `sync_status`.

---

### 4.3 `lapply()` Loop Interruptibility and Partial State

Both the copy loop (`copy_files_to_right/left()`) and the delete loop (`full_asym_sync_to_right()`, `update_missing_files_asym_to_right()`) are implemented as:

```r
invisible(
  lapply(
    cli::cli_progress_along(...),
    function(i) fs::file_copy/delete(...)
  )
)
```

#### RC-04: No atomicity — partial completion leaves inconsistent state

The `lapply()` iterates file-by-file. If any individual `fs::file_copy()` or `fs::file_delete()` call throws an error:
1. The error propagates out of the `lapply()` immediately.
2. All files processed before index `i` are already copied/deleted.
3. Files at index `i` and beyond are not processed.
4. There is no `on.exit()`, `tryCatch()`, or cleanup handler to record what was done or attempt rollback.

**For copy operations**: the left directory is unchanged; right is partially updated. The user can re-run the sync to complete it, but they have no log of what was already copied.

**For delete operations**: right-only files are partially deleted. Re-running the sync will complete the deletions — but any files that were supposed to be *kept* (via `exclude_delete` or a corrected `sync_status`) may have already been deleted.

**Severity: High** — partial delete state is especially dangerous because it cannot be safely resumed.

#### RC-05: No progress record or resumability

There is no mechanism to record which files have been successfully processed. If a sync of 10,000 files is interrupted at file 5,000, the user must either re-run the full sync (copying 5,000 files again) or manually determine what remains. There is no checkpoint file or transaction log.

**Severity: Medium** — operational inconvenience in large-scale syncs; data safety concern if delete operations are partially completed.

#### RC-06: User interrupt (Ctrl+C) mid-loop

R's `lapply()` is not interruptible in the sense that it does not catch `SIGINT`. If the user presses Ctrl+C while a `lapply()` is in progress, R raises an interrupt condition. This is equivalent to an error in RC-04 — partial state, no cleanup, no record.

**Severity: Medium** — expected behaviour in R, but worth documenting as a known risk for production use.

---

### 4.4 Concurrent Access

#### RC-07: No file locking

syncdr uses no file locking mechanism. On shared filesystems (network drives, Dropbox, SharePoint-mounted drives):
1. Two users can call `compare_directories()` on the same pair of directories simultaneously.
2. Both can receive `sync_status` objects and initiate sync operations concurrently.
3. Both `fs::file_copy()` operations can overwrite the same file. The last writer wins, and the result depends on OS-level write ordering — non-deterministic.

R provides no standard cross-process file locking API. The `filelock` package exists for this purpose but is not used or suggested by syncdr.

**Severity: High** — production risk on shared filesystems.

#### RC-08: Read during write — hash inconsistency

`compare_file_contents()` hashes files using `secretbase::siphash13(file = path)`. If a file is being written by another process while hashing is in progress, the hash may be computed over a partial write. This could:
- Cause a file to appear "different" when it is in the process of being updated to match.
- Cause a file to appear "same" if the partial write happens to produce a matching hash (extremely unlikely but theoretically possible).

**Severity: Low** — only relevant on actively-written files; unlikely in normal QA→PROD workflows.

---

### 4.5 Race Condition — Finding Matrix

| Finding ID | Description | Severity | Category |
|---|---|---|---|
| RC-01 | No timestamp on `sync_status` objects — staleness undetectable | **High** | Stale snapshot |
| RC-02 | No freshness check before sync executes | **High** | Stale snapshot |
| RC-03 | FAT32 / low-resolution timestamp → 2-second window of missed syncs | Medium | Timestamp resolution |
| SC-01 | External modification after compare → older version copied over newer | **High** | Stale snapshot |
| SC-02 | External deletion after compare → `fs::file_delete()` errors mid-loop, partial state | **High** | Stale snapshot + partial failure |
| SC-03 | New file added to left after compare → silently not synced | Medium | Stale snapshot |
| SC-04 | Serialised/cached `sync_status` reused across sessions | **High** | Stale snapshot |
| RC-04 | `lapply()` not atomic — error leaves inconsistent state (copy or delete) | **High** | Partial completion |
| RC-05 | No progress record — sync not resumable after interruption | Medium | Partial completion |
| RC-06 | Ctrl+C / user interrupt mid-loop → same as RC-04 | Medium | Partial completion |
| RC-07 | No file locking — concurrent sync on shared filesystem non-deterministic | **High** | Concurrent access |
| RC-08 | Hash computed on file being written by another process | Low | Concurrent access |

---

## Cross-Reference: Steps 3 & 4 Combined Risk Assessment

The most dangerous combinations of findings are where multiple vulnerabilities compound:

| Scenario | Findings Combined | Net Risk |
|---|---|---|
| User provides wrong `right_path` (T1/swapped args) with `force = TRUE`, `delete_in_right = TRUE` | D1-G1 + VAL-10 (no self-sync check) | **Catastrophic** — mass deletion of wrong directory with no confirmation |
| Stale `sync_status` from yesterday + force sync | RC-01 + RC-02 + D1-G1 | **High** — files updated overnight are overwritten with day-old versions |
| Large production sync on shared drive with concurrent users | RC-07 + RC-04 + D1-G2 | **High** — non-deterministic overwrites, partial states, no backup |
| `backup = TRUE` but backup fails silently, then deletion proceeds | D1-G7 + D1 delete loop | **High** — user believes backup exists but it doesn't; files deleted unrecoverably |
| Path with regex metacharacters (T10) + `copy_files_to_right()` | GSUB-03 + O1-G2 | **High** — files copied to wrong destinations, silently overwriting unrelated files |
