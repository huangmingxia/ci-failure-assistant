#!/bin/bash

# ==============================================
# Simple Configuration Check Script (macOS + Bash 3/4 compatible)
# Usage: ./check_config.sh
# ==============================================

echo "Configuration Check"
echo "=================="

# --- Dependencies ---
echo ""
echo "Dependencies:"
if command -v jq &> /dev/null; then
    echo "  OK: jq installed"
else
    echo "  WARN: jq not installed"
fi

if command -v curl &> /dev/null; then
    echo "  OK: curl installed"
else
    echo "  ERROR: curl not installed"
fi

# --- .env File ---
echo ""
echo "Environment Configuration:"
if [ -f ".env" ]; then
    echo "  OK: .env file found"

    # Load environment variables safely
    set -o allexport
    source .env
    set +o allexport

    echo ""
    echo "Configuration Status:"

    # List of required variables
    REQUIRED_VARS=("REPORTPORTAL_BASE_URL" "REPORTPORTAL_TOKEN")
    OPTIONAL_VARS=("LAUNCH_ID" "TEST_SUITE" "E2E_CODE_PATH" "UPSTREAM_REPO_NAME")

    # Check required
    for var in "${REQUIRED_VARS[@]}"; do
        if [ -n "${!var}" ]; then
            if [ "$var" = "REPORTPORTAL_TOKEN" ]; then
                echo "  OK: $var is set (*** hidden ***)"
            else
                echo "  OK: $var = ${!var}"
            fi
        else
            echo "  ERROR: $var is not set"
        fi
    done

    # Check optional
    for var in "${OPTIONAL_VARS[@]}"; do
        if [ -n "${!var}" ]; then
            echo "  OK: $var = ${!var}"
        else
            echo "  WARN: $var is not set"
        fi
    done

else
    echo "  ERROR: .env file not found"
    echo "  Please create it from template:"
    echo "    cp .env.example .env"
fi

# --- Configuration Files ---
echo ""
echo "Configuration Files:"
if [ -f "config/.analyze_config.json" ]; then
    echo "  OK: config/.analyze_config.json found"
else
    echo "  WARN: config/.analyze_config.json not found"
fi

# --- Quick Commands ---
echo ""
echo "Quick Commands:"
echo "1. Copy environment template: cp .env.example .env"
echo "2. Edit configuration: nano .env (or vi .env)"
echo "3. Get logs: source .env && ./get_logs.sh \$LAUNCH_ID \"\$REPORTPORTAL_TOKEN\""

echo ""
echo "Configuration check completed!"
