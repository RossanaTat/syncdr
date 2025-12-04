# syncdr — NEWS

All notable changes to this package are recorded in this file.

## Version 0.1.0 (2025-12-04) — Initial CRAN release

### Main features
- Add bidirectional synchronization primitives: symmetric_sync() provides conflict-aware two-way syncing for directory trees.
- Add one-way synchronization: asymmetric_sync() for push/pull style operations.
- Add directory comparison utility compare_directories() to detect new, removed, modified and conflicted entries before performing syncs.
- Add toy_dirs() helper to quickly create reproducible example directory trees for demos and tests.
- Add user-friendly wrappers (wrappers.R) that combine compare + sync flows for common workflows.

### Convenience & user interface
- New action and display helpers (action_functions.R, display_functions.R, styling_functions.R, print.R) to produce clear, structured console output and human-readable summaries of planned synchronization actions.
- Small, focused API that exposes clear entry points for typical sync workflows while keeping low-level primitives available for advanced usage.

### Documentation
- Rd documentation provided for exported functions with examples demonstrating basic compare and sync workflows.
- Examples in help pages illustrate typical use cases (preview compare, one-way sync, two-way sync).

### Tests
- Comprehensive unit tests covering core behavior: tests for symmetric and asymmetric sync, comparison logic, display and action helpers, utility functions, and toy_dirs.
- Snapshot tests included for stable console output and printed summaries.
- Test suite demonstrates handling of typical edge cases (empty trees, missing files, basic conflict scenarios).

### Internal improvements
- Code organized into clear modules: sync implementations, comparison utilities, display/action layers, and general utilities (utils.R, auxiliary_functions.R).
- Namespace initialization and package hooks centralized (zzz.R).
- Emphasis on modularity to make future maintenance and testing straightforward.

### Bug fixes and robustness
- Path normalization and cross-platform considerations added to reduce Windows/Unix discrepancies.
- Improved handling for missing directories and permission-related errors: operations fail with informative messages rather than silent errors.
- More defensive checks in comparison and sync steps to avoid partial updates when preconditions are not met.

### Developer notes / future work
TODO
