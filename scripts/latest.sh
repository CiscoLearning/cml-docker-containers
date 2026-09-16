#!/bin/bash

# usage: VERSION=$(bash latest.sh IMAGE [REF_TAG])  -- default REF_TAG=latest
# Resolves REF_TAG to a versioned tag matching its digest, via short-circuit walk.

set -euo pipefail

IMAGE=${1:-}
REF_TAG=${2:-latest}
MAX_CHECKS=25

log() { echo "$@" >&2; }

if [ -z "$IMAGE" ]; then
  log "Error: No image specified."
  exit 1
fi

# 1. resolve REF_TAG to a digest
TARGET_SHA=$(crane digest "$IMAGE:$REF_TAG" 2>/dev/null)
if [ -z "$TARGET_SHA" ]; then
  log "Error: Could not fetch digest for $IMAGE:$REF_TAG"
  exit 1
fi

# 2. retry-on-429 wrapper for a single digest call
get_digest_with_retry() {
  local img=$1 tag=$2 attempt=1 out status
  while [ $attempt -le 4 ]; do
    out=$(crane digest "$img:$tag" 2>&1)
    status=$?
    if [ $status -eq 0 ]; then echo "$out"; return 0; fi
    echo "$out" | grep -q "429" || return 1
    sleep $((attempt * 2))
    attempt=$((attempt + 1))
  done
  return 1
}

# 3. list tags, filter to plausibly-versioned, sort newest first
log "fetching tags and matching digests..."
versioned=$(crane ls "$IMAGE" 2>/dev/null \
  | grep -Ev '^sha256[-.:][0-9a-f]+(\.(sig|att|sbom))?$' \
  | grep -vE '^[0-9a-f]{8,}$' \
  | grep -E '^[0-9]' \
  | grep -F '.' \
  | sort -V -r \
  | uniq)

# 4. digest-check in two passes, short-circuit on first match (bounded by MAX_CHECKS)
find_match() {
  local list=$1 tag sha checked=0
  while IFS= read -r tag; do
    [ -n "$tag" ] || continue
    [ "$checked" -ge "$MAX_CHECKS" ] && return 1
    checked=$((checked + 1))
    sha=$(get_digest_with_retry "$IMAGE" "$tag") || continue
    [ "$sha" = "$TARGET_SHA" ] && { echo "$tag"; return 0; }
  done <<<"$list"
  return 1
}

# Pass order tracks REF_TAG: dashed -> qualified tags first, else clean tags first.
no_dash=$(echo "$versioned" | grep -v -- '-')
with_dash=$(echo "$versioned" | grep    -- '-')
case "$REF_TAG" in
  *-*) p1=$with_dash; p2=$no_dash ;;
    *) p1=$no_dash;   p2=$with_dash ;;
esac
BEST_TAG=$(find_match "$p1") || BEST_TAG=$(find_match "$p2") || BEST_TAG=""

# 5. a series alias ("1.31") carries the newest patch release of that series but
# hides its number, so the version, and the image definition id derived from it,
# would sort below an older but fully numbered build. Replace it with the highest
# published tag that extends it ("1.31.6").
refine_alias() {
  local tag=$1 base suffix cand rest matches
  base=${tag%%-*}
  suffix=${tag#"$base"}
  matches=""
  while IFS= read -r cand; do
    [ -n "$cand" ] || continue
    rest=${cand%"$suffix"}
    [ "$rest$suffix" = "$cand" ] || continue
    case "$rest" in "$base".*) ;; *) continue ;; esac
    echo "${rest#"$base".}" | grep -qE '^[0-9]+(\.[0-9]+)*$' || continue
    matches="$matches$cand"$'\n'
  done <<<"$versioned"
  [ -n "$matches" ] || return 1
  echo "$matches" | grep -v '^$' | sort -V -r | head -1
}

if [ -n "$BEST_TAG" ]; then
  if REFINED=$(refine_alias "$BEST_TAG") && [ -n "$REFINED" ]; then
    log "refining series alias $BEST_TAG to $REFINED"
    BEST_TAG=$REFINED
  fi
  echo "$BEST_TAG"
else
  log "No versioned tag found matching $REF_TAG."
  exit 1
fi
