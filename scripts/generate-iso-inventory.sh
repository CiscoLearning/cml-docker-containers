#!/bin/bash
set -euo pipefail

# generate-iso-inventory.sh
# Usage: generate-iso-inventory.sh TS IMAGES_DIR [CONTAINERS_DIR]
# - TS: timestamp string used for ISO build (e.g., 20251024140158)
# - IMAGES_DIR: path to images root, e.g., BUILD/debian/<PKG>/var/lib/libvirt/images
# - CONTAINERS_DIR: optional; defaults to "containers"
#
# Produces Markdown to stdout with an inventory per ISO group:
# - Header per ISO: \n## refplat-<TS>-<TYPE>.iso
# - Table: Container | Description/Version | Artifacts | Size
# - Description: YAML ui.description
# - Artifacts include node-definition YAML and image tarball + image-definition YAML when present
# - Size with size of tar.gz

TS=${1:?usage: generate-iso-inventory.sh TS IMAGES_DIR [CONTAINERS_DIR]}
IMAGES_DIR=${2:?usage: generate-iso-inventory.sh TS IMAGES_DIR [CONTAINERS_DIR]}
CONTAINERS_DIR=${3:-containers}

if [ ! -d "$IMAGES_DIR" ]; then
  echo "Images dir not found: $IMAGES_DIR" >&2
  exit 1
fi
if [ ! -d "$CONTAINERS_DIR" ]; then
  echo "Containers dir not found: $CONTAINERS_DIR" >&2
  exit 1
fi

# Helper: trim trailing whitespace, remove CRs
trim_ws() {
  tr -d '\r' | sed -E 's/[[:space:]]+$//'
}

# Helper: read variable from vars.mk (NAME, VERSION, FULLDESC, DESC)
get_var_from_vars_mk() {
  local file=$1 var=$2
  awk -F '(:=|=)' -v V="$var" '
    BEGIN{IGNORECASE=0}
    /^[[:space:]]*#/ {next}
    $0 ~ "^[[:space:]]*" V "[[:space:]]*(:=|=)" {
      x=$2
      sub(/^[[:space:]]+/, "", x)
      sub(/[[:space:]]+$/, "", x)
      print x
      exit
    }
  ' "$file" | tr -d '\r'
}

# Escape replacement content for sed
sed_escape() {
  sed -e 's/[\\&\//]/\\&/g'
}

# Helper: sanitize text for Markdown table cell
md_sanitize() {
  sed -E 's/\|/\\|/g; s/`/\\`/g' | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'
}

# Build suffix list (including empty)
mapfile -t SUFFIXES < <(for d in "$CONTAINERS_DIR"/*; do
  [ -d "$d" ] || continue
  [ -f "$d/.disabled" ] && continue
  if [ -f "$d/iso-name" ]; then
    tr -d '\r\n' <"$d/iso-name" | trim_ws
  else
    echo "services"
  fi
done | sort -u)

# Generate Markdown
printf "# ISO Inventory\n\n"
for sfx in "${SUFFIXES[@]}"; do
  iso_name="refplat-${TS}-${sfx}.iso"
  printf "## %s\n\n" "$iso_name"
  printf "| Container | Description/Version | Artifacts | Size |\n"
  printf "|---|---|---|---|\n"
  # Iterate modules in this suffix group
  for d in "$CONTAINERS_DIR"/*; do
    [ -d "$d" ] || continue
    [ -f "$d/.disabled" ] && continue
    if [ -f "$d/iso-name" ]; then
      dsfx=$(tr -d '\r\n' <"$d/iso-name" | trim_ws)
    else
      dsfx="services"
    fi
    [ "$dsfx" = "$sfx" ] || continue

    # Module name: from vars.mk NAME or basename
    mod_name=$(basename "$d")
    if [ -f "$d/vars.mk" ]; then
      name_from_vars=$(get_var_from_vars_mk "$d/vars.mk" NAME || true)
      if [ -n "${name_from_vars:-}" ]; then
        mod_name="$name_from_vars"
      fi
    fi

    # Description: prefer YAML ui.description; fallback to expanded FULLDESC
    fulldesc_disp=""
    nd_yaml_rel="node-definitions/${mod_name}.yaml"
    nd_yaml="$IMAGES_DIR/$nd_yaml_rel"
    if [ -f "$nd_yaml" ]; then
      # Extract ui.description via yq (supports scalars and block strings)
      desc_yaml=$(yq -r '.ui.description // ""' "$nd_yaml" 2>/dev/null || yq e -r '.ui.description // ""' "$nd_yaml" 2>/dev/null || echo "")
      desc_yaml=$(printf "%s" "$desc_yaml" | tr -d '\r')
      if [ -n "${desc_yaml:-}" ]; then
        fulldesc_disp=$(printf "%s" "$desc_yaml" | md_sanitize)
      fi
    fi
    # fallback
    if [ -z "$fulldesc_disp" ]; then
      fulldesc_disp="${mod_name}/unknown"
    fi

    # discover artifact directory by scanning actual outputs to avoid VERSION mismatches
    ntag=""
    for vdir in "$IMAGES_DIR/virl-base-images/${mod_name}-"*; do
      [ -d "$vdir" ] || continue
      bn=$(basename "$vdir")
      # prefer a directory that contains both yaml and tar.gz
      if [ -f "$vdir/$bn.yaml" ] && [ -f "$vdir/$bn.tar.gz" ]; then
        ntag="$bn"
        break
      fi
      # else remember first seen
      [ -n "$ntag" ] || ntag="$bn"
    done

    # Collect artifacts (if present), build bullet list, and compute tar.gz size
    artifacts=()
    artifacts_lines=()
    size_disp="-"
    if [ -f "$nd_yaml" ]; then artifacts+=("$nd_yaml_rel"); fi
    if [ -n "$ntag" ]; then
      img_yaml_rel="virl-base-images/${ntag}/${ntag}.yaml"
      img_tgz_rel="virl-base-images/${ntag}/${ntag}.tar.gz"
      if [ -f "$IMAGES_DIR/$img_yaml_rel" ]; then artifacts+=("$img_yaml_rel"); fi
      if [ -f "$IMAGES_DIR/$img_tgz_rel" ]; then
        artifacts+=("$img_tgz_rel")
        # compute human size
        bytes=$(stat -c%s "$IMAGES_DIR/$img_tgz_rel" 2>/dev/null || echo "")
        if [ -n "$bytes" ]; then
          if command -v numfmt >/dev/null 2>&1; then
            size_disp=$(numfmt --to=iec --suffix=B "$bytes" 2>/dev/null || echo "$bytes B")
          else
            size_disp=$(ls -lh "$IMAGES_DIR/$img_tgz_rel" | awk '{print $5}')
          fi
        fi
      fi
    fi
    for a in "${artifacts[@]}"; do artifacts_lines+=("- $a"); done
    if [ ${#artifacts_lines[@]} -eq 0 ]; then
      artifacts_disp="no artifacts (build modules first)"
    else
      # join with <br> for multi-line list inside table cell
      artifacts_disp=$(printf "%s\n" "${artifacts_lines[@]}" | sed ':a;N;$!ba;s/\n/<br>/g')
    fi

    printf "| %s | %s | %s | %s |\n" "$mod_name" "$fulldesc_disp" "$artifacts_disp" "$size_disp"
  done
  printf "\n"
done
