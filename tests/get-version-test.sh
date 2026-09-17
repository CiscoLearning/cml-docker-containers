#!/bin/bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_VERBOSE=${TEST_VERBOSE:-1}
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

run_case() {
  local name=$1
  shift
  if "$@"; then
    [ "$TEST_VERBOSE" = 0 ] || printf 'ok - %s\n' "$name"
  else
    printf 'not ok - %s\n' "$name" >&2
    exit 1
  fi
}

assert_eq() {
  local expected=$1 actual=$2
  [ "$actual" = "$expected" ] || {
    printf 'expected %q, got %q\n' "$expected" "$actual" >&2
    return 1
  }
}

run_get_version() {
  local type=$1
  shift
  CACHE_DIR="$TMPDIR/cache" CACHE_TTL=3600 \
    bash "$ROOT/scripts/get_version.sh" "$type" "$@"
}

plain_deb() {
  assert_eq 1.10.0 "$(run_get_version deb "file://$ROOT/tests/fixtures/debian-packages.txt" demo)"
}

gzip_deb() {
  local index=$TMPDIR/Packages.gz
  gzip -c "$ROOT/tests/fixtures/debian-packages.txt" >"$index"
  assert_eq 1.10.0 "$(run_get_version deb "file://$index" demo)"
}

xz_deb() {
  local index=$TMPDIR/Packages.xz
  xz -c "$ROOT/tests/fixtures/debian-packages.txt" >"$index"
  assert_eq 1.10.0 "$(run_get_version deb "file://$index" demo)"
}

multiple_deb_indexes() {
  local newer=$TMPDIR/Packages-newer
  printf 'Package: demo\nVersion: 2.0\n' >"$newer"
  assert_eq 2.0 "$(run_get_version deb \
    "file://$ROOT/tests/fixtures/debian-packages.txt" \
    "file://$newer" demo)"
}

apk() {
  local index=$TMPDIR/APKINDEX.tar.gz
  tar -czf "$index" -C "$ROOT/tests/fixtures" --transform='s/apkindex.txt/APKINDEX/' apkindex.txt
  assert_eq 1.10.0-r0 "$(run_get_version apk "file://$index" demo)"
}

package_boundary() {
  assert_eq 7.0 "$(run_get_version deb "file://$ROOT/tests/fixtures/debian-packages.txt" demo-tools)"
}

missing_package() {
  [ -z "$(run_get_version deb "file://$ROOT/tests/fixtures/debian-packages-empty.txt" demo)" ]
}

unknown_type() {
  ! run_get_version rpm "file://$ROOT/tests/fixtures/debian-packages.txt" demo >/dev/null 2>&1
}

invalid_apk() {
  local index=$TMPDIR/invalid.tar.gz
  printf 'not a tar archive\n' | gzip >"$index"
  ! run_get_version apk "file://$index" demo >/dev/null 2>&1
}

cache_hit() {
  local index=$TMPDIR/cache-packages.txt
  cp "$ROOT/tests/fixtures/debian-packages.txt" "$index"
  assert_eq 1.10.0 "$(run_get_version deb "file://$index" demo)"
  printf 'Package: demo\nVersion: 999.0\n' >"$index"
  assert_eq 1.10.0 "$(run_get_version deb "file://$index" demo)"
}

failed_fetch_not_cached() {
  local index=$TMPDIR/missing-packages.txt
  run_get_version deb "file://$index" demo >/dev/null 2>&1 && return 1
  printf 'Package: demo\nVersion: 2.0\n' >"$index"
  assert_eq 2.0 "$(run_get_version deb "file://$index" demo)"
}

run_case 'Debian plain index selects highest version' plain_deb
run_case 'Debian gzip index selects highest version' gzip_deb
run_case 'Debian xz index selects highest version' xz_deb
run_case 'multiple Debian indexes select highest version' multiple_deb_indexes
run_case 'Alpine index selects highest version' apk
run_case 'package names match exactly' package_boundary
run_case 'missing package returns no version' missing_package
run_case 'unknown package format fails' unknown_type
run_case 'invalid Alpine index fails' invalid_apk
run_case 'cached index is reused' cache_hit
run_case 'failed fetch is not cached' failed_fetch_not_cached

[ "$TEST_VERBOSE" = 0 ] || printf 'get-version tests: ok\n'
