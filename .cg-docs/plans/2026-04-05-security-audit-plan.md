---
date: 2026-04-05
title: "Security Audit Plan for syncdr"
status: completed
completed-date: 2026-04-06
brainstorm: ""
language: "R"
estimated-effort: "large"
tags: [security, audit, file-system, destructive-operations, input-validation, testing]
steps-completed:
  - "1: File-system operations inventory verification (2026-04-06)"
  - "2: Input validation gap analysis (2026-04-06)"
  - "3: Destructive operation safety analysis (2026-04-06)"
  - "4: Race condition analysis (2026-04-06)"
  - "5: Permission and error handling analysis (2026-04-06)"
  - "6: Backup mechanism analysis (2026-04-06)"
  - "7: Path handling analysis (2026-04-06)"
findings:
  - ".cg-docs/solutions/bugs/2026-04-06-security-audit-steps-1-2.md"
  - ".cg-docs/solutions/bugs/2026-04-06-security-audit-steps-3-4.md"
  - ".cg-docs/solutions/bugs/2026-04-06-security-audit-steps-5-6-7.md"
---

# Plan: Security Audit Plan for syncdr

## Objective

Perform a comprehensive security audit of the syncdr R package to identify, categorize, and document all vulnerabilities related to file-system operations, destructive actions (deletion, overwrite), input validation, race conditions, and permission handling. The audit will produce a structured vulnerability inventory, a threat model, a testing strategy for safety, and recommendations for future hardening — without implementing any fixes.

## Context

syncdr is a CRAN-published R package (v0.1.1) that compares and synchronizes directories by detecting differences in file content or metadata, and propagates updates by copying, overwriting, and deleting files. It is used in production workflows (e.g., QA → PROD syncs involving thousands of files). The package is maintained by the PIP Technical Team (Andres and Rossana) at the World Bank.

The package currently has:
- **13 exported functions** (see NAMESPACE) spanning comparison, synchronization (asymmetric and symmetric), display, and utility operations.
- **7 internal functions** (`copy_files_to_right`, `copy_files_to_left`, `filter_common_files`, `filter_non_common_files`, `directory_info`, `compare_modification_times`, `compare_file_contents`, `hash_files`, `hash_files_in_dir`, `style_msgs`, `rs_theme`, `display_file_actions`).
- **10 test files** in `tests/testthat/`, covering action functions, async sync, symmetric sync, auxiliary functions, compare directories, display functions, print, toy dirs, and utils.
- Dependencies on `fs`, `collapse`, `data.table`, `joyn`, `digest`, `secretbase`, `cli`, `DT`, `knitr`.

This plan is audit-only. No code changes will be made.

---

## 1. File-System Interaction Inventory

### 1.1 All functions interacting with the file system

The following is a complete inventory of every function that reads, writes, creates, copies, or deletes files/directories, organized by source file and operation type.

#### A. File/directory READING operations

| Function | Source File | Operations | Notes |
|---|---|---|---|
| `directory_info()` | `auxiliary_functions.R` | `fs::dir_ls()`, `fs::file_info()` | Lists and stats all files recursively |
| `compare_directories()` | `compare_directories.R` | Calls `directory_info()` twice | Reads both left and right dirs |
| `hash_files()` | `auxiliary_functions.R` | `secretbase::siphash13(file=)` | Reads file content for hashing |
| `hash_files_in_dir()` | `auxiliary_functions.R` | `fs::dir_ls()`, `digest::digest(file=TRUE)` | Lists dir and hashes every file |
| `search_duplicates()` | `auxiliary_functions.R` | Calls `hash_files_in_dir()` | Reads all files in a directory |
| `save_sync_status()` | `auxiliary_functions.R` | Calls `hash_files_in_dir()`, `directory_info()` | Reads dir for saving status |
| `display_dir_tree()` | `display_functions.R` | `fs::dir_tree()` | Reads directory structure for display |

#### B. File COPY operations (potentially overwriting)

| Function | Source File | Operations | Key Detail |
|---|---|---|---|
| `copy_files_to_right()` | `action_functions.R` | `fs::dir_create()`, `fs::file_copy(overwrite=TRUE)` | **Always overwrites** — hardcoded `overwrite = TRUE` |
| `copy_files_to_left()` | `action_functions.R` | `fs::dir_create()`, `fs::file_copy(overwrite=TRUE)` | **Always overwrites** — hardcoded `overwrite = TRUE` |
| `toy_dirs()` | `toy_dirs.R` | `fs::dir_create()`, `saveRDS()`, `fs::file_copy()`, `fs::file_create()` | Creates test fixtures in tempdir |
| `copy_temp_environment()` | `toy_dirs.R` | `fs::dir_create()`, `fs::dir_copy()` | Copies test dirs |

