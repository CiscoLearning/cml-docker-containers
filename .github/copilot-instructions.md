# Review instructions

When reviewing shell scripts, run `shfmt -w -i 2 -ci` on changed shell scripts and tests, and verify `set -euo pipefail` behavior.

Review Makefile changes for default-preserving overrides and dry-run behavior.

For version-resolution changes, require deterministic tests covering registry/package failures, cache behavior, tag ordering, and digest mismatches.

Do not treat a successful shell command with empty output as a valid version.
