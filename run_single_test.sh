#!/bin/bash

# Usage: ./run_single_test.sh <flow_file>
# Example: ./run_single_test.sh flows/home/07_home_screen_verification.yaml

if [ -z "$1" ]; then
    echo "Usage: ./run_single_test.sh <flow_file>"
    echo ""
    echo "Available flows:"
    find flows -name "*.yaml" | sort
    exit 1
fi

FLOW_FILE="$1"
DEVICE="emulator-5554"
APP_ID="org.digitalgreen.farmer.chat"

if [ ! -f "$FLOW_FILE" ]; then
    echo "Error: File '$FLOW_FILE' not found"
    exit 1
fi

echo "=== Resetting app to fresh state ==="
adb -s "$DEVICE" shell pm clear "$APP_ID" > /dev/null 2>&1
adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS > /dev/null 2>&1
adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION > /dev/null 2>&1
adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION > /dev/null 2>&1
adb -s "$DEVICE" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
echo "Waiting 3s for app to load..."
sleep 3

echo "=== Running: $FLOW_FILE ==="
maestro test \
    -e APP_ID="$APP_ID" \
    -e LANGUAGE="English (Kenya)" \
    -e LANGUAGE_CODE=en \
    -e USER_NAME="Test Farmer" \
    -e SHORT_NAME=TF \
    -e WAIT_TIMEOUT=10000 \
    "$FLOW_FILE"

echo ""
echo "=== Done ==="
