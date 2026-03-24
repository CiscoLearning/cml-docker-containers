#!/bin/bash

# usage: VERSION=$(bash latest.sh nginx)
IMAGE=$1
PROCS=15 # parallel xargs procs

# redirect all "talk" to stderr so it doesn't pollute the variable
log() { echo "$@" >&2; }

if [ -z "$IMAGE" ]; then
  log "Error: No image specified."
  exit 1
fi

# 1. get the target digest for 'latest'
TARGET_SHA=$(crane digest "$IMAGE:latest" 2> /dev/null)
if [ $? -ne 0 ]; then
  log "Error: Could not fetch digest for $IMAGE:latest"
  exit 1
fi

# 2. function for xargs to use (retries on 429)
get_digest_with_retry() {
  local img=$1
  local tag=$2
  local attempt=1
  local max_attempts=4

  while [ $attempt -le $max_attempts ]; do
    # use --quiet or redirect crane's own stderr if it's too chatty
    out=$(crane digest "$img:$tag" 2>&1)
    status=$?

    if [ $status -eq 0 ]; then
      # format: tag<space>sha
      echo "$tag $out"
      return 0
    elif echo "$out" | grep -q "429"; then
      sleep $((attempt * 2))
      ((attempt++))
    else
      return 1
    fi
  done
  return 1
}
export -f get_digest_with_retry

log "fetching tags and matching digests (using parallel threads)..."

# 3. process tags
# -P 5 keeps us under the radar for rate limits
# we filter for the SHA, then find the 'best' version string
MATCHES=$(crane ls "$IMAGE" | xargs -P $PROCS -I {} bash -c "get_digest_with_retry '$IMAGE' '{}'" |
  grep "$TARGET_SHA" | awk '{print $1}')

# ranking Logic:
# 1. must start with a digit (kills 'latest', 'mainline', 'trixie')
# 2. prefer tags WITHOUT dashes (prefer '1.29' over '1.29-trixie')
# 3. sort by version logic (1.29 > 1.9)
BEST_TAG=$(echo "$MATCHES" | grep -E '^[0-9]' |
  grep -v "-" |
  sort -V | tail -n 1)

# fallback: If everything had a dash (e.g. only 1.29-trixie exists), take the
# best versioned one
if [ -z "$BEST_TAG" ]; then
  BEST_TAG=$(echo "$MATCHES" | grep -E '^[0-9]' | sort -V | tail -n 1)
fi

# 4. final output to STDOUT
if [ -n "$BEST_TAG" ]; then
  echo "$BEST_TAG"
else
  log "No versioned tag found matching latest."
  exit 1
fi
