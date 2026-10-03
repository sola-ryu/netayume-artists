#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMFY_CLI="$SCRIPT_DIR/../comfy-cli/run.py"
IMAGES_DIR="$SCRIPT_DIR/images"
ARTISTS_FILE="$SCRIPT_DIR/artists.txt"
DONE_FILE="$SCRIPT_DIR/artists-done.txt"

prompt='"1girl,brown hair,white shirt,"'

mkdir -p "$IMAGES_DIR"
touch "$DONE_FILE"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

while IFS= read -r artist; do
  [ -z "$artist" ] && continue
  grep -qxF "$artist" "$DONE_FILE" && continue

  echo "Generating: $artist"
  rm -f "$tmp_dir"/*.png

  if ! "$COMFY_CLI" anime "$artist, $prompt" -s 1 -W 512 -H 512 -o "$tmp_dir"; then
    echo "  failed, skipping" >&2
    continue
  fi

  out_file="$(find "$tmp_dir" -maxdepth 1 -type f -name '*.png' | head -n1)"
  if [ -z "$out_file" ]; then
    echo "  no output file, skipping" >&2
    continue
  fi

  mv "$out_file" "$IMAGES_DIR/$artist.png"
  echo "$artist" >> "$DONE_FILE"
done < "$ARTISTS_FILE"
