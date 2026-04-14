---
date: 2026-04-06
title: "syncdr — Performance Review"
category: performance-issues
status: final
reviewer: "@cg-performance"
scope: "DEV branch — R/action_functions.R, R/auxiliary_functions.R, R/compare_directories.R, R/utils.R"
---

# syncdr — Performance Review

**Package:** syncdr v0.1.1  
**Branch:** DEV  
**Review date:** 2026-04-06  
**Scope:** `R/action_functions.R`, `R/auxiliary_functions.R`, `R/compare_directories.R`, `R/utils.R`

Performance is evaluated in the context of a file-synchronization package where
network and disk I/O dominate CPU cost for almost all realistic workloads. CPU
findings are rated higher only when they introduce algorithmic complexity that
grows super-linearly, or when they duplicate work that disk latency already
makes expensive.

---

## Summary

| ID | Priority | Area | Impact |
|---|---|---|---|
| PERF-01 | P2 | `failures` vector O(n²) growth in copy loops | High for mass-failure scenarios |
| PERF-02 | P3 | Sequential hashing in `hash_files()` | Medium for large directories on multi-core |
| PERF-03 | P3 | Dual hash libraries doing the same job | Low / maintenance |
| PERF-04 | P3 | `tryCatch` overhead per file copy | Negligible in practice |

No P1 findings. No finding blocks the current release; PERF-01 is the only
issue that can produce meaningfully degraded behaviour for real workloads.

---

## PERF-01 — O(n²) failure-vector growth in `copy_files_to_right` / `copy_files_to_left`

| Field | Detail |
|---|---|
| **Priority** | P2 |
| **Files** | `R/action_functions.R` |
| **Affected functions** | `copy_files_to_right()`, `copy_files_to_left()` |

**Description.** Both functions accumulate copy failures using superassignment
into a character vector that grows with `c()`:

```r
failures <- character(0)

# inside lapply error handler:
failures <<- c(failures, files_to_copy$path_from[i])
```

`c(failures, new_item)` allocates a **new vector of length n+1 on every
failure**, copying all existing elements. For *f* failures this allocates
*f* vectors of total size 1 + 2 + … + f = f(f+1)/2 — O(f²) in both
allocations and copies.

Under normal operation (zero or near-zero failures) this is immaterial. But
in scenarios where failures are common — a read-only filesystem, a locked
network share, a permission boundary affecting thousands of files — the
failure-collection code becomes quadratic at exactly the moment the user is
already experiencing a degraded operation.

**Concrete example.** 10,000 files, all failing (e.g., source drive
disconnected mid-sync): the loop allocates ~50 million character cells across
10,000 growing vectors. On a machine with a slow allocator this is measurable
wall time on top of the (already fast, because no I/O) error-path work.

**Recommended fix.** Pre-allocate at the file count and track with an index,
or collect indices and subset at the end:

```r
# Option A: collect integer indices (cheapest)
failure_idx <- integer(0)

# inside error handler:
failure_idx <<- c(failure_idx, i)   # integers are small; still O(n²) but 8x cheaper

# after loop:
failures <- files_to_copy$path_from[failure_idx]
```

```r
# Option B: pre-allocate logical mask (O(1) per failure, O(n) total)
failed <- logical(nrow(files_to_copy))

# inside error handler:
failed[[i]] <<- TRUE

# after loop:
failures <- files_to_copy$path_from[failed]
```

Option B is strictly O(n) — constant cost per failure, single subset at the
end — and is the recommended approach. The pre-allocated `logical` vector has
the same length as `files_to_copy` regardless of the failure rate, so memory
use is predictable.

**Note on `<<-` scope.** The superassignment pattern itself is acceptable for
this closure structure (`lapply` over an index, writing back into the enclosing
function frame). The issue is not the `<<-` but the data structure it writes
into. Option B retains `<<-` and eliminates the quadratic growth.

**Also note:** this is a DRY violation in the performance dimension — the same
O(n²) pattern is duplicated in both `copy_files_to_right` and
`copy_files_to_left`. Fixing it should be done once in the shared helper
recommended in ARC-01 of the architecture review.

---

## PERF-02 — Sequential hashing bottleneck in `hash_files()` and `hash_files_in_dir()`

| Field | Detail |
|---|---|
| **Priority** | P3 |
| **Files** | `R/auxiliary_functions.R` |
| **Affected functions** | `hash_files()`, `hash_files_in_dir()` |

**Description.** Both functions hash files sequentially with `lapply`:

```r
# hash_files()
hashes <- lapply(files_path, function(path) {
  secretbase::siphash13(file = path)
})

# hash_files_in_dir()
files_df$hash <- lapply(files_df$path, function(p) {
  digest::digest(p, algo = "xxhash32", file = TRUE)
})
```

For a directory of 10,000 files on a local SSD, hashing is likely
I/O-bound and sequential throughput saturates the disk; parallelisation would
not help. For a directory on a network share or a RAID array with high queue
depth, parallel reads can significantly improve throughput because the storage
controller can service multiple requests concurrently.

This is rated P3 because:

1. The primary use case (local SSD) gains nothing from parallelisation.
2. Adding `parallel::mclapply` or `future.apply::future_lapply` introduces
   a new dependency and complicates the user-facing interface.
