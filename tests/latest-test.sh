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

setup_crane() {
  local mode=$1
  cat >"$TMPDIR/crane" <<'SCRIPT'
#!/bin/bash
set -euo pipefail
case "$1" in
  digest)
    case "$2" in
      nginx:latest) printf '%s\n' 'sha256:alias-nginx-113' ;;
      nginx:1.13) printf '%s\n' 'sha256:alias-nginx-113' ;;
      nginx:1.13.8) printf '%s\n' 'sha256:alias-nginx-113' ;;
      nginx:1.13.9) printf '%s\n' 'sha256:other-nginx-1139' ;;
      *) exit 1 ;;
    esac
    ;;
  ls)
    printf '%s\n' '1.13.9' '1.13.8' '1.13' '1.13-alpine'
    ;;
  *) exit 1 ;;
esac
SCRIPT
  if [ "$mode" = fail-digest ]; then
    sed -i 's/nginx:latest) printf.*/nginx:latest) exit 1 ;;/' "$TMPDIR/crane"
  fi
  chmod +x "$TMPDIR/crane"
}

resolves_matching_lower_patch() {
  setup_crane normal
  local actual
  actual=$(PATH="$TMPDIR:$PATH" bash "$ROOT/scripts/latest.sh" nginx)
  [ "$actual" = 1.13.8 ]
}

reference_digest_failure() {
  setup_crane fail-digest
  local stderr status
  set +e
  stderr=$(PATH="$TMPDIR:$PATH" bash "$ROOT/scripts/latest.sh" nginx 2>&1 >/dev/null)
  status=$?
  set -e
  [ "$status" -ne 0 ] && [[ "$stderr" == *"Error: Could not fetch digest for nginx:latest"* ]]
}

run_case 'latest resolves to matching lower patch' resolves_matching_lower_patch
run_case 'reference digest failure is reported' reference_digest_failure

[ "$TEST_VERBOSE" = 0 ] || printf 'latest integration tests: ok\n'
