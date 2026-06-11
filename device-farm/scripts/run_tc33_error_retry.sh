#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVICE_FARM_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$DEVICE_FARM_DIR")"
DEVICE="${DEVICE:-$(adb devices 2>/dev/null | grep -w 'device$' | head -1 | awk '{print $1}')}"
APP_ID="org.digitalgreen.farmer.chat"

ENV_ARGS=(
  -e APP_ID="$APP_ID"
  -e LANGUAGE="English (Kenya)"
  -e LANGUAGE_CODE=en
  -e USER_NAME="Test Farmer"
  -e SHORT_NAME=TF
  -e WAIT_TIMEOUT=10000
)

echo "=========================================="
echo "  TC33 - Error Screen / Try Again Recovery"
echo "=========================================="

# ── Phase 0: Clean slate ──
echo "[1/6] Clearing app data and granting permissions..."
adb -s "$DEVICE" shell "
    settings put secure stylus_handwriting_enabled 0;
    settings put secure show_stylus_handwriting_intro 0;
    pm clear $APP_ID;
    pm grant $APP_ID android.permission.POST_NOTIFICATIONS;
    pm grant $APP_ID android.permission.ACCESS_FINE_LOCATION;
    pm grant $APP_ID android.permission.ACCESS_COARSE_LOCATION;
    pm grant $APP_ID android.permission.RECORD_AUDIO;
    pm grant $APP_ID android.permission.CAMERA" 2>/dev/null

# ── Phase 1: Enable airplane mode (kill network) ──
echo "[2/6] Enabling airplane mode (no internet)..."
adb -s "$DEVICE" shell cmd connectivity airplane-mode enable
sleep 2

# ── Phase 2: Launch app with no network ──
echo "[3/6] Launching app with no connectivity..."
adb -s "$DEVICE" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
sleep 5

# ── Phase 3: Assert error screen ──
echo "[4/6] Asserting error screen appears..."
if maestro --device "$DEVICE" test "${ENV_ARGS[@]}" \
    "$PROJECT_DIR/flows/home/33_error_screen_assert.yaml" 2>&1; then
    echo "  -> Phase 1 PASSED: Error screen detected"
else
    echo "  -> Phase 1 FAILED: Error screen not detected"
    adb -s "$DEVICE" shell cmd connectivity airplane-mode disable
    exit 1
fi

# ── Phase 4: Restore network ──
echo "[5/6] Disabling airplane mode (restoring internet)..."
adb -s "$DEVICE" shell cmd connectivity airplane-mode disable
sleep 5

# ── Phase 5: Tap retry and assert recovery ──
echo "[6/6] Tapping retry and asserting recovery..."
if maestro --device "$DEVICE" test "${ENV_ARGS[@]}" \
    "$PROJECT_DIR/flows/home/33_error_screen_retry.yaml" 2>&1; then
    echo ""
    echo "=========================================="
    echo "  TC33 PASSED - Error retry recovery works"
    echo "=========================================="
    exit 0
else
    echo ""
    echo "=========================================="
    echo "  TC33 FAILED - Retry recovery broken"
    echo "=========================================="
    exit 1
fi
