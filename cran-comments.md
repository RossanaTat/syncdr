## CRAN submission notes — first release

Package: syncdr
Version: 0.1.2
Maintainer: Rossana Tatulli <rtatulli@worldbank.org>

This is the first CRAN submission of the syncdr package.

#### Checks performed:

- devtools::document()
- devtools::check(remote = TRUE, manual = TRUE)
- rcmdcheck::rcmdcheck(args = "--as-cran")
- covr::package_coverage()
- spelling::spell_check_package()
- urlchecker::url_check()

Checks were run on:
- Local machine (Windows 11, R 4.3.2)
- GitHub Actions (windows-latest, macOS-latest, ubuntu-latest)

#### Notes:

- The single NOTE about "unable to verify current time" comes from the Windows system clock and is not indicative of a package issue.
- References in DESCRIPTION: no methodological references are included because the package provides practical file system utilities (directory comparison and synchronization) rather than implementing or extending a published statistical or computational methodology.
- Any other NOTE shown is the standard NOTE for a first-time CRAN submission.

## Resubmission

This is a resubmission of the syncdr package.

Changes made in response to CRAN feedback:
- Fixed documentation examples that called non-existent or unexported functions (`filter_sync_status`, `style_msgs`).
- Ensured all user-facing functions are properly exported and documented.
- Updated or removed examples for internal functions to prevent errors during `R CMD check`.
- Increased the patch version number in DESCRIPTION.
- Confirmed that all checks pass without errors or warnings, except for the standard NOTE about "unable to verify current time" on Windows.

## Security hardening resubmission (current)

This is a further resubmission following an internal security and robustness audit.
No new user-facing features are added; all changes are hardening fixes.

Key changes since the previous submission:
- **Path safety**: replaced all `gsub()`-based path stripping with `fs::path_rel()`
  to prevent regex-metacharacter injection and Windows backslash misinterpretation.
- **Input validation**: added guards for identical paths (self-sync), nested paths,
  invalid path arguments (NA/empty/length > 1), malformed `sync_status` objects,
  and unsafe `backup_dir` placements.
- **Backup reliability**: centralised backup logic in a new `perform_backup()` helper
  that verifies backup success before proceeding, uses timestamped subdirectories,
  preserves directory structure, and warns when using the ephemeral `tempdir()`.
- **Error handling**: added write-permission preflight checks before copy loops;
  per-file `tryCatch` in copy workers so I/O failures are collected and reported
  without leaving directories in a partially-modified state.
- **API defaults**: changed `force` default from `TRUE` to `FALSE` (requiring
  explicit confirmation); changed `delete_in_right` default from `TRUE` to `FALSE`;
  exposed `overwrite` as a user parameter.
- **Staleness detection**: `compare_directories()` now stamps results with
  `created_at`; sync functions warn when the `sync_status` is over one hour old.

#### Checks performed:

- devtools::document()          — clean, no warnings
- devtools::check_man()         — no issues
- devtools::test()              — FAIL 0 / WARN 8 (all expected, from intentional
                                   overwrite=FALSE and backup-ephemerality tests)
                                   / SKIP 4 (Windows chmod + 2 empty stubs)
                                   / PASS 276
- rcmdcheck::rcmdcheck(args = "--as-cran")
                                — 0 ERRORs, 0 WARNINGs (pdflatex not installed
                                   locally; CRAN servers have LaTeX)
- spelling::spell_check_package() — clean (WORDLIST covers technical terms)
- urlchecker::url_check()       — all URLs valid

Checks were run on:
- Local machine (Windows 11, R 4.3.2)
- GitHub Actions (windows-latest, macOS-latest, ubuntu-latest)

#### Expected NOTEs:

- "unable to verify current time" — Windows system clock artefact, not a package issue.
- Standard new-submission NOTE (if this is treated as a new submission by CRAN).
