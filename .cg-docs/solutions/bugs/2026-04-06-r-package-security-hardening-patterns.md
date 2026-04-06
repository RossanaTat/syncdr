---
date: 2026-04-06
title: "R package security audit: 9 recurring hardening patterns for file-operation packages"
category: "bugs"
language: "R"
tags: [security, api-design, isTRUE, safe-defaults, overwrite, cli-abort, roxygen, force-param, switch-case, option-defaults]
root-cause: "Multiple interacting issues across API design, defensive coding style, and documentation found during a full security audit of syncdr v0.1.1."
severity: "P1"
---

# R package security audit: 9 recurring hardening patterns for file-operation packages

## Problem

A security audit of `syncdr` (a file-synchronization R package) surfaced 35 classified
vulnerabilities across Groups A–F. The `/cg-review` pass then found 9 additional
cross-cutting patterns that recur across multiple files and functions. These patterns
are generalizable to any R package that performs file operations.

## Root Cause

These issues accumulated during iterative development without a systematic hardening
checklist. Most are non-obvious: each item is individually small, but together they
create an API that can silently corrupt data or mislead users.

## Solution

### Pattern 1 — `isTRUE()` / `isFALSE()` everywhere, not `== TRUE` / `== FALSE`

**Problem:** `if (recurse == TRUE)` errors when `recurse = NA`; `if (isTRUE(recurse))`
safely returns `FALSE`. A function using both styles in the same file is inconsistent
and the safer form is required for exported parameters.

```r
# BAD — errors on NA, misleading on non-logical input
if (recurse == TRUE) { ... }

# GOOD
if (isTRUE(recurse)) { ... }

# BAD — uses | (vectorised) for a scalar boolean
if (Ask == FALSE | is.na(Ask)) { ... }

# GOOD — short-circuit scalar
if (isFALSE(Ask) || is.na(Ask)) { ... }
```

**Rule:** All boolean parameter guards in exported functions must use `isTRUE()`/`isFALSE()`.

---

### Pattern 2 — Safe defaults for destructive operations

**Problem:** Functions that delete files had `force = TRUE` and `delete_in_right = TRUE`
as defaults — opt-out destruction. A new user calling `full_asym_sync_to_right()` with
defaults would silently delete right-only files.

```r
# BAD — destruction by default
full_asym_sync_to_right <- function(..., force = TRUE, delete_in_right = TRUE)

# GOOD — safe defaults; user must explicitly opt in to destruction
full_asym_sync_to_right <- function(..., force = FALSE, delete_in_right = FALSE)
```

**Rule:** Any parameter that controls a destructive or irreversible operation must default
to `FALSE`. The preview mode (`force = FALSE`) must be the default.

---

### Pattern 3 — `switch()` keys must match exactly — case counts

**Problem:** `save_sync_status()` produced `"Rds"` (capital R) as the fallback format
string, but the `switch()` arm was keyed on `"rds"` (lowercase). `switch("Rds", "rds" = saveRDS(...))` silently returns `NULL` — the file was never saved.

```r
# BAD — case mismatch: "Rds" never matches arm "rds"
format <- ifelse(condition, "fst", "Rds")
switch(format, "rds" = saveRDS(...))      # silently skipped

# GOOD — consistent casing
format <- ifelse(condition, "fst", "rds")
switch(format, "rds" = saveRDS(...))
```

Also: never assign the return value of a side-effectful `switch()` to a variable that
is never used — it looks like a deferred call that was forgotten:

```r
# BAD — dead variable, confusing
save_fun <- switch(format, "rds" = saveRDS(...))

# GOOD — no assignment needed when the arms are side effects
switch(format, "rds" = saveRDS(...))
```

---

### Pattern 4 — Package options must be registered in `.onLoad`

**Problem:** `check_sync_status_staleness()` correctly uses
`getOption("syncdr.staleness_threshold_secs", 3600L)` with a fallback. But the option
was not registered in `zzz.R`, so `options()` output never showed it and users had no
way to discover it without reading source code.

