#!/bin/bash
# setup.sh — One-time setup for FarmerChat DeviceFarm
# Installs dependencies, detects device, configures tester identity.
# Usage: cd device-farm && bash setup.sh
set -uo pipefail

DEVICE_FARM_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$DEVICE_FARM_DIR")"
APP_ID="org.digitalgreen.farmer.chat"
ACTIVITY="org.digitalgreen.farmer.chatbot.MainActivity"
DUPLICATE_ACTIVITY=".MainActivity"

echo ""
echo "============================================"
echo "  FarmerChat DeviceFarm — Setup"
echo "============================================"
echo ""

# ── Step 1: Check macOS ──
echo "[1/8] Checking platform..."
if [[ "$(uname)" != "Darwin" ]]; then
    echo "  ERROR: This project is designed for macOS."
    echo "  Your OS: $(uname)"
    exit 1
fi
echo "  macOS detected."

# ── Step 2: Check/install ADB ──
echo "[2/8] Checking ADB..."
if ! command -v adb &>/dev/null; then
    echo "  ADB not found. Installing Android platform-tools..."
    if command -v brew &>/dev/null; then
        brew install --cask android-platform-tools
    else
        echo ""
        echo "  Homebrew not found. Please install ADB manually:"
        echo "    Option A: Install Homebrew first:"
        echo "      /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo "      brew install --cask android-platform-tools"
        echo "    Option B: Download from Google:"
        echo "      https://developer.android.com/tools/releases/platform-tools"
        echo ""
        exit 1
    fi
fi
ADB_VER=$(adb --version 2>&1 | head -1)
echo "  $ADB_VER"

# ── Step 3: Check/install Maestro ──
echo "[3/8] Checking Maestro CLI..."
if ! command -v maestro &>/dev/null; then
    echo "  Maestro not found. Installing..."
    curl -Ls "https://get.maestro.mobile.dev" | bash
    export PATH="$HOME/.maestro/bin:$PATH"

    if ! command -v maestro &>/dev/null; then
        echo ""
        echo "  Maestro installed but not in PATH. Add this to your shell profile:"
        echo "    export PATH=\"\$HOME/.maestro/bin:\$PATH\""
        echo "  Then restart your terminal and run setup.sh again."
        exit 1
    fi
fi
MAESTRO_VER=$(maestro --version 2>&1 | head -1)
echo "  Maestro: $MAESTRO_VER"

# ── Step 4: Detect USB device ──
echo "[4/8] Detecting Android device..."
DEVICE=$(adb devices 2>/dev/null | grep -w "device$" | head -1 | awk '{print $1}')
if [ -z "$DEVICE" ]; then
    echo ""
    echo "  No Android device detected!"
    echo ""
    echo "  To connect your device:"
    echo "    1. Go to Settings > About Phone"
    echo "    2. Tap 'Build Number' 7 times to enable Developer Options"
    echo "    3. Go to Settings > Developer Options"
    echo "    4. Enable 'USB Debugging'"
    echo "    5. Connect your device via USB cable"
    echo "    6. Tap 'Allow' on the USB debugging prompt"
    echo "    7. Run 'bash setup.sh' again"
    echo ""
    exit 1
fi