#### C. File DELETE operations

| Function | Source File | Operations | Key Detail |
|---|---|---|---|
| `full_asym_sync_to_right()` | `asymmetric_sync.R` | `fs::file_delete()` | Deletes right-only files; controlled by `delete_in_right` flag |
| `update_missing_files_asym_to_right()` | `asymmetric_sync.R` | `fs::file_delete()` | Deletes right-only files; controlled by `delete_in_right` and `exclude_delete` |

#### D. File/directory CREATE operations

| Function | Source File | Operations | Key Detail |
|---|---|---|---|
| `copy_files_to_right()` | `action_functions.R` | `fs::dir_create()` | Creates destination subdirectories |
| `copy_files_to_left()` | `action_functions.R` | `fs::dir_create()` | Creates destination subdirectories |
| `save_sync_status()` | `auxiliary_functions.R` | `dir.create()`, `fst::write_fst()` / `fwrite()` / `saveRDS()` | Creates `_syncdr/` subdirectory and saves status file |

#### E. BACKUP operations (file.copy to backup_dir)

| Function | Source File | Operations | Key Detail |
|---|---|---|---|
| `full_asym_sync_to_right()` | `asymmetric_sync.R` | `dir.create()`, `file.copy(recursive=TRUE)` | Backs up right dir before sync |
| `common_files_asym_sync_to_right()` | `asymmetric_sync.R` | `dir.create()`, `file.copy(recursive=TRUE)` | Backs up right dir before sync |
| `update_missing_files_asym_to_right()` | `asymmetric_sync.R` | `dir.create()`, `file.copy(recursive=TRUE)` | Backs up right dir before sync |
| `partial_update_missing_files_asym_to_right()` | `asymmetric_sync.R` | `dir.create()`, `file.copy(recursive=TRUE)` | Backs up right dir before sync |
| `full_symmetric_sync()` | `symmetric_sync.R` | `dir.create()`, `file.copy(recursive=TRUE)` | Backs up **both** dirs |
| `partial_symmetric_sync_common_files()` | `symmetric_sync.R` | `dir.create()`, `file.copy(recursive=TRUE)`, `list.files()` | Backs up both dirs |

### 1.2 All destructive operations

**Destructive** = any operation that deletes, overwrites, or irreversibly modifies existing files.

| Category | Functions | Mechanism |
|---|---|---|
| **File deletion** | `full_asym_sync_to_right()`, `update_missing_files_asym_to_right()` | `fs::file_delete()` on right-only files |
| **File overwrite** | `copy_files_to_right()`, `copy_files_to_left()` | `fs::file_copy(overwrite = TRUE)` — hardcoded, not user-configurable |
| **Directory creation** | All copy functions, `save_sync_status()` | `fs::dir_create()`, `dir.create(recursive=TRUE)` — creates dirs that did not exist |

### 1.3 Input validation inventory

| Function | Validation Present | What Is Validated | What Is NOT Validated |
|---|---|---|---|
| `compare_directories()` | `stopifnot(fs::dir_exists())` | Both paths exist as directories | Path is not empty string; path is not NA; paths are not identical; paths are not nested |
| `full_asym_sync_to_right()` | Argument mutual exclusion check; `stopifnot(fs::dir_exists())` | Correct arg combo; dirs exist | Types of `by_date`/`by_content`; `left_path == right_path` check; path traversal |
| `common_files_asym_sync_to_right()` | Same as above | Same | Same gaps |
| `update_missing_files_asym_to_right()` | Same + `exclude_delete` type check | Same + exclude_delete is character | Same gaps |
| `partial_update_missing_files_asym_to_right()` | Same as full_asym minus delete | Same | Same gaps |
| `full_symmetric_sync()` | Same as full_asym | Same | Same gaps |
| `partial_symmetric_sync_common_files()` | Same | Same | Same gaps |
| `search_duplicates()` | `stopifnot(fs::dir_exists())` | Path exists | Not empty; not NA |
| `save_sync_status()` | None for dir_path | — | Path existence not checked before hashing |
| `filter_common_files()` | `stopifnot(dir %in% c(...))` | `dir` argument value | No check on input data frame structure |
| `filter_non_common_files()` | `stopifnot(dir %in% c(...))` | `dir` argument value | No check on input data frame structure |
| `copy_files_to_right()` | None | — | No validation of `left_dir`, `right_dir`, `files_to_copy` |
| `copy_files_to_left()` | None | — | No validation of `left_dir`, `right_dir`, `files_to_copy` |