```r
# In R/zzz.R — register ALL package options at load time
.onLoad <- function(libname, pkgname) {
  op <- options()
  op.syncdr <- list(
    syncdr.verbose                  = FALSE,
    syncdr.save_format              = "rds",      # lowercase — must match switch() arms
    syncdr.staleness_threshold_secs = 3600L       # was missing
  )
  toset <- !(names(op.syncdr) %in% names(op))
  if (any(toset)) options(op.syncdr[toset])
  invisible(NULL)                                  # invisible(NULL), not invisible()
}
```

**Rule:** Every `getOption("pkg.name")` call in the package must have a corresponding
entry in the `op.pkg` list in `.onLoad`. The value in `.onLoad` becomes the documented
default.

---

### Pattern 5 — Variable shadowing `base::format()`

**Problem:** In `save_sync_status()`:
```r
format <- getOption("syncdr.save_format")     # shadows base::format()
...
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")  # calls base::format() — works TODAY
                                                   # but one line reorder → "rds"(...) error
```

**Rule:** Never name a local variable after a base R function used later in the same
scope. Use a suffix like `save_fmt` or `fmt`.

---

### Pattern 6 — Consistent error signaling: `cli::cli_abort()` everywhere

**Problem:** `filter_common_files()`, `filter_non_common_files()`, and
`search_duplicates()` used `stopifnot()` while all exported functions used `cli::cli_abort()`.
`stopifnot()` produces raw expression dumps; `cli_abort()` produces structured,
actionable messages. Internal functions called from exported code can surface errors to
users — they need the same quality error messages.

```r
# BAD — user sees: "Error: fs::dir_exists(dir_path) is not TRUE"
stopifnot(exprs = { fs::dir_exists(dir_path) })

# GOOD — user sees: "✖ `dir_path` does not exist or is not a directory. ℹ Path: ..."
validate_path_arg(dir_path, "dir_path")
# or directly:
if (!dir %in% c("left", "right", "all")) {
  cli::cli_abort(c(
    '{.arg dir} must be one of "left", "right", or "all".',
    "x" = 'Got: {.val {dir}}'
  ))
}
```

**Rule:** All argument validation in the package must use `cli::cli_abort()`. No
`stopifnot()` in any function reachable from exported code.

---

### Pattern 7 — `@param overwrite FALSE` behavior must match actual `fs::file_copy` behavior

**Problem:** Documentation said `overwrite = FALSE` "silently preserves" existing files.
Reality: `fs::file_copy(overwrite = FALSE)` **throws an error** on existing files. A
`tryCatch` wrapper converts this to a `cli_warn()` — so users see a warning stream for
every existing file, not silence.

```r
# BAD — says "preserved and skipped" implying silence
#' @param overwrite If FALSE, existing destination files are preserved and the copy is skipped.

# GOOD — describes the actual warning behavior
#' @param overwrite Logical, default is TRUE. If TRUE, existing files at the
#'   destination are overwritten. If FALSE, any attempt to copy a file that
#'   already exists at the destination triggers a per-file warning and that
#'   file is skipped; copying continues for all remaining files.
```

**Rule:** When `fs::file_copy(overwrite = FALSE)` is used inside a `tryCatch`, always
document that failures produce *warnings*, not silence.

---

### Pattern 8 — Backup ordering: after confirmation, not before

**Problem:** Five of six sync functions ran backup *before* the force-confirmation
prompt. If the user declined, an orphaned backup directory was left behind with no
corresponding sync. `partial_update_missing_files_asym_to_right()` accidentally had the
correct order (backup after confirmation).

```r
# BAD — backup before ask: orphan backup on cancel
if (backup) { perform_backup(...) }
if (isFALSE(force)) {
  Ask <- askYesNo(...)
  if (isFALSE(Ask) || is.na(Ask)) cli::cli_abort("Synchronization interrupted")
}

# GOOD — ask first, only backup if proceeding
if (isFALSE(force)) {
  Ask <- askYesNo(...)
  if (isFALSE(Ask) || is.na(Ask)) cli::cli_abort("Synchronization interrupted")
}
if (backup) { perform_backup(...) }
```

