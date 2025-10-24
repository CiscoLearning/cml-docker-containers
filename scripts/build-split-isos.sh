#!/bin/sh
set -eu

TS=${1:?usage: build-split-isos.sh TS SUBDIRS images_dir}
SUBDIRS_STR=${2:?usage: build-split-isos.sh TS SUBDIRS images_dir}
IMAGES_DIR=${3:?usage: build-split-isos.sh TS SUBDIRS images_dir}

if [ ! -d "${IMAGES_DIR}" ]; then
  echo "Images dir not found: ${IMAGES_DIR}" >&2
  exit 1
fi

# iterate over unique suffixes (including empty) discovered from subdirs
# trailing whitespace trimmed with awk for portability
(
  for d in ${SUBDIRS_STR}; do
    [ -f "${d}/.disabled" ] && continue
    if [ -f "${d}/iso-name" ]; then
      sfx=$(tr -d '\r\n' <"${d}/iso-name" | sed -E 's/[[:space:]]+$//')
    else
      sfx=""
    fi
    printf '%s\n' "$sfx"
  done
) | sort -u | while IFS= read -r sfx; do

  staging="${IMAGES_DIR}/iso-staging${sfx}"
  nd="${staging}/node-definitions"
  vb="${staging}/virl-base-images"
  mkdir -p "${nd}" "${vb}"

  for d in ${SUBDIRS_STR}; do
    [ -f "${d}/.disabled" ] && continue
    if [ -f "${d}/iso-name" ]; then
      dsfx=$(tr -d '\r\n' <"${d}/iso-name" | sed -E 's/[[:space:]]+$//')
    else
      dsfx=""
    fi
    [ "${dsfx}" = "${sfx}" ] || continue

    # module NAME from vars.mk if present, else use directory name
    mod_name=$(basename "${d}")
    if [ -f "${d}/vars.mk" ]; then
      name_from_vars=$(awk -F '(:=|=)' 'BEGIN{IGNORECASE=0} /^[[:space:]]*NAME[[:space:]]*(:=|=)/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit }' "${d}/vars.mk") || true
      if [ -n "${name_from_vars:-}" ]; then
        mod_name="$name_from_vars"
      fi
    fi

    # link node-definition yaml if exists
    if [ -f "${IMAGES_DIR}/node-definitions/${mod_name}.yaml" ]; then
      ln -sf "../../node-definitions/${mod_name}.yaml" "${nd}/${mod_name}.yaml"
    fi

    # link virl-base-images artifacts for module
    for vdir in "${IMAGES_DIR}/virl-base-images/${mod_name}-"*; do
      [ -d "${vdir}" ] || continue
      bn=$(basename "${vdir}")
      mkdir -p "${vb}/${bn}"
      for af in "${vdir}"/*; do
        [ -e "${af}" ] || continue
        ln -sf "../../../virl-base-images/${bn}/$(basename "${af}")" "${vb}/${bn}/$(basename "${af}")"
      done
    done
  done

  out_iso="docker-refplat-images${sfx}-${TS}.iso"

  echo "Creating ${out_iso} from ${staging}"
  xorriso -as mkisofs -V REFPLAT -r -J -follow-links -o "${out_iso}" "${staging}"
  echo "Built: ${out_iso}"

done

ls -lh docker-refplat-images*-"${TS}".iso 2>/dev/null || true