---

## 2. Threat Model

### 2.1 Threat actors and scenarios

| ID | Threat | Actor | Scenario | Impact |
|---|---|---|---|---|
| T1 | **Swapped source/target** | User error | User passes `left_path` and `right_path` in wrong order to `full_asym_sync_to_right()`. Production files deleted, QA files overwrite production. | **Critical** — data loss |
| T2 | **Self-sync** | User error | User passes the same path as both `left_path` and `right_path`. Behavior undefined. | **High** — unpredictable |
| T3 | **Nested directory sync** | User error | `left_path` is a parent of `right_path` (or vice versa). Recursive listing may cause infinite loops or corrupted state. | **High** — infinite loop or corruption |
| T4 | **Empty/NA path** | User error / programmatic | Path argument is `""`, `NA`, `NULL`, or whitespace. `fs::dir_exists("")` returns `FALSE` but `gsub("", ...)` on paths produces unexpected results. | **Medium** — unclear errors |
| T5 | **Large-scale unintended deletion** | User error | `full_asym_sync_to_right()` on wrong directories; `delete_in_right = TRUE` (default) wipes thousands of production files. | **Critical** — mass data loss |
| T6 | **Race condition: compare-then-sync** | Concurrent access | Files change between `compare_directories()` and sync execution. Stale `sync_status` leads to wrong copy/delete decisions. | **High** — silent data corruption |
| T7 | **Race condition: stale sync_status reuse** | User error | User caches a `sync_status` object, modifies directories manually, then passes stale object to sync function. | **High** — wrong operations |
| T8 | **Partial failure mid-sync** | I/O error | Copy succeeds for some files but fails mid-operation (disk full, permission denied). No rollback mechanism. Directory left in inconsistent state. | **High** — partial corruption |
| T9 | **Permission errors** | Environment | Read-only source or destination. Functions may fail partway through with no cleanup. | **Medium** — inconsistent state |
| T10 | **Path traversal via gsub** | Input manipulation | `gsub(left_dir, "", path_left)` is used to compute relative paths. If `left_dir` contains regex metacharacters (`.`, `+`, `*`, `(`, etc.), `gsub` matches unintended patterns. | **Medium** — wrong file paths |
| T11 | **Symlink following** | Environment | `fs::dir_ls()` and `fs::file_copy()` may follow symlinks, causing operations outside intended directories. | **Medium** — unintended scope |
| T12 | **Backup to same directory** | User error | User sets `backup_dir` to the same path as `right_path`. Backup corrupts the directory being synced. | **High** — data corruption |
| T13 | **Backup to tempdir lost** | Default behavior | Default `backup_dir = "temp_dir"` → `tempdir()`. Backups lost on session end. User may believe backup is persistent. | **Medium** — false confidence |
| T14 | **`force = TRUE` default** | API design | All sync functions default to `force = TRUE`, skipping the preview/confirmation step. Novice users may trigger destructive operations unknowingly. | **High** — accidental destruction |
| T15 | **Overwrite hardcoded** | API design | `copy_files_to_right/left()` always pass `overwrite = TRUE` to `fs::file_copy()`. No option to prevent overwriting. | **Medium** — silent data loss |

### 2.2 Attack surface summary

```
User Input → [path validation] → [compare_directories] → [sync_status object] → [sync function] → [file operations]
     ↑              ↑                      ↑                       ↑                     ↑
   T1-T4          T4,T10               T6,T7,T11                T14,T15           T5,T8,T9,T12
```

---

## 3. Vulnerability Categories

### V1: Destructive Operations — Unintended Deletes and Overwrites

**Functions affected:**
- `full_asym_sync_to_right()` — lines using `fs::file_delete()`
- `update_missing_files_asym_to_right()` — lines using `fs::file_delete()`
- `copy_files_to_right()` / `copy_files_to_left()` — `fs::file_copy(overwrite = TRUE)`

