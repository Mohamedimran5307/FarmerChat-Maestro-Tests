#!/bin/bash
# run.sh — FarmerChat DeviceFarm entry point
# One command to run all tests and push results.
# Usage: cd device-farm && bash run.sh
set -uo pipefail

DEVICE_FARM_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$DEVICE_FARM_DIR")"

# ── Check tester config ──
if [ ! -f "$DEVICE_FARM_DIR/.config/tester.conf" ]; then
    echo "ERROR: Tester not configured."
    echo "  Run 'bash setup.sh' first to set up your environment."
    exit 1
fi
source "$DEVICE_FARM_DIR/.config/tester.conf"

# ── Detect USB device ──
DEVICE=$(adb devices 2>/dev/null | grep -w "device$" | head -1 | awk '{print $1}')
if [ -z "$DEVICE" ]; then
    echo "ERROR: No Android device connected via USB."
    echo ""
    echo "  Checklist:"
    echo "    1. Connect your device via USB cable"
    echo "    2. Enable USB debugging (Settings > Developer Options)"
    echo "    3. Tap 'Allow' on the USB debugging prompt on your phone"
    echo "    4. Run 'adb devices' to verify"
    echo ""
    exit 1
fi

MANUFACTURER=$(adb -s "$DEVICE" shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r\n')
MODEL=$(adb -s "$DEVICE" shell getprop ro.product.model 2>/dev/null | tr -d '\r\n')
ANDROID_VER=$(adb -s "$DEVICE" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r\n')

echo ""
echo "============================================"
echo "  FarmerChat DeviceFarm"
echo "============================================"
echo "  Tester:  $TESTER_NAME"
echo "  Device:  $MANUFACTURER $MODEL (Android $ANDROID_VER)"
echo "  Serial:  $DEVICE"
echo "============================================"
echo ""

# ── Run all tests ──
export DEVICE TESTER_NAME DEVICE_FARM_DIR REPO_ROOT
bash "$DEVICE_FARM_DIR/scripts/run_tests.sh"

# ── Push results to Git ──
bash "$DEVICE_FARM_DIR/scripts/push_results.sh"

echo ""
echo "Done! Your results have been saved and pushed."
