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
  -e PHONE_NUMBER=7013733824
  -e OTP_CODE=1111
)

echo "================================================"
echo "  TC35 - Chat History Retry"
echo "================================================"

echo "[1/7] Clearing app data and granting permissions..."
adb -s "$DEVICE" shell settings put secure stylus_handwriting_enabled 0 2>/dev/null
adb -s "$DEVICE" shell settings put secure show_stylus_handwriting_intro 0 2>/dev/null
adb -s "$DEVICE" shell pm clear "$APP_ID" > /dev/null 2>&1
adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS 2>/dev/null || true
adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true
adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION 2>/dev/null || true
adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.RECORD_AUDIO 2>/dev/null || true
adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.CAMERA 2>/dev/null || true

adb -s "$DEVICE" shell cmd connectivity airplane-mode disable 2>/dev/null || true
sleep 2

echo "[2/7] Onboarding + login + ask question..."
adb -s "$DEVICE" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
sleep 3

if maestro --device "$DEVICE" test "${ENV_ARGS[@]}" \
    "$PROJECT_DIR/flows/home/35_chat_history_retry_setup.yaml" 2>&1; then
    echo "  -> Logged in, chat history created, on home"
else
    echo "  -> FAILED: Could not complete setup"
    exit 1
fi

echo "[3/7] Enabling airplane mode..."
adb -s "$DEVICE" shell cmd connectivity airplane-mode enable
sleep 3

echo "[4/7] Navigating to Chat History (offline) - assert error screen..."
if maestro --device "$DEVICE" test "${ENV_ARGS[@]}" \
    "$PROJECT_DIR/flows/home/35_chat_history_retry_assert.yaml" 2>&1; then
    echo "  -> Error screen detected"
else
    echo "  -> FAILED: Error screen not detected"
    adb -s "$DEVICE" shell cmd connectivity airplane-mode disable
    exit 1
fi

echo "[5/7] Disabling airplane mode (restoring internet)..."
adb -s "$DEVICE" shell cmd connectivity airplane-mode disable
sleep 5

echo "[6/7] Tapping Try again and verifying chat history..."
if maestro --device "$DEVICE" test "${ENV_ARGS[@]}" \
    "$PROJECT_DIR/flows/home/35_chat_history_retry_recovery.yaml" 2>&1; then
    echo ""
    echo "================================================"
    echo "  TC35 PASSED - Chat history retry works"
    echo "================================================"
    exit 0
else
    echo ""
    echo "================================================"
    echo "  TC35 FAILED - Chat history retry broken"
    echo "================================================"
    exit 1
fi