**Specific findings to audit:**
1. `delete_in_right = TRUE` is the default. Combined with `force = TRUE` (also default), deletion proceeds without any user confirmation.
2. `overwrite = TRUE` is hardcoded in both copy functions — not exposed as a parameter.
3. No maximum deletion threshold (e.g., "abort if > N files would be deleted").
4. No dry-run mode that logs what *would* happen without executing.
5. `exclude_delete` only exists in `update_missing_files_asym_to_right()` — not in `full_asym_sync_to_right()`.

### V2: Race Conditions

**Functions affected:** All sync functions that accept `sync_status` objects.

**Specific findings to audit:**
1. Gap between `compare_directories()` and sync execution — no freshness check.
2. No file locking mechanism during sync operations.
3. The `lapply()` loop in copy/delete operations is sequential but not atomic — interruption leaves partial state.
4. No checksumming at copy-time to verify the source file hasn't changed since comparison.

### V3: Input Validation Gaps

**Functions affected:** All exported functions.

**Specific findings to audit:**
1. No check for `left_path == right_path` (self-sync).
2. No check for nested paths (`left_path` is parent/child of `right_path`).
3. No check for `NA`, empty string `""`, or whitespace-only paths.
4. No type checking on `by_date`, `by_content`, `recurse` (except when `NA` causes downstream errors).
5. `gsub()` used for path manipulation instead of `fs::path_rel()` — vulnerable to regex metacharacters.
6. `backup_dir` is not validated against `left_path` or `right_path`.
7. `save_sync_status()` does not validate `dir_path` exists before proceeding.
8. `files_to_copy` data frame structure is never validated in `copy_files_to_right/left()`.

### V4: Permission Handling and Partial Operations

**Functions affected:** All sync and copy functions.

**Specific findings to audit:**
1. No pre-flight permission check on source (read) or destination (write) directories.
2. No `tryCatch()` around individual file operations — one failure aborts the entire `lapply()` loop.
3. No rollback mechanism if copy/delete partially completes.
4. No summary of what succeeded vs. failed when an error occurs mid-operation.
5. Backup uses `file.copy()` without checking return value (returns `TRUE`/`FALSE`, not error).

### V5: Path Handling and Injection

**Functions affected:** `copy_files_to_right()`, `copy_files_to_left()`, `directory_info()`, `display_file_actions()`, `print.syncdr_status()`.

**Specific findings to audit:**
1. `gsub(left_dir, "", path_left)` treats `left_dir` as a regex pattern. Paths containing `.`, `+`, `*`, `(`, `)`, `[`, `]`, `{`, `}`, `^`, `$`, `|`, `\\` will produce incorrect relative paths.
2. `fs::path()` is used for path construction in some places, but `paste0()` and string concatenation in others — inconsistent.
3. No path normalization before comparison (e.g., trailing slashes, `..` components).

### V6: Backup Reliability

**Functions affected:** All sync functions with `backup` parameter.

**Specific findings to audit:**
1. Default `backup_dir = "temp_dir"` resolves to `tempdir()` — ephemeral, lost on session restart.
2. `file.copy(from = right_path, to = backup_dir, recursive = TRUE)` copies the directory *into* backup_dir as a subdirectory — naming depends on OS and path structure.
3. No verification that backup completed successfully before proceeding with destructive operations.
4. `full_symmetric_sync()` has inconsistent backup logic: when `backup_dir != "temp_dir"`, both `backup_right` and `backup_left` resolve to the same user-provided path.
5. `partial_symmetric_sync_common_files()` uses `list.files()` + `file.copy()` (different backup strategy from other functions), potentially missing nested directory structure.

---

## Implementation Steps

### 1. Audit: File-System Operations Inventory Verification

- **Files**: All files in `R/`
- **Details**:
  - Grep for `fs::file_copy`, `fs::file_delete`, `fs::dir_create`, `fs::dir_ls`, `file.copy`, `file.create`, `dir.create`, `saveRDS`, `fwrite`, `write_fst`, `unlink` across all source files.
  - Cross-reference with the inventory in Section 1 above.
  - Verify no file-system operations are missing from the inventory.
- **Tests**: Manual grep verification — no code changes.
- **Acceptance criteria**: Complete inventory with zero unaccounted file-system calls.

### 2. Audit: Input Validation Gap Analysis

