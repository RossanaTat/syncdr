---
date: 2026-04-06
title: "Test isolation: top-level setup code outside test_that() is a P1 anti-pattern"
category: "testing-patterns"
language: "R"
tags: [testthat, test-isolation, setup, fixture, temp-dirs, test-pollution]
root-cause: "Setup code and sync operations placed at file parse-time outside test_that() blocks, making all tests in the file share mutable state and preventing individual test execution."
severity: "P1"
---

# Test isolation: top-level setup code outside `test_that()` is a P1 anti-pattern

## Problem

In `test-asym_sync.R` and `test-symm_sync.R`, substantial setup code runs at file
parse time (outside any `test_that()` block):

```r
# At top level — runs when the file is sourced:
e <- toy_dirs()
syncdr_temp <- copy_temp_environment()
left  <- syncdr_temp$left
right <- syncdr_temp$right
sync_status_date <- compare_directories(left_path = left, right_path = right)
full_asym_sync_to_right(sync_status = sync_status_date, force = TRUE, delete_in_right = TRUE)

# Later test_that blocks reference `left`, `right`, `sync_status_date` from outer scope:
test_that("full asym sync to right -by date, non common files", {
  new_status <- compare_directories(left, right)   # uses outer-scope `left`/`right`
  expect_true(nrow(new_status$non_common_files) == 0)
})
```

Symptoms:
- A single failure in top-level setup silently breaks **all** subsequent `test_that` blocks in the file (they error with "object not found", not a clear test failure).
- Tests cannot be run individually via `devtools::test(filter = "...")` — the top-level sync runs first regardless.
- Each `test_that` block reads from state mutated by the *previous* block's operations, not a known clean state. Test order matters, which testthat explicitly warns against.
- Adding a new test in the middle of the file changes all tests that come after it.

## Root Cause

The test files were written in a "script" style — sequential setup and assertions across the whole file — rather than using testthat's self-contained `test_that()` model. This works for a simple single-pass read but breaks as soon as tests need to be run selectively or in different contexts (e.g., parallel test runners, `test_file()` calls).

## Solution

Every `test_that()` block must own its fixture. Each block calls `copy_temp_environment()` internally:

```r
# CORRECT: each block is self-contained
test_that("full asym sync to right -by date, non common files", {
  syncdr_temp <- copy_temp_environment()
  left  <- syncdr_temp$left
  right <- syncdr_temp$right

  sync_status <- compare_directories(left_path = left, right_path = right)
  full_asym_sync_to_right(sync_status = sync_status, force = TRUE, delete_in_right = TRUE)

  new_status <- compare_directories(left, right)
  expect_true(nrow(new_status$non_common_files) == 0)
  # ... more assertions
})
```

For groups of tests that truly share expensive setup, use `local()`:

```r
local({
  syncdr_temp <- copy_temp_environment()
  left  <- syncdr_temp$left
  right <- syncdr_temp$right
  sync_status <- compare_directories(left, right)

  test_that("assertion 1", {
    # uses left, right, sync_status from local() scope
  })

  test_that("assertion 2", {
    # same scope — but note: mutation in test 1 is still visible here
  })
})
```

Use `withr::local_tempdir()` (not `tempfile()`) for any temporary directories so cleanup is automatic:

```r
test_that("backup creates files", {
  backup_dir <- withr::local_tempdir()    # auto-cleaned on test exit
  full_asym_sync_to_right(
    left_path  = e$left,
    right_path = e$right,
    backup     = TRUE,
    backup_dir = backup_dir,
    force      = TRUE
  )
  expect_true(length(fs::dir_ls(backup_dir, recurse = TRUE)) > 0)
})
```

## Prevention

**Rule:** No production code may execute outside a `test_that()` block in a test file.
Permitted at top level:
- `library()` / `testthat::local_package()` calls
- `source()` for shared helpers
- Pure constant definitions (`THRESHOLD <- 3600L`)

Not permitted at top level:
- `toy_dirs()`, `copy_temp_environment()`, `compare_directories()` calls
- Any sync function call
- Any `file.create()`, `writeLines()`, filesystem mutations

**Linting:** Add `lintr::object_usage_linter()` and consider a custom `lintr` rule that flags `test_that` blocks referencing variables defined outside the block.

## Related

- `2026-04-06-security-audit-steps-5-6-7.md` — Group F test fixes (required adding `force = TRUE` to all top-level sync calls, which is the same symptom: tests depend on outer-scope setup)
- testthat documentation: https://testthat.r-lib.org/reference/test_that.html
- `withr` for auto-cleanup: https://withr.r-lib.org/