MANUFACTURER=$(adb -s "$DEVICE" shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r\n')
MODEL=$(adb -s "$DEVICE" shell getprop ro.product.model 2>/dev/null | tr -d '\r\n')
ANDROID_VER=$(adb -s "$DEVICE" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r\n')
API_LEVEL=$(adb -s "$DEVICE" shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r\n')
echo "  Found: $MANUFACTURER $MODEL (Android $ANDROID_VER, API $API_LEVEL)"
echo "  Serial: $DEVICE"

# ── Step 5: Check FarmerChat APK ──
echo "[5/8] Checking FarmerChat app..."
if adb -s "$DEVICE" shell pm list packages 2>/dev/null | grep -q "$APP_ID"; then
    APK_VER=$(adb -s "$DEVICE" shell dumpsys package "$APP_ID" 2>/dev/null | grep "versionName" | head -1 | sed 's/.*versionName=//' | tr -d '\r\n')
    echo "  FarmerChat already installed (v$APK_VER)"
elif [ -f "$REPO_ROOT/app.apk" ]; then
    echo "  Installing FarmerChat APK from repo root..."
    adb -s "$DEVICE" install -r "$REPO_ROOT/app.apk"
    echo "  APK installed."
else
    echo ""
    echo "  FarmerChat is NOT installed and no APK found."
    echo "  Please install FarmerChat on the device manually."
    echo "  Then run setup.sh again."
    exit 1
fi

# ── Step 6: Grant permissions & configure device ──
echo "[6/8] Configuring device..."
adb -s "$DEVICE" shell "
    pm grant $APP_ID android.permission.POST_NOTIFICATIONS;
    pm grant $APP_ID android.permission.ACCESS_FINE_LOCATION;
    pm grant $APP_ID android.permission.ACCESS_COARSE_LOCATION;
    pm grant $APP_ID android.permission.RECORD_AUDIO;
    pm grant $APP_ID android.permission.CAMERA;
    settings put secure stylus_handwriting_enabled 0;
    settings put secure show_stylus_handwriting_intro 0" 2>/dev/null

# Disable duplicate launcher activity (APK v4.0.0 bug)
adb -s "$DEVICE" shell "pm disable $APP_ID/$DUPLICATE_ACTIVITY" 2>/dev/null || true

# Push gallery test image
if [ -f "$REPO_ROOT/assets/test_crop_disease.png" ]; then
    adb -s "$DEVICE" shell mkdir -p /sdcard/DCIM/Camera 2>/dev/null || true
    adb -s "$DEVICE" push "$REPO_ROOT/assets/test_crop_disease.png" \
        /sdcard/DCIM/Camera/IMG_20260101_120000.png > /dev/null 2>&1
    adb -s "$DEVICE" shell "am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
        -d file:///sdcard/DCIM/Camera/IMG_20260101_120000.png" > /dev/null 2>&1
fi
echo "  Permissions granted, device configured."

# ── Step 7: Create tester config ──
echo "[7/8] Setting up tester identity..."
mkdir -p "$DEVICE_FARM_DIR/.config"

if [ -f "$DEVICE_FARM_DIR/.config/tester.conf" ]; then
    source "$DEVICE_FARM_DIR/.config/tester.conf"
    echo "  Already configured as: $TESTER_NAME"
    read -rp "  Keep this name? (Y/n): " keep
    if [[ "$keep" =~ ^[Nn] ]]; then
        read -rp "  Enter your name (e.g., Imran): " NEW_NAME
        TESTER_NAME=$(echo "$NEW_NAME" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
        echo "TESTER_NAME=\"$TESTER_NAME\"" > "$DEVICE_FARM_DIR/.config/tester.conf"
        echo "  Updated to: $TESTER_NAME"
    fi
else
    read -rp "  Enter your name (e.g., Imran): " NEW_NAME
    TESTER_NAME=$(echo "$NEW_NAME" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
    echo "TESTER_NAME=\"$TESTER_NAME\"" > "$DEVICE_FARM_DIR/.config/tester.conf"
    echo "  Configured as: $TESTER_NAME"
fi

# ── Step 8: Verify Git ──
echo "[8/8] Verifying Git connection..."
if git -C "$REPO_ROOT" remote -v 2>/dev/null | grep -q "origin"; then
    REMOTE_URL=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null)
    echo "  Remote: $REMOTE_URL"
    if git -C "$REPO_ROOT" fetch origin 2>/dev/null; then
        echo "  Git connection OK."
    else
        echo "  WARNING: Cannot reach Git remote. Results push may fail."
        echo "  Ensure you have access to the repository."
    fi
else
    echo "  WARNING: No Git remote configured."
    echo "  Results will be saved locally only."
fi

# ── Summary ──
echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo "  Tester:       $TESTER_NAME"
echo "  Device:       $MANUFACTURER $MODEL"
echo "  Android:      $ANDROID_VER (API $API_LEVEL)"
echo "  Serial:       $DEVICE"
echo "  Maestro:      $MAESTRO_VER"
echo ""
echo "  To run tests: bash run.sh"
echo "============================================"
echo ""
