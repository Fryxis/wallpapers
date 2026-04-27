#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

# Usage:
#   ./rename_photos.sh [dossier] [numero_depart]
# Exemples:
#   ./rename_photos.sh
#   ./rename_photos.sh . 1
#   ./rename_photos.sh /chemin/vers/photos 10

TARGET_DIR="${1:-.}"
START_AT="${2:-1}"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Erreur: dossier introuvable: $TARGET_DIR" >&2
  exit 1
fi

if ! [[ "$START_AT" =~ ^[0-9]+$ ]]; then
  echo "Erreur: numero_depart doit etre un entier positif." >&2
  exit 1
fi

mapfile -t FILES < <(
  for f in "$TARGET_DIR"/*; do
    [[ -f "$f" ]] || continue
    name="${f##*/}"
    ext="${name##*.}"
    ext_lower="${ext,,}"
    case "$ext_lower" in
      jpg|jpeg|png|webp|gif|bmp|tif|tiff)
        printf '%s\n' "$f"
        ;;
    esac
  done | sort -V
)

if [[ "${#FILES[@]}" -eq 0 ]]; then
  echo "Aucune image a renommer dans $TARGET_DIR"
  exit 0
fi

index="$START_AT"

# Phase 1: noms temporaires pour eviter les conflits.
for file in "${FILES[@]}"; do
  tmp="${file}.tmp_rename_$$"
  mv -- "$file" "$tmp"
done

# Phase 2: renommage final 1.jpg, 2.png, etc.
for tmp in "$TARGET_DIR"/*.tmp_rename_"$$"; do
  base="${tmp##*/}"
  original_ext="${base%".tmp_rename_$$"}"
  original_ext="${original_ext##*.}"
  final="$TARGET_DIR/$index.$original_ext"
  mv -- "$tmp" "$final"
  echo "Renomme: ${tmp##*/} -> ${index}.${original_ext}"
  ((index++))
done

echo "Termine: $((index - START_AT)) image(s) renommee(s)."
