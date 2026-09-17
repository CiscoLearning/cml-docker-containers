#!/bin/bash

# Return the highest patch tag extending ALIAS whose digest equals TARGET_SHA.
# SNAPSHOT is newline-separated: tag<TAB>digest.
refine_alias() {
  local alias=$1 target_sha=$2 snapshot=$3
  local base suffix cand digest rest matches
  base=${alias%%-*}
  suffix=${alias#"$base"}

  # Only refine two-component series aliases (for example, 1.31 or 1.31-alpine).
  [[ $base =~ ^[0-9]+\.[0-9]+$ ]] || return 1

  matches=""
  while IFS=$'\t' read -r cand digest; do
    [ -n "$cand" ] || continue
    [ "$digest" = "$target_sha" ] || continue
    rest=${cand%"$suffix"}
    [ "$rest$suffix" = "$cand" ] || continue
    case "$rest" in
      "$base".*) ;;
      *) continue ;;
    esac
    echo "${rest#"$base".}" | grep -qE '^[0-9]+(\.[0-9]+)*$' || continue
    matches="$matches$cand"$'\n'
  done <<<"$snapshot"

  [ -n "$matches" ] || return 1
  printf '%s\n' "$matches" | grep -v '^$' | sort -V -r | head -1
}
