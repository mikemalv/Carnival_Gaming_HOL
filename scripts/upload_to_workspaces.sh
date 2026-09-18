#!/bin/bash
# Upload HOL files to per-user Snowflake workspaces
# 
# Prerequisites:
#   1. Run admin/01_create_workspaces.sql on HOL_CARNIVAL as ACCOUNTADMIN
#   2. Set CORTEX_CONNECTION below to your HOL_CARNIVAL connection name
#      (or add one: snow connection add --connection-name hol_carnival ...)
#
# Usage: ./scripts/upload_to_workspaces.sh [connection_name]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
CONNECTION="${1:-hol_carnival}"
WS_DB="HOL_WORKSPACES.PUBLIC"

echo "Uploading HOL files to Snowflake workspaces..."
echo "Connection: $CONNECTION"
echo "Workspace DB: $WS_DB"
echo ""

for i in $(seq -w 1 10); do
    USER_DIR="$BASE_DIR/USER_HOL_${i}"
    WS_FQN="${WS_DB}.USER_HOL_${i}"
    
    if [ ! -d "$USER_DIR" ]; then
        echo "SKIP: $USER_DIR does not exist"
        continue
    fi
    
    echo "--- Uploading to ${WS_FQN} ---"
    
    # Upload each file individually (cortex ws cp doesn't support recursive)
    for f in "$USER_DIR"/*.sql "$USER_DIR"/*.yaml "$USER_DIR"/*.md; do
        [ -f "$f" ] || continue
        fname=$(basename "$f")
        echo "  $fname"
        cortex ws cp "$f" "${WS_FQN}:/${fname}" -c "$CONNECTION" 2>&1
    done
    
    # Publish the workspace so users can see the files
    echo "  Publishing workspace..."
    snow sql -c "$CONNECTION" -q "ALTER WORKSPACE ${WS_FQN} COMMIT;" 2>&1
    
    echo "  Done: USER_HOL_${i}"
    echo ""
done

echo "All workspaces uploaded and published."
echo ""
echo "Users can find their files in Snowsight:"
echo "  Projects > Workspaces > HOL_WORKSPACES > USER_HOL_XX"
