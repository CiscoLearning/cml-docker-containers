#!/bin/bash
set -euo pipefail

type="$1"
url="$2"
pkg="$3"

CACHE_DIR="${CACHE_DIR:-/tmp/cml-docker-containers-cache}"
CACHE_TTL="${CACHE_TTL:-3600}"

_cache_init() {
  mkdir -p "$CACHE_DIR"
}

_cache_get() {
  local url="$1"
  local hash
  hash=$(echo "$url" | md5sum | cut -d' ' -f1)
  echo "$CACHE_DIR/$hash"
}

_cache_age() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo 999999
    return
  fi
  local now age
  now=$(date +%s)
  age=$((now - $(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo 0)))
  echo "$age"
}

_cache_fetch() {
  local url="$1"
  local dest tmp age
  dest=$(_cache_get "$url")
  age=$(_cache_age "$dest")

  if [[ "$age" -lt "$CACHE_TTL" ]] && [[ -s "$dest" ]]; then
    cat "$dest"
    return 0
  fi

  tmp=$(mktemp "${dest}.tmp.XXXXXX")
  if ! curl --fail --silent --show-error "$url" >"$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  if [[ ! -s "$tmp" ]]; then
    rm -f "$tmp"
    echo "Empty response from $url" >&2
    return 1
  fi
  mv "$tmp" "$dest"
  cat "$dest"
}

_cache_init

case "$type" in
  deb)
    # The indexes should match the repositories used by the image build. A
    # lookup and the later package install are not atomic; a repository update
    # between them can still make the reported artifact version differ from
    # the version installed in the image.
    # Accept one or more package indexes followed by the package name.
    pkg="${!#}"
    urls=("${@:2:$#-2}")
    for index_url in "${urls[@]}"; do
      case "$index_url" in
        *.gz) data_stream="gzip -dc" ;;
        *.xz) data_stream="xz -dc" ;;
        *) data_stream="cat" ;;
      esac
      _cache_fetch "$index_url" | $data_stream | awk -v package="$pkg" '
        $1 == "Package:" { p = ($2 == package) }
        p && $1 == "Version:" { print $2 }
      '
    done | sort -V | tail -n1
    ;;
  apk)
    _cache_fetch "$url" | tar -xzO -f - APKINDEX 2>/dev/null | awk -F: -v package="$pkg" '
      $1 == "P" && $2 == package { p = 1 }
      p && $1 == "V" { print $2; p = 0 }
    ' | sort -V | tail -n1
    ;;
  *)
    echo "Unknown type: $type" >&2
    exit 1
    ;;
esac