- **Files**: All exported functions in `R/asymmetric_sync.R`, `R/symmetric_sync.R`, `R/compare_directories.R`, `R/auxiliary_functions.R`, `R/action_functions.R`
- **Details**:
  - For each exported function, document:
    1. Every parameter and its expected type/constraints
    2. What validation currently exists (if any)
    3. What validation is missing
  - Focus areas:
    - Path parameters: existence, type, non-NA, non-empty, non-nested, non-identical
    - Logical parameters: type, non-NA
    - Data frame parameters: expected columns, non-empty
  - Catalog every `gsub()` call used for path manipulation and assess regex injection risk.
- **Tests**: Manual code review — no code changes.
- **Acceptance criteria**: Complete validation gap matrix for every exported function parameter.

### 3. Audit: Destructive Operation Safety Analysis

- **Files**: `R/asymmetric_sync.R`, `R/action_functions.R`
- **Details**:
  - Trace every code path that leads to `fs::file_delete()` or `fs::file_copy(overwrite = TRUE)`.
  - For each path, document:
    1. What user-facing safeguards exist (confirmation prompt, flags, preview)
    2. What defaults are in effect (`force`, `delete_in_right`, `overwrite`)
    3. Whether backup occurs *before* destructive operations
    4. Whether the operation is atomic or can leave partial state
  - Specific code paths to trace:
    - `full_asym_sync_to_right()` → delete loop
    - `full_asym_sync_to_right()` → copy loop (via `copy_files_to_right()`)
    - `update_missing_files_asym_to_right()` → delete loop with `exclude_delete`
    - `copy_files_to_right()` → `fs::file_copy(overwrite = TRUE)`
- **Tests**: Manual trace — no code changes.
- **Acceptance criteria**: Complete decision tree for every destructive code path, documenting safeguards and gaps.

### 4. Audit: Race Condition Analysis

- **Files**: All sync functions, `R/compare_directories.R`
- **Details**:
  - Document the time gap between `compare_directories()` output and sync execution.
  - Assess whether `sync_status` objects carry a timestamp or freshness indicator.
  - Identify scenarios where stale `sync_status` leads to incorrect operations.
  - Analyze the sequential `lapply()` loops for interruptibility and partial-completion risk.
- **Tests**: Manual analysis — no code changes.
- **Acceptance criteria**: Documented race condition scenarios with severity ratings and triggering conditions.

### 5. Audit: Permission and Error Handling Analysis

- **Files**: All sync functions, `R/action_functions.R`
- **Details**:
  - Identify every file-system call and assess:
    1. Whether it is wrapped in error handling (`tryCatch`, `try`, `withCallingHandlers`)
    2. What happens to previously-completed operations if it fails
    3. Whether the user receives a meaningful error message
  - Check `file.copy()` return value usage (returns logical, not error).
  - Check `fs::file_delete()` behavior on non-existent or locked files.
- **Tests**: Manual analysis — no code changes.
- **Acceptance criteria**: Error handling coverage matrix for every file-system call.

### 6. Audit: Backup Mechanism Analysis

- **Files**: All sync functions with `backup` parameter
- **Details**:
  - Compare backup implementation across all 6 sync functions for consistency.
  - Document:
    1. When backup occurs relative to destructive operations
    2. Whether backup success is verified before proceeding
    3. Whether backup is complete (captures full directory structure)
    4. `full_symmetric_sync()` bug: both `backup_right` and `backup_left` resolve to same path when custom `backup_dir` provided.
    5. `partial_symmetric_sync_common_files()` different backup strategy (flat file copy vs. recursive dir copy).
- **Tests**: Manual analysis — no code changes.
- **Acceptance criteria**: Backup consistency report with identified discrepancies.

### 7. Audit: Path Handling Analysis

- **Files**: `R/action_functions.R`, `R/auxiliary_functions.R`, `R/print.R`, `R/display_functions.R`
- **Details**:
  - Catalog every `gsub()` used for path manipulation.
  - Test mentally (or document) what happens with paths containing regex metacharacters: `C:/Users/user.name/project+data/dir(1)/`.
  - Compare with `fs::path_rel()` which handles this correctly.
  - Check for path normalization (trailing slashes, `.` and `..` components, mixed separators).
- **Tests**: Manual analysis — no code changes.
- **Acceptance criteria**: Complete list of `gsub()` path operations with assessed risk and recommended alternatives.

---

## Testing Strategy

This section defines the tests that WOULD be written to validate safety. These are recommendations — not to be implemented as part of this audit.

### Safety Test Categories

#### ST1: Self-sync protection
- Pass identical paths as `left_path` and `right_path` to every sync function.
- Expected: informative error before any file operations.

