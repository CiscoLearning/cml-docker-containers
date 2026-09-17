#!/bin/bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_VERBOSE=${TEST_VERBOSE:-1}
# shellcheck disable=SC1091
source "$ROOT/scripts/latest-functions.sh"

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

fixture() {
  grep -v '^#' "$ROOT/tests/fixtures/$1"
}

assert_refines_to() {
  local alias=$1 digest=$2 file=$3 expected=$4 actual
  actual=$(refine_alias "$alias" "$digest" "$(fixture "$file")")
  [ "$actual" = "$expected" ] || {
    printf 'expected %s -> %s, got %s\n' "$alias" "$expected" "$actual" >&2
    return 1
  }
}

rejects_refinement() {
  ! refine_alias "$1" "$2" "$(fixture "$3")" >/dev/null
}

run_case 'nginx alias selects matching lower patch' assert_refines_to \
  1.13 sha256:alias-nginx-113 resolver-synthetic.tsv 1.13.8
run_case 'nginx qualified alias preserves suffix' assert_refines_to \
  1.13-alpine sha256:alias-nginx-113-alpine resolver-synthetic.tsv 1.13.9-alpine
run_case 'splunk alias selects matching patch' assert_refines_to \
  10.4 sha256:cc3a3efe2509fa31f67d4aa20dde7118886babf9a0930f197ef996d513c44834 splunk-tags.tsv 10.4.3
run_case 'thousandeyes timestamped tag is not refined' rejects_refinement \
  0.16.24-agent sha256:alias-te-agent thousandeyes-enterprise-agent-tags.tsv
run_case 'digest mismatch is rejected' rejects_refinement \
  1.13 sha256:wrong nginx-tags.tsv
run_case 'fully qualified version is not refined' rejects_refinement \
  1.13.9 sha256:nginx-1139 nginx-tags.tsv
run_case 'missing patch series is rejected' rejects_refinement \
  10.5 sha256:missing splunk-tags.tsv

[ "$TEST_VERBOSE" = 0 ] || printf 'latest-functions tests: ok\n'
