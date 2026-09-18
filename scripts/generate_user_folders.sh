#!/bin/bash
# Generate per-user folders from templates
# Usage: ./scripts/generate_user_folders.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$BASE_DIR/templates"

for i in $(seq -w 1 10); do
    USER_DIR="$BASE_DIR/user_${i}"
    mkdir -p "$USER_DIR"
    
    for tmpl in "$TEMPLATE_DIR"/*.sql "$TEMPLATE_DIR"/*.yaml; do
        [ -f "$tmpl" ] || continue
        fname=$(basename "$tmpl")
        sed "s/{{USER_NUM}}/${i}/g" "$tmpl" > "$USER_DIR/$fname"
    done
    
    echo "Generated user_${i}/"
done

echo "Done! All 10 user folders generated."
