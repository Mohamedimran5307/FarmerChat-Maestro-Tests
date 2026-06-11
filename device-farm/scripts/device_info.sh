#!/bin/bash
# device_info.sh — Captures physical device metadata as JSON
# Usage: bash device_info.sh <DEVICE_SERIAL> <OUTPUT_DIR> [TESTER_NAME]

set -uo pipefail

DEVICE="${1:?Usage: device_info.sh <DEVICE_SERIAL> <OUTPUT_DIR> [TESTER_NAME]}"
OUTPUT_DIR="${2:?Usage: device_info.sh <DEVICE_SERIAL> <OUTPUT_DIR> [TESTER_NAME]}"
TESTER_NAME="${3:-unknown}"
APP_ID="org.digitalgreen.farmer.chat"

# Helper: get device property, strip carriage returns
getprop() {
    adb -s "$DEVICE" shell getprop "$1" 2>/dev/null | tr -d '\r\n'
}

# Gather device properties
MANUFACTURER=$(getprop ro.product.manufacturer)
MODEL=$(getprop ro.product.model)
ANDROID_VER=$(getprop ro.build.version.release)
API_LEVEL=$(getprop ro.build.version.sdk)
DEVICE_CODE=$(getprop ro.product.device)
BUILD_ID=$(getprop ro.build.display.id)

# Screen info
SCREEN_SIZE=$(adb -s "$DEVICE" shell wm size 2>/dev/null | grep "Physical" | sed 's/Physical size: //' | tr -d '\r\n')
if [ -z "$SCREEN_SIZE" ]; then
    SCREEN_SIZE=$(adb -s "$DEVICE" shell wm size 2>/dev/null | grep "Override" | sed 's/Override size: //' | tr -d '\r\n')
fi
SCREEN_DENSITY=$(adb -s "$DEVICE" shell wm density 2>/dev/null | grep "Physical" | sed 's/Physical density: //' | tr -d '\r\n')
if [ -z "$SCREEN_DENSITY" ]; then
    SCREEN_DENSITY=$(adb -s "$DEVICE" shell wm density 2>/dev/null | grep "Override" | sed 's/Override density: //' | tr -d '\r\n')
fi

# RAM (convert KB to GB)
RAM_KB=$(adb -s "$DEVICE" shell cat /proc/meminfo 2>/dev/null | grep MemTotal | awk '{print $2}' | tr -d '\r\n')
if [ -n "$RAM_KB" ] && [ "$RAM_KB" -gt 0 ] 2>/dev/null; then
    RAM_GB=$(awk "BEGIN {printf \"%.1f\", $RAM_KB / 1048576}")
else
    RAM_GB="N/A"
fi

# Battery
BATTERY_LEVEL=$(adb -s "$DEVICE" shell dumpsys battery 2>/dev/null | grep "level:" | awk '{print $2}' | tr -d '\r\n')

# Maestro version
MAESTRO_VER=$(maestro --version 2>&1 | head -1 | tr -d '\r\n' || echo "N/A")

# APK version
APK_VERSION=$(adb -s "$DEVICE" shell dumpsys package "$APP_ID" 2>/dev/null | grep "versionName" | head -1 | sed 's/.*versionName=//' | tr -d '\r\n' || echo "N/A")

# Timestamp
TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')

# Write JSON
mkdir -p "$OUTPUT_DIR"
cat > "$OUTPUT_DIR/device_info.json" << JSONEOF
{
  "tester": "$TESTER_NAME",
  "serial": "$DEVICE",
  "manufacturer": "$MANUFACTURER",
  "model": "$MODEL",
  "device_codename": "$DEVICE_CODE",
  "android_version": "$ANDROID_VER",
  "api_level": $API_LEVEL,
  "build_id": "$BUILD_ID",
  "screen_resolution": "$SCREEN_SIZE",
  "screen_density": "${SCREEN_DENSITY}dpi",
  "ram_gb": "$RAM_GB",
  "battery_level": ${BATTERY_LEVEL:-0},
  "apk_version": "$APK_VERSION",
  "maestro_version": "$MAESTRO_VER",
  "timestamp": "$TIMESTAMP"
}
JSONEOF

echo "  Device info saved: $OUTPUT_DIR/device_info.json"
