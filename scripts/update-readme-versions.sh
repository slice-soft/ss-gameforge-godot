#!/usr/bin/env bash
# update-readme-versions.sh
#
# Reads .release-please-manifest.json, fetches the latest GitHub release
# for each addon, and rewrites the ADDONS-TABLE section in README.md and README.es.md.
#
# Requirements: gh CLI (authenticated), jq
# Usage: ./scripts/update-readme-versions.sh

set -euo pipefail

REPO="slice-soft/ss-gameforge-godot"
MANIFEST=".release-please-manifest.json"
READMES="README.md README.es.md"
START_MARKER="<!-- ADDONS-TABLE:START -->"
END_MARKER="<!-- ADDONS-TABLE:END -->"

# --- checks ---
if ! command -v gh &>/dev/null; then
  echo "error: gh CLI not found. Install it from https://cli.github.com" >&2
  exit 1
fi
if ! command -v jq &>/dev/null; then
  echo "error: jq not found." >&2
  exit 1
fi
if [ ! -f "$MANIFEST" ]; then
  echo "error: $MANIFEST not found. Run from the repo root." >&2
  exit 1
fi

# --- build table rows ---
rows=""
tmp_paths=$(mktemp)
jq -r 'keys[]' "$MANIFEST" > "$tmp_paths"

while IFS= read -r addon_path; do
  addon_name=$(basename "$addon_path")
  version=$(jq -r --arg p "$addon_path" '.[$p]' "$MANIFEST")
  tag="${addon_name}-v${version}"

  # Fetch release from GitHub
  release_json=$(gh release view "$tag" --repo "$REPO" --json tagName,url,assets 2>/dev/null || echo "")

  if [ -z "$release_json" ]; then
    echo "  warn: no release found for $tag — skipping"
    continue
  fi

  release_url=$(echo "$release_json" | jq -r '.url')
  zip_url=$(echo "$release_json" | jq -r --arg z "${addon_name}-v${version}.zip" \
    '.assets[] | select(.name == $z) | .url' 2>/dev/null || echo "")

  if [ -n "$zip_url" ]; then
    download_cell="[\`${addon_name}-v${version}.zip\`](${zip_url})"
  else
    download_cell="—"
  fi

  rows="${rows}| \`${addon_name}\` | [v${version}](${release_url}) | ${download_cell} |
"
  echo "  ok: $addon_name @ v$version"

done < "$tmp_paths"
rm -f "$tmp_paths"

# --- write block to temp file (avoids awk newline-in-variable issue on macOS) ---
tmp_block=$(mktemp)
printf '%s\n' "$START_MARKER" \
  "| Addon | Version | Download |" \
  "|-------|---------|----------|" \
  > "$tmp_block"
printf '%s' "$rows" >> "$tmp_block"
printf '%s\n' "$END_MARKER" >> "$tmp_block"

# --- replace section in all READMEs ---
for readme in $READMES; do
  if [ ! -f "$readme" ]; then
    echo "  skip: $readme not found"
    continue
  fi
  awk -v blockfile="$tmp_block" '
    /<!-- ADDONS-TABLE:START -->/ {
      while ((getline line < blockfile) > 0) print line
      close(blockfile)
      skip=1; next
    }
    /<!-- ADDONS-TABLE:END -->/ { skip=0; next }
    !skip                       { print }
  ' "$readme" > "${readme}.tmp" && mv "${readme}.tmp" "$readme"
  echo "  updated: $readme"
done

rm -f "$tmp_block"

echo ""
echo "Done."
