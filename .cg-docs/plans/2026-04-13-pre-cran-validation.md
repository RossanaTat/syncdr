---
date: 2026-04-13
title: "Pre-CRAN Validation — Fast Final Checks"
status: completed
completed-date: 2026-04-13
brainstorm: ~
language: "R"
estimated-effort: "small"
tags: [cran, release, validation, security]
---

# Plan: Pre-CRAN Validation — Fast Final Checks

## Objective

Run a focused, high-impact validation pass to confirm that the `syncdr` package (v0.1.1, `security` branch) is CRAN-ready after the security/vulnerability remediation work. This is **not** a full audit — it is a release-gate checklist targeting the things CRAN reviewers check and the things most likely to break after 3,000+ lines of changes.

## Context

- The `security` branch was forked from `DEV` (the branch used for the previous CRAN submission). The delta is 17 modified files (+1,652 / −411 lines) relative to `DEV` — all security/robustness work.
- DESCRIPTION and NAMESPACE are unchanged between `DEV` and `security` (the v0.1.1 metadata submitted to CRAN is already in place).
- A 41-finding vulnerability audit was completed; Fix Groups A–F addressed critical/high issues across path computation, input validation, backup reliability, error handling, and API defaults.
- Groups D and E are confirmed implemented with passing tests (260→265 at time of commit).
- The package previously passed CRAN review for first submission from `DEV` and was resubmitted once for example/export fixes.
- The `roadmap.json` is empty — no milestone tracking needed.

## Implementation Steps

### 1. `R CMD check --as-cran` (zero errors, zero warnings)

- **Action**: Run `devtools::check(remote = TRUE, manual = TRUE)` or `rcmdcheck::rcmdcheck(args = "--as-cran")`.
- **Acceptance criteria**: 0 ERRORs, 0 WARNINGs. Only acceptable NOTE is "New submission" / "unable to verify current time".
- **Why**: This is the single most important gate. If this passes cleanly, the package is structurally sound.

### 2. Full test suite — confirm zero failures

- **Action**: Run `devtools::test()` and confirm all tests pass.
- **Acceptance criteria**: FAIL 0, WARN 0 (or only expected warnings from intentional test logic), SKIP 0 (or documented skips).
- **Why**: The security branch added ~80+ new tests. Confirm nothing regressed.

### 3. Documentation consistency check

- **Action**: Run `devtools::document()` then `devtools::check_man()`. Verify all exported functions in NAMESPACE have `.Rd` files. Spot-check that new parameters added during security fixes (e.g., `overwrite` in copy functions, new validation error messages) are documented in roxygen headers.
- **Files to spot-check**: `R/action_functions.R`, `R/utils.R` (new `perform_backup()`), `R/compare_directories.R` (new `created_at` field), any function where defaults changed (e.g., `force`, `delete_in_right`).
- **Acceptance criteria**: `devtools::document()` produces no diff (docs are up to date). No undocumented exported functions.

### 4. DESCRIPTION and metadata review

- **Action**: Manually verify:
  - `Version:` is correct and incremented from last CRAN submission.
  - All new dependencies (if any) are listed in `Imports:` / `Suggests:`.
  - `Authors@R`, `License`, `URL`, `BugReports` are correct.
  - `Title` and `Description` follow CRAN formatting rules (no period in Title, Description is a paragraph).
- **Acceptance criteria**: DESCRIPTION is clean and CRAN-compliant.

### 5. NEWS.md update

- **Action**: Verify `NEWS.md` documents the security/robustness improvements for this version. CRAN reviewers and users expect a changelog entry for each version.
- **Acceptance criteria**: NEWS.md has a `# syncdr 0.1.1` section listing the key changes (path safety, input validation, backup reliability, error handling, API default changes).

### 6. Spell check and URL check

- **Action**: Run `spelling::spell_check_package()` and `urlchecker::url_check()`.
- **Acceptance criteria**: No real typos in documentation. No broken URLs.

### 7. cran-comments.md update

- **Action**: Update `cran-comments.md` to reflect the current submission context — mention the security hardening, platforms tested, and any expected NOTEs.
- **Acceptance criteria**: `cran-comments.md` is accurate for this submission attempt.

## Testing Strategy

No new tests to write — this plan validates existing test coverage. Step 2 runs the full suite. Step 1 runs examples and vignettes as part of `R CMD check`.

## Documentation Checklist

- [ ] All exported functions have roxygen2 docs (Step 3)
- [ ] New parameters documented (Step 3)
- [ ] NEWS.md updated (Step 5)
- [ ] cran-comments.md updated (Step 7)
- [ ] README does not need changes (no API surface changes visible to users)

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| `R CMD check` fails on vignettes due to missing Suggests | Run with `_R_CHECK_FORCE_SUGGESTS_=false` or ensure all Suggests are installed |
| Default-change (e.g., `force = FALSE`) breaks existing examples | Step 1 catches this — examples run during check |
| New `cli::cli_abort()` messages don't match test expectations | Step 2 catches this |
| Forgotten `@export` or `@param` tag | Step 3 catches this |

## Out of Scope

- Writing new tests (coverage is already strong from the audit)
- Fixing any remaining Low-severity VULs (VUL-29, 32, 33, 35) — these are style/minor and not CRAN blockers
- Multi-platform CI setup (GitHub Actions already configured)
- Performance benchmarking
- `rhub` checks (optional but not gating)
