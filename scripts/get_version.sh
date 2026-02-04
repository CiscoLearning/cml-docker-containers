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
  local dest="$(_cache_get "$url")"
  local age
  age=$(_cache_age "$dest")

  if [[ "$age" -lt "$CACHE_TTL" ]] && [[ -s "$dest" ]]; then
    cat "$dest"
    return 0
  fi

  curl -s "$url" > "$dest"
  cat "$dest"
}

_cache_init

case "$type" in
  deb)
    if [[ "$url" == *.gz ]]; then
      data_stream="gzip -dc"
    else
      data_stream="cat"
    fi
    _cache_fetch "$url" | $data_stream | awk -v package="$pkg" '
      $1 == "Package:" { p = ($2 == package) }
      p && $1 == "Version:" { print $2 }
    ' | sort -V | tail -n1
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