3. The disk read is the bottleneck, not the SipHash-1-3 computation (which
   is extremely fast — benchmarks typically show >2 GB/s).

**Recommended approach (if pursued).** Add a `workers` argument defaulting
to `1L` (sequential) with a note that values >1 use `parallel::mclapply`.
Do not enable parallelism by default — it changes behaviour on Windows
(no fork) and in interactive sessions. Evaluate only if profiling real
workloads on network shares shows hashing is the bottleneck.

**Pre-existing issue.** This pattern pre-dates the DEV branch; it is noted
here for completeness and future roadmap awareness.

---

## PERF-03 — Two hash libraries for the same purpose

| Field | Detail |
|---|---|
| **Priority** | P3 |
| **Files** | `R/auxiliary_functions.R` |
| **Affected functions** | `hash_files()` (uses `secretbase::siphash13`), `hash_files_in_dir()` (uses `digest::digest(..., algo = "xxhash32")`) |

**Description.** The package uses two different libraries — and two different
hash algorithms — to hash files:

| Function | Library | Algorithm |
|---|---|---|
| `hash_files()` | `secretbase` | SipHash-1-3 |
| `hash_files_in_dir()` | `digest` | xxHash-32 |

`hash_files()` is used by `compare_file_contents()` for cross-directory
comparison. `hash_files_in_dir()` is used by `save_sync_status()` and
`search_duplicates()` for within-directory deduplication and snapshotting.

Problems:

1. **Two `Imports` entries** (`secretbase`, `digest`) for a function that a
   single library can provide. `digest` supports many algorithms including
   `siphash` variants; `secretbase` is a newer, leaner package focused on
   SipHash.
2. **xxHash-32 has a larger collision space issue than SipHash-1-3 for file
   comparison** — xxHash-32 produces 32-bit digests (4 billion possible
   values). For directories with tens of thousands of files, the birthday
   collision probability for a 32-bit hash is non-trivial (~1% at ~9,000
   files). A false "same" conclusion on `save_sync_status` would silently
   mark changed files as unchanged. `siphash13` produces 64-bit digests —
   collision probability is negligible.
3. **Hashes from the two functions are incompatible** — they cannot be
   compared across the two use sites, making future unification of the
   snapshot and comparison paths harder.

**Recommended fix.** Consolidate on `secretbase::siphash13` (already
imported) in both functions. Drop the `digest` import. Update
`hash_files_in_dir()`:

```r
hash_files_in_dir <- function(dir_path) {
  dir_files <- fs::dir_ls(dir_path, type = "file", recurse = TRUE)
  data.frame(
    path = as.character(dir_files),
    hash = vapply(dir_files, function(p) secretbase::siphash13(file = p),
                  character(1L))
  )
}
```

This also removes the `lapply` → `data.frame` → list-column pattern
(`files_df$hash` is a list, not a character vector) and replaces it with
`vapply` which returns a character vector directly — cleaner and slightly
faster.

---

## PERF-04 — Per-file `tryCatch` overhead in copy loops

| Field | Detail |
|---|---|
| **Priority** | P3 |
| **Files** | `R/action_functions.R` |
| **Affected functions** | `copy_files_to_right()`, `copy_files_to_left()` |

**Description.** Each file copy is wrapped in `tryCatch`:

```r
lapply(cli::cli_progress_along(...), function(i) {
  tryCatch(
    fs::file_copy(...),
    error = function(e) { ... }
  )
})
```

`tryCatch` in R establishes a restart/handler frame on every call — roughly
equivalent to pushing and popping a condition handler. For N files this is N
`tryCatch` setups and teardowns. CPython shows similar patterns with
try/except in tight loops.

**Why this is P3 and not P2.** The `fs::file_copy()` call hits the OS
filesystem layer — a syscall with context switches. Even a single
`file_copy()` for a 1 KB file involves open, stat, read, write, fsync (on
some systems), close — dozens of µs at minimum on a local SSD, hundreds of
ms on a network share. A `tryCatch` frame setup costs ~1–5 µs. The disk I/O
overhead is 10–1000× the `tryCatch` overhead; the per-file `tryCatch` cost
is lost in the noise.

**Conclusion.** The `tryCatch`-per-file pattern is correct for the security
requirement (VUL-24/26 — do not abort the entire sync on a single failure)
and the performance cost is negligible relative to disk I/O. No change
recommended. Noted here to document that this was evaluated and accepted.

---

## Remediation Order

| ID | Priority | Effort | Can be done now? |
|---|---|---|---|
| PERF-01 | P2 | Small — replace `c(failures, x)` with logical mask | Yes (in both functions; or once in ARC-01 helper) |
| PERF-03 | P3 | Small — replace `digest` call in `hash_files_in_dir` | Yes |
| PERF-02 | P3 | Medium — requires API design + dependency decision | Backlog |
| PERF-04 | P3 | None — accepted as-is | N/A |

PERF-01 and PERF-03 can be fixed immediately with no test-breaking risk.
PERF-01 fix should be coordinated with ARC-01 (DRY refactor of the copy
functions) to avoid patching the same code twice.
