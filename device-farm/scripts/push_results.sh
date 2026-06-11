#!/bin/bash
# push_results.sh — Auto-push test results to the shared Git repo
# Usage: bash push_results.sh
# Expects: RUN_DIR, TESTER_NAME, DEVICE, TIMESTAMP as env vars or from tester.conf

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVICE_FARM_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="${REPO_ROOT:-$(dirname "$DEVICE_FARM_DIR")}"

# Load tester config if env vars not set
if [ -z "${TESTER_NAME:-}" ] && [ -f "$DEVICE_FARM_DIR/.config/tester.conf" ]; then
    source "$DEVICE_FARM_DIR/.config/tester.conf"
fi
TESTER_NAME="${TESTER_NAME:-unknown}"

# Validate inputs
if [ -z "${RUN_DIR:-}" ] || [ ! -d "${RUN_DIR:-}" ]; then
    echo "ERROR: RUN_DIR not set or does not exist."
    exit 1
fi

if [ -z "${DEVICE:-}" ]; then
    DEVICE=$(adb devices 2>/dev/null | grep -w "device$" | head -1 | awk '{print $1}')
fi

# Derive device folder name
MANUFACTURER=$(adb -s "$DEVICE" shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r\n' | tr ' ' '_')
MODEL=$(adb -s "$DEVICE" shell getprop ro.product.model 2>/dev/null | tr -d '\r\n' | tr ' ' '_')
ANDROID_VER=$(adb -s "$DEVICE" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r\n')
DEVICE_FOLDER="${MANUFACTURER}_${MODEL}_Android${ANDROID_VER}"

# Derive timestamp
TIMESTAMP="${TIMESTAMP:-$(basename "$RUN_DIR")}"

# Target path in Git repo
TARGET="$REPO_ROOT/results/$TESTER_NAME/$DEVICE_FOLDER/$TIMESTAMP"

echo ""
echo "============================================"
echo "  Pushing Results to Git"
echo "============================================"
echo "  Tester:  $TESTER_NAME"
echo "  Device:  $DEVICE_FOLDER"
echo "  Run:     $TIMESTAMP"
echo "  Target:  results/$TESTER_NAME/$DEVICE_FOLDER/$TIMESTAMP/"
echo ""

# Copy results (JSON + HTML only, not recordings)
mkdir -p "$TARGET"
cp "$RUN_DIR/device_info.json" "$TARGET/" 2>/dev/null || true
cp "$RUN_DIR/test_results.json" "$TARGET/" 2>/dev/null || true
cp "$RUN_DIR/report.html" "$TARGET/" 2>/dev/null || true
cp "$RUN_DIR/style.css" "$TARGET/" 2>/dev/null || true

# Git operations
cd "$REPO_ROOT"

# Check if we have a remote configured
if ! git remote -v 2>/dev/null | grep -q "origin"; then
    echo "WARNING: No Git remote configured. Results saved locally only."
    echo "  Run: git remote add origin <repo-url>"
    exit 0
fi

# Stage and commit
git add results/
git commit -m "Results: $TESTER_NAME / $DEVICE_FOLDER / $TIMESTAMP" 2>/dev/null || {
    echo "  No changes to commit."
    exit 0
}

# Push with rebase (handles concurrent pushes from other colleagues)
echo "  Pushing to remote..."
BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

if git pull --rebase origin "$BRANCH" 2>/dev/null && git push origin "$BRANCH" 2>/dev/null; then
    echo ""
    echo "  Results pushed successfully!"
    echo "  Path: results/$TESTER_NAME/$DEVICE_FOLDER/$TIMESTAMP/"
else
    echo ""
    echo "  Push failed. Retrying once..."
    sleep 2
    if git pull --rebase origin "$BRANCH" 2>/dev/null && git push origin "$BRANCH" 2>/dev/null; then
        echo "  Results pushed successfully on retry!"
    else
        echo ""
        echo "  WARNING: Auto-push failed. Your results are committed locally."
        echo "  To push manually, run:"
        echo "    cd $REPO_ROOT"
        echo "    git pull --rebase origin $BRANCH && git push origin $BRANCH"
    fi
fi
