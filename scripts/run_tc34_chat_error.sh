#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEVICE="emulator-5554"
APP_ID="org.digitalgreen.farmer.chat"

ENV_ARGS=(
  -e APP_ID="$APP_ID"
  -e LANGUAGE="English (Kenya)"
  -e LANGUAGE_CODE=en
  -e USER_NAME="Test Farmer"
  -e SHORT_NAME=TF
  -e WAIT_TIMEOUT=10000
  -e PHONE_NUMBER=7013733824
  -e OTP_CODE=1111
)

echo "================================================"
echo "  TC34 - Chat Error State with Retry"
echo "================================================"

# ── Step 1: Clean slate ──
echo "[1/7] Clearing app data and granting permissions..."
    adb -s "$DEVICE" shell settings put secure stylus_handwriting_enabled 0 2>/dev/null
    adb -s "$DEVICE" shell settings put secure show_stylus_handwriting_intro 0 2>/dev/null
adb -s "$DEVICE" shell pm clear "$APP_ID" > /dev/null 2>&1
adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS 2>/dev/null || true
adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true
adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION 2>/dev/null || true
adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.RECORD_AUDIO 2>/dev/null || true
adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.CAMERA 2>/dev/null || true
adb -s "$DEVICE" forward tcp:7001 tcp:7001 2>/dev/null || true

# ── Step 2: Ensure airplane mode is OFF for onboarding ──
adb -s "$DEVICE" shell cmd connectivity airplane-mode disable 2>/dev/null || true
sleep 2

# ── Step 3: Launch app and complete onboarding ──
echo "[2/7] Launching app and completing onboarding..."
adb -s "$DEVICE" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
sleep 3

if maestro --device "$DEVICE" test "${ENV_ARGS[@]}" \
    "$PROJECT_DIR/flows/home/34_chat_error_onboarding.yaml" 2>&1; then
    echo "  -> Onboarding completed, on home screen"
else
    echo "  -> FAILED: Could not complete onboarding"
    exit 1
fi

# ── Step 4: Enable airplane mode (kill network) ──
echo "[3/7] Enabling airplane mode (no internet)..."
adb -s "$DEVICE" shell cmd connectivity airplane-mode enable
sleep 3

# ── Step 5: Type question, send, assert error state ──
echo "[4/7] Sending chat question with no network..."
if maestro --device "$DEVICE" test "${ENV_ARGS[@]}" \
    "$PROJECT_DIR/flows/home/34_chat_error_offline.yaml" 2>&1; then
    echo "  -> Chat error state detected (chat_error_content + chat_error_retry_button)"
else
    echo "  -> FAILED: Chat error state not detected"
    adb -s "$DEVICE" shell cmd connectivity airplane-mode disable
    exit 1
fi

# ── Step 6: Restore network ──
echo "[5/7] Disabling airplane mode (restoring internet)..."
adb -s "$DEVICE" shell cmd connectivity airplane-mode disable
sleep 5

# ── Step 7: Tap retry and assert AI response ──
echo "[6/7] Tapping retry and waiting for AI response..."
if maestro --device "$DEVICE" test "${ENV_ARGS[@]}" \
    "$PROJECT_DIR/flows/home/34_chat_error_recovery.yaml" 2>&1; then
    echo ""
    echo "================================================"
    echo "  TC34 PASSED - Chat error retry works"
    echo "================================================"
    exit 0
else
    echo ""
    echo "================================================"
    echo "  TC34 FAILED - Chat error retry broken"
    echo "================================================"
    exit 1
fi