#### ST2: Nested directory protection
- Pass `left_path = "/a"` and `right_path = "/a/b"` (and reversed).
- Expected: informative error before any file operations.

#### ST3: Invalid path handling
- Pass `NA`, `""`, `NULL`, `123`, `c("a","b")` as path arguments.
- Expected: type-appropriate error messages.

#### ST4: Large-scale deletion safeguard
- Create a scenario where >100 files would be deleted.
- Verify that `force = FALSE` shows preview with count.
- Verify that `force = TRUE` still proceeds (current behavior) — document as known risk.

#### ST5: Path with regex metacharacters
- Create directories with names containing `.`, `+`, `(`, `)`, `[`, `]`.
- Run `compare_directories()` and all sync functions.
- Verify correct file matching and path computation.

#### ST6: Partial failure resilience
- Mock `fs::file_copy()` to fail on the Nth file.
- Verify error message includes what succeeded and what failed.
- Verify the directory is in a documented (if not clean) state.

#### ST7: Permission denial
- Create read-only destination directory.
- Run sync functions and verify informative error.

#### ST8: Backup verification
- Run sync with `backup = TRUE` and verify backup directory contains exact copy.
- Verify backup completes *before* any destructive operation begins.
- Test `full_symmetric_sync()` with custom `backup_dir` — verify both dirs backed up to different locations.

#### ST9: Stale sync_status
- Create `sync_status`, modify directories, then pass stale `sync_status` to sync.
- Document actual behavior (this is an awareness test, not a pass/fail).

#### ST10: Force = FALSE confirmation flow
- Mock `askYesNo()` to return `TRUE`, `FALSE`, `NA`.
- Verify no file operations occur when `FALSE` or `NA`.
- Verify correct operations when `TRUE`.

#### ST11: Symlink behavior
- Create symlinks in source/destination directories.
- Document whether `fs::dir_ls()` follows symlinks and whether sync operates outside intended scope.

#### ST12: Concurrent access simulation
- From two R sessions, run `compare_directories()` then sync on overlapping directories.
- Document observed behavior.

---

## Documentation Checklist

- [ ] Vulnerability inventory document (this plan, Section 1)
- [ ] Threat model (this plan, Section 2)
- [ ] Vulnerability categories (this plan, Section 3)
- [ ] Input validation gap matrix
- [ ] Destructive operation decision trees
- [ ] Race condition scenarios
- [ ] Permission/error handling coverage matrix
- [ ] Backup consistency report
- [ ] Path handling risk assessment
- [ ] Recommended safety test suite specification (this plan, Testing Strategy)

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Audit may miss file-system calls in dependencies (e.g., `joyn` writing temp files) | Include dependency analysis in Step 1 |
| Some vulnerability categories may overlap (e.g., race conditions + partial failure) | Cross-reference findings across categories |
| Platform-specific behavior (Windows vs. Unix path separators, symlinks, permissions) | Note platform-specific behavior but focus on cross-platform concerns |
| Audit scope creep into implementation | Strictly enforce "document only" — all findings are recommendations |

## Out of Scope

- **Implementing fixes** — this plan is for auditing and documenting vulnerabilities only.
- **Performance optimization** — not a security concern.
- **Network-based synchronization** — syncdr operates on local/mounted file systems only.
- **Dependency vulnerability scanning** — CVE scanning of `fs`, `digest`, etc. is a separate task.
- **Code style or refactoring** — unless directly tied to a security vulnerability.

---

## Verification Checklist

To ensure full coverage, the auditor should verify:

- [ ] Every exported function in NAMESPACE has been analyzed for input validation
- [ ] Every `fs::file_copy`, `fs::file_delete`, `fs::dir_create`, `file.copy`, `dir.create`, `saveRDS`, `fwrite`, `write_fst` call is accounted for
- [ ] Every `gsub()` used for path manipulation is cataloged
- [ ] Every function with `backup` parameter has consistent backup logic
- [ ] Every function with `force` parameter has correct confirmation flow
- [ ] Every `lapply()` loop over file operations has been assessed for partial-failure behavior
- [ ] The threat model covers: user error, concurrent access, I/O failure, environment issues
- [ ] All 6 vulnerability categories (V1–V6) have at least one specific code-level finding
- [ ] All 12 safety test categories (ST1–ST12) reference specific functions and expected behavior
- [ ] Cross-platform path handling (Windows `\` vs. Unix `/`) is noted where relevant
