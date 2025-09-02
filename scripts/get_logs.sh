#!/usr/bin/env bash

# Download complete logs for each failed test case
# Each failed case will have its own .log file
# Usage: ./get_logs.sh <LAUNCH_ID> <TOKEN> [--filter]

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <LAUNCH_ID> <TOKEN> [--filter]"
    echo "  --filter: Automatically filter logs to reduce size by 90%+"
    exit 1
fi

LAUNCH_ID=$1
TOKEN=$2
FILTER_LOGS=false

# Check for filter flag
if [ $# -ge 3 ] && [ "$3" = "--filter" ]; then
    FILTER_LOGS=true
    echo "Filter mode enabled - logs will be automatically filtered"
fi
BASE_URL="https://reportportal-openshift.apps.dno.ocp-hub.prod.psi.redhat.com"

OUTPUT_DIR="failed_cases_${LAUNCH_ID}/logs"
mkdir -p "$OUTPUT_DIR"

echo "Fetching failed test items for Launch $LAUNCH_ID..."

# Get all items from the launch
ITEMS_RESPONSE=$(curl -s -H "Authorization: bearer $TOKEN" \
    "$BASE_URL/api/v1/prow/item?filter.eq.launchId=$LAUNCH_ID&page.size=200")

# Extract Cluster_Operator suite ID
CLUSTER_OPERATOR_ID=$(echo "$ITEMS_RESPONSE" | jq -r '.content[] | select(.name == "Cluster_Operator") | .id' | head -1)
if [ -z "$CLUSTER_OPERATOR_ID" ]; then
    echo "ERROR: Cluster_Operator suite not found"
    exit 1
fi

# Extract failed step IDs and names
echo "$ITEMS_RESPONSE" | jq -r --argjson parent "$CLUSTER_OPERATOR_ID" \
    '.content[] | select(.parent == $parent and .status == "FAILED") | "\(.id)|\(.name)"' > /tmp/failed_steps.txt

echo "Found failed steps, downloading logs per test case..."

while IFS='|' read -r STEP_ID STEP_NAME; do
    [ -z "$STEP_ID" ] && continue

    # Extract all case IDs (e.g., OCP-12345) from the test name
    CASE_IDS=$(echo "$STEP_NAME" | grep -o '[0-9]\{5,\}' | sort | uniq)
    
    # If no case ID found, generate a placeholder
    [ -z "$CASE_IDS" ] && CASE_IDS="unknown"

    # For each case ID, create a separate log file
    for CASE_ID in $CASE_IDS; do
        LOG_FILE="$OUTPUT_DIR/OCP-${CASE_ID}.log"
        PAGE=1
        > "$LOG_FILE"

        while :; do
            LOG_PAGE=$(curl -s -H "Authorization: bearer $TOKEN" \
                "$BASE_URL/api/v1/prow/log?filter.eq.item=$STEP_ID&page.page=$PAGE&page.size=5000")
            LOG_COUNT=$(echo "$LOG_PAGE" | jq -r '.content | length' 2>/dev/null || echo 0)
            [ "$LOG_COUNT" -eq 0 ] && break

            echo "$LOG_PAGE" | jq -r '.content[] | "[\(.logTime)] \(.level): \(.message)"' >> "$LOG_FILE"

            ((PAGE++))
            [ "$PAGE" -gt 10 ] && break
            [ "$LOG_COUNT" -lt 5000 ] && break
        done

        echo "Saved: $LOG_FILE"
        
        # Auto-filter if requested
        if [ "$FILTER_LOGS" = true ]; then
            ORIGINAL_SIZE=$(wc -l < "$LOG_FILE")
            if [ "$ORIGINAL_SIZE" -gt 200 ]; then
                echo "  Filtering large log ($ORIGINAL_SIZE lines)..."
                ./filter_logs.sh "$LOG_FILE" "${LOG_FILE%.log}_filtered.log"
                echo "  Filtered version: ${LOG_FILE%.log}_filtered.log"
            fi
        fi
    done
done < /tmp/failed_steps.txt

if [ "$FILTER_LOGS" = true ]; then
    echo "Complete! Original logs saved to: $OUTPUT_DIR"
    echo "Filtered logs (for analysis): $OUTPUT_DIR/*_filtered.log"
else
    echo "Complete! Logs saved to: $OUTPUT_DIR"
    echo "Tip: Use --filter flag to auto-reduce large logs by 90%+"
fi
