#!/bin/bash

# Log pre-filtering script - Extract key error information, reduce 95% processing load
# Usage: ./filter_logs.sh <log_file> [output_file]

set -e

LOG_FILE="$1"
OUTPUT_FILE="${2:-${LOG_FILE%.log}_filtered.log}"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "Usage: $0 <log_file> [output_file]"
    echo "Example: $0 failed_cases_761135/logs/OCP-28867.log"
    exit 1
fi

echo "Filtering log: $(basename "$LOG_FILE")"
ORIGINAL_LINES=$(wc -l < "$LOG_FILE")
echo "Original size: $ORIGINAL_LINES lines, $(du -h "$LOG_FILE" | cut -f1)"

# Create filtered log file
{
    echo "# Filtered log: $(basename "$LOG_FILE")"
    echo "# Original size: $ORIGINAL_LINES lines, $(du -h "$LOG_FILE" | cut -f1)"
    echo "# Filter time: $(date)"
    echo "# Filter strategy: First 50 lines + Key errors + Last 50 lines"
    echo ""
    
    echo "=== Start Information (First 50 lines) ==="
    head -50 "$LOG_FILE"
    
    echo ""
    echo "=== Key Error Information ==="
    grep -i "error\|fail\|panic\|exception\|unexpected\|timeout" "$LOG_FILE" | head -30
    
    echo ""
    echo "=== End Information (Last 50 lines) ==="
    tail -50 "$LOG_FILE"
    
} > "$OUTPUT_FILE"

FILTERED_LINES=$(wc -l < "$OUTPUT_FILE")
COMPRESSION_RATIO=$(echo "scale=1; ($ORIGINAL_LINES - $FILTERED_LINES) * 100 / $ORIGINAL_LINES" | bc)

echo "Filtering completed:"
echo "  Original: $ORIGINAL_LINES lines"
echo "  Filtered: $FILTERED_LINES lines"
echo "  Compression: ${COMPRESSION_RATIO}%"
echo "  Output: $OUTPUT_FILE"
echo "  Size: $(du -h "$OUTPUT_FILE" | cut -f1)"