**Rule:** In any function with both a confirmation prompt and a destructive operation:
confirmation always comes first. Use `partial_update_missing_files_asym_to_right` as
the reference implementation.

---

### Pattern 9 — Duplicate copy workers invite divergence

**Problem:** `copy_files_to_right()` and `copy_files_to_left()` are ~120 lines each
of near-identical code. The only difference is which path column is source vs. destination.
When CODE-P1-01 was introduced (bare `==` in `copy_files_to_right`), `copy_files_to_left`
had already been fixed to use `isTRUE()`. The duplication caused them to diverge silently.

```r
# BAD — two copies of the same logic
copy_files_to_right <- function(left_dir, right_dir, files_to_copy, recurse, overwrite) {
  if (recurse == TRUE) { ... }  # BUG introduced here
  ...
}
copy_files_to_left  <- function(left_dir, right_dir, files_to_copy, recurse, overwrite) {
  if (isTRUE(recurse)) { ... }  # was correctly fixed
  ...
}

# GOOD — shared internal worker
.copy_files_impl <- function(src_dir, dest_dir, files_to_copy, src_col, dest_col,
                              recurse = TRUE, overwrite = TRUE) {
  if (isTRUE(recurse)) {
    files_to_copy <- files_to_copy |>
      ftransform(path_from = .data[[src_col]],
                 path_to   = fs::path(dest_dir, fs::path_rel(.data[[src_col]], start = src_dir)))
  } else {
    files_to_copy <- files_to_copy |>
      ftransform(path_from = .data[[src_col]], path_to = dest_dir)
  }
  # ... single copy loop with tryCatch
}

copy_files_to_right <- function(left_dir, right_dir, files_to_copy, recurse = TRUE, overwrite = TRUE) {
  .copy_files_impl(left_dir, right_dir, files_to_copy, "path_left", "path_right", recurse, overwrite)
}
copy_files_to_left  <- function(left_dir, right_dir, files_to_copy, recurse = TRUE, overwrite = TRUE) {
  .copy_files_impl(right_dir, left_dir, files_to_copy, "path_right", "path_left", recurse, overwrite)
}
```

**Rule:** Any two functions that differ only in argument names / column names must share
a private implementation helper. DRY violations in file-operation code are high-risk
because bugs introduced on one side will not be caught until the other diverges visibly.

## Prevention

**Checklist for any new or modified sync/copy function in syncdr:**

- [ ] All boolean parameter guards use `isTRUE()`/`isFALSE()` — no bare `== TRUE`, no `|` for scalar booleans
- [ ] Destructive-operation parameters (`force`, `delete_*`, `overwrite`) default to `FALSE`
- [ ] `switch()` keys and the strings that feed them use identical casing
- [ ] All package options are registered in `.onLoad` in `zzz.R`
- [ ] No local variable shadows a `base::` function used later in the same scope
- [ ] All argument validation uses `cli::cli_abort()` — no `stopifnot()`
- [ ] `@param` docs for `overwrite = FALSE` describe the warning behavior, not silent skip
- [ ] Backup runs after force-confirmation prompt, not before
- [ ] No copy-paste of large function bodies — extract a shared `_impl()` helper

## Related

- `2026-04-06-vulnerability-report.md` — full VUL-01 through VUL-35 audit findings
- `2026-04-06-security-audit-steps-1-2.md` — Group A/B fix implementation
- `2026-04-06-security-audit-steps-3-4.md` — Group C/D fix implementation
- `2026-04-06-security-audit-steps-5-6-7.md` — Group E/F fix implementation + test suite
- `2026-04-06-test-isolation-top-level-setup-anti-pattern.md` — test pollution pattern (testing-patterns)
- `../.cg-docs/reviews/2026-04-06-security-branch-review.md` — full 8-agent standard review report
