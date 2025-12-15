## CRAN submission notes — first release

Package: syncdr
Version: 0.1.0
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
