#!/bin/bash
# Generate per-user folders from templates
# Usage: ./scripts/generate_user_folders.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE_DIR="$BASE_DIR/templates"

for i in $(seq -w 1 10); do
    USER_DIR="$BASE_DIR/USER_HOL_${i}"
    mkdir -p "$USER_DIR"
    
    for tmpl in "$TEMPLATE_DIR"/*.sql "$TEMPLATE_DIR"/*.yaml "$TEMPLATE_DIR"/*.md "$TEMPLATE_DIR"/*.ipynb; do
        [ -f "$tmpl" ] || continue
        fname=$(basename "$tmpl")
        sed "s/{{USER_NUM}}/${i}/g" "$tmpl" > "$USER_DIR/$fname"
    done

    # Stale files from earlier template revisions (cleanup moved 09 -> 10).
    rm -f "$USER_DIR/09_cleanup.sql"
    
    echo "Generated USER_HOL_${i}/"
done

echo "Done! All 10 user folders generated."
