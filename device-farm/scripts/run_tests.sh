#!/bin/bash
# run_tests.sh — Core test engine for FarmerChat DeviceFarm
# Runs all 40 Maestro test cases on a physical device connected via USB.
# Adapted from FarmerChat_Genymotion/scripts/run_single_device.sh
# All Genymotion Cloud / tunnel / gRPC code has been stripped.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVICE_FARM_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$DEVICE_FARM_DIR")"
PROJECT_DIR="$REPO_ROOT"
REPORT_DIR="$DEVICE_FARM_DIR/reports"
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
RUN_DIR="${REPORT_SUBDIR:-$REPORT_DIR/$TIMESTAMP}"
export MAESTRO_DRIVER_STARTUP_TIMEOUT=180000
APP_ID="org.digitalgreen.farmer.chat"
ACTIVITY="org.digitalgreen.farmer.chatbot.MainActivity"
DUPLICATE_ACTIVITY=".MainActivity"
START_TIME=$(date +%s)

TESTER_NAME="${TESTER_NAME:-unknown}"
SKIP_RECORDING="${SKIP_RECORDING:-false}"

# Auto-detect device if not set
if [ -z "${DEVICE:-}" ]; then
    DEVICE=$(adb devices 2>/dev/null | grep -w "device$" | head -1 | awk '{print $1}')
    if [ -z "$DEVICE" ]; then
        echo "ERROR: No Android device connected via USB."
        echo "  Connect a device and enable USB debugging."
        exit 1
    fi
fi

RECORDINGS_DIR="$RUN_DIR/recordings"
mkdir -p "$RUN_DIR" "$RECORDINGS_DIR"

echo "============================================"
echo "  FarmerChat DeviceFarm — Test Suite"
echo "  Tester:    $TESTER_NAME"
echo "  Run:       $TIMESTAMP"
echo "  Device:    $DEVICE"
echo "  Recording: $([ "$SKIP_RECORDING" = "true" ] && echo "DISABLED" || echo "ENABLED")"
echo "============================================"

# Disable duplicate launcher activity (APK v4.0.0 bug)
adb -s "$DEVICE" shell "pm disable $APP_ID/$DUPLICATE_ACTIVITY" > /dev/null 2>&1 || true
resolved=$(adb -s "$DEVICE" shell "cmd package resolve-activity --brief $APP_ID" 2>/dev/null | tail -1 | tr -d '\r')
echo "  Launcher: $resolved"
echo ""

# ── Counters & Result Arrays ──
TOTAL=0
PASSED=0
FAILED=0
declare -a R_STATUS R_TCNAME R_LOGFILE R_DURATION R_VIDEO R_PREP_TIME R_TEST_TIME

# ── Screen Recording ──
start_recording() {
    [ "$SKIP_RECORDING" = "true" ] && return
    adb -s "$DEVICE" shell "rm -f /sdcard/test_recording.mp4; nohup screenrecord --time-limit 180 /sdcard/test_recording.mp4 < /dev/null > /dev/null 2>&1 &" 2>/dev/null
}

stop_recording() {
    [ "$SKIP_RECORDING" = "true" ] && echo "" && return
    local safe_name
    safe_name=$(echo "$1" | sed 's/[^a-zA-Z0-9_-]/_/g')
    adb -s "$DEVICE" shell "kill -2 \$(pidof screenrecord)" 2>/dev/null || true
    sleep 2
    adb -s "$DEVICE" pull /sdcard/test_recording.mp4 "$RECORDINGS_DIR/${safe_name}.mp4" > /dev/null 2>&1
    adb -s "$DEVICE" shell rm -f /sdcard/test_recording.mp4 2>/dev/null
    if [ -f "$RECORDINGS_DIR/${safe_name}.mp4" ]; then
        local fsize
        fsize=$(wc -c < "$RECORDINGS_DIR/${safe_name}.mp4" | tr -d ' ')
        if [ "$fsize" -gt 10000 ]; then
            echo "recordings/${safe_name}.mp4"
            return
        fi
        rm -f "$RECORDINGS_DIR/${safe_name}.mp4"
    fi
    echo ""
}

# ── Environment Variables for Maestro ──
ENV_ARGS=(
  -e APP_ID="$APP_ID"
  -e LANGUAGE="English (Kenya)"
  -e LANGUAGE_CODE=en
  -e USER_NAME="Test Farmer"
  -e SHORT_NAME=TF
  -e WAIT_TIMEOUT=30000
  -e PHONE_NUMBER=7013733824
  -e NEW_PHONE_NUMBER="777766666"
  -e OTP_CODE=1111
)

# ── Gallery Setup ──
ensure_gallery_photo() {
    local TEST_IMG="$PROJECT_DIR/assets/test_crop_disease.png"
    if [ ! -f "$TEST_IMG" ]; then
        echo "  Gallery image not found, skipping."
        return
    fi
    echo "  Pushing crop disease test image to gallery..."
    adb -s "$DEVICE" shell mkdir -p /sdcard/DCIM/Camera 2>/dev/null || true
    adb -s "$DEVICE" push "$TEST_IMG" /sdcard/DCIM/Camera/IMG_20260101_120000.png > /dev/null 2>&1 &
    local PUSH_PID=$!
    local waited=0
    while kill -0 $PUSH_PID 2>/dev/null && [ $waited -lt 30 ]; do
        sleep 2
        waited=$((waited + 2))
    done
    if kill -0 $PUSH_PID 2>/dev/null; then
        kill $PUSH_PID 2>/dev/null || true
        echo "  Gallery push timed out (30s), skipping."
        return
    fi
    adb -s "$DEVICE" shell "am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/DCIM/Camera/IMG_20260101_120000.png" > /dev/null 2>&1
    echo "  Gallery ready."
}

# ── FRESH vs WARM Mode Logic ──
FRESH_STATE_FLOWS="01_language_screen|02_language_selection|03_skip_name|04_enter_name|29_legal_terms_of_use|30_legal_privacy_policy|38_legal_dialog_close"
ONBOARDING_DONE=false

prepare_fresh() {
    local prep_start=$(date +%s)
    echo "  [prep] FRESH mode (pm clear + cold start)"

    adb -s "$DEVICE" shell "input keyevent KEYCODE_WAKEUP; wm dismiss-keyguard; input keyevent KEYCODE_HOME" 2>/dev/null
    sleep 1

    adb -s "$DEVICE" shell "
        settings put secure stylus_handwriting_enabled 0;
        settings put secure show_stylus_handwriting_intro 0;
        am force-stop $APP_ID;
        pm clear $APP_ID;
        pm grant $APP_ID android.permission.POST_NOTIFICATIONS;
        pm grant $APP_ID android.permission.ACCESS_FINE_LOCATION;
        pm grant $APP_ID android.permission.ACCESS_COARSE_LOCATION;
        pm grant $APP_ID android.permission.RECORD_AUDIO;
        pm grant $APP_ID android.permission.CAMERA;
        pm disable $APP_ID/$DUPLICATE_ACTIVITY" 2>/dev/null

    adb -s "$DEVICE" shell "am start -W -n $APP_ID/$ACTIVITY" > /dev/null 2>&1
    sleep 5

    local focused_app
    focused_app=$(adb -s "$DEVICE" shell "dumpsys activity activities 2>/dev/null | grep mFocusedApp" 2>/dev/null || true)
    if ! echo "$focused_app" | grep -q "$APP_ID"; then
        echo "  [retry] App not focused, relaunching..."
        adb -s "$DEVICE" shell "am force-stop $APP_ID; sleep 1; am start -W -n $APP_ID/$ACTIVITY" > /dev/null 2>&1
        sleep 5
    fi

    ONBOARDING_DONE=false

    local prep_end=$(date +%s)
    LAST_PREP_TIME=$((prep_end - prep_start))
}

prepare_warm() {
    local prep_start=$(date +%s)
    echo "  [prep] WARM mode (force-stop + relaunch, data preserved)"

    adb -s "$DEVICE" shell "input keyevent KEYCODE_WAKEUP; wm dismiss-keyguard" 2>/dev/null
    adb -s "$DEVICE" shell "am force-stop $APP_ID" 2>/dev/null
    sleep 1
    adb -s "$DEVICE" shell "am start -W -n $APP_ID/$ACTIVITY" > /dev/null 2>&1
    sleep 3

    local focused_app
    focused_app=$(adb -s "$DEVICE" shell "dumpsys activity activities 2>/dev/null | grep mFocusedApp" 2>/dev/null || true)
    if ! echo "$focused_app" | grep -q "$APP_ID"; then
        echo "  [retry] App not focused, relaunching..."
        adb -s "$DEVICE" shell "am start -W -n $APP_ID/$ACTIVITY" > /dev/null 2>&1
        sleep 3
    fi

    local prep_end=$(date +%s)
    LAST_PREP_TIME=$((prep_end - prep_start))
}

do_initial_onboarding() {
    if $ONBOARDING_DONE; then
        return 0
    fi
    echo "  [setup] Running initial onboarding (one-time)..."

    if maestro --device "$DEVICE" test "${ENV_ARGS[@]}" \
        "$PROJECT_DIR/helpers/complete_onboarding.yaml" > /dev/null 2>&1; then
        ONBOARDING_DONE=true
        echo "  [setup] Onboarding complete — home screen ready"
    else
        echo "  [setup] WARNING: Initial onboarding failed, tests may fail"
    fi
}

prepare_device() {
    local flow_basename="$1"
    if echo "$flow_basename" | grep -qE "$FRESH_STATE_FLOWS"; then
        prepare_fresh
    else
        if ! $ONBOARDING_DONE; then
            prepare_fresh
            do_initial_onboarding
        else
            prepare_warm
        fi
    fi
}

# ── Run a Single Maestro Flow ──
run_flow() {
    local flow_file="$1"
    local flow_basename
    flow_basename=$(basename "$flow_file" .yaml)
    local test_name
    test_name=$(grep -m1 "^name:" "$flow_file" 2>/dev/null | sed 's/^name: *//' | tr -d '"' || echo "$flow_basename")
    local log_file="$RUN_DIR/${test_name}.log"
    local tc_start=$(date +%s)
    TOTAL=$((TOTAL + 1))

    echo ""
    echo "--- [$TOTAL] $test_name ---"

    LAST_PREP_TIME=0
    prepare_device "$flow_basename"
    start_recording

    local test_start=$(date +%s)

    # Run Maestro with single retry (no cloud tunnel recovery needed on physical USB)
    local maestro_ok=false
    if maestro --device "$DEVICE" test "${ENV_ARGS[@]}" "$flow_file" \
        > "$log_file" 2>&1; then
        maestro_ok=true
    else
        echo "  [retry] First attempt failed, retrying once..."
        sleep 3
        if maestro --device "$DEVICE" test "${ENV_ARGS[@]}" "$flow_file" \
            > "$log_file" 2>&1; then
            maestro_ok=true
        fi
    fi

    if $maestro_ok; then
        PASSED=$((PASSED + 1))
        STATUS="PASSED"
    else
        FAILED=$((FAILED + 1))
        STATUS="FAILED"
        echo "  [FAILURE REASON]"
        grep -E "Assert.*FAILED|visible.*FAILED|TimeoutException|java\.io\.EOF" "$log_file" 2>/dev/null | head -5 | sed 's/^/    /'
        if ! grep -qE "Assert.*FAILED|visible.*FAILED|TimeoutException" "$log_file" 2>/dev/null; then
            tail -5 "$log_file" 2>/dev/null | sed 's/^/    /'
        fi
    fi

    local test_end=$(date +%s)
    local test_only=$((test_end - test_start))

    local video_path
    video_path=$(stop_recording "$test_name")

    local tc_end=$(date +%s)
    local duration=$((tc_end - tc_start))
    echo "  $STATUS (${duration}s total | prep:${LAST_PREP_TIME}s | test:${test_only}s)"

    R_STATUS+=("$STATUS")
    R_TCNAME+=("$test_name")
    R_LOGFILE+=("${test_name}.log")
    R_DURATION+=("${duration}s")
    R_VIDEO+=("$video_path")
    R_PREP_TIME+=("${LAST_PREP_TIME}s")
    R_TEST_TIME+=("${test_only}s")
}

# ── Run Network Error Test (airplane mode toggle) ──
run_network_test() {
    local script_file="$1"
    local test_name="$2"
    local log_file="$RUN_DIR/${test_name}.log"
    local tc_start=$(date +%s)
    TOTAL=$((TOTAL + 1))

    echo ""
    echo "--- [$TOTAL] $test_name ---"

    start_recording

    local test_start=$(date +%s)

    if DEVICE="$DEVICE" bash "$script_file" > "$log_file" 2>&1; then
        PASSED=$((PASSED + 1))
        STATUS="PASSED"
    else
        FAILED=$((FAILED + 1))
        STATUS="FAILED"
        adb -s "$DEVICE" shell cmd connectivity airplane-mode disable 2>/dev/null || true
    fi

    local test_end=$(date +%s)
    local test_only=$((test_end - test_start))

    local video_path
    video_path=$(stop_recording "$test_name")

    local tc_end=$(date +%s)
    local duration=$((tc_end - tc_start))
    echo "  $STATUS (${duration}s total | test:${test_only}s)"

    R_STATUS+=("$STATUS")
    R_TCNAME+=("$test_name")
    R_LOGFILE+=("${test_name}.log")
    R_DURATION+=("${duration}s")
    R_VIDEO+=("$video_path")
    R_PREP_TIME+=("0s")
    R_TEST_TIME+=("${test_only}s")
}

# ── Skip list: flows handled by dedicated network test scripts ──
SKIP_FILES="33_error_screen_assert|33_error_screen_retry|34_chat_error_offline|34_chat_error_onboarding|34_chat_error_recovery|35_chat_history_retry_setup|35_chat_history_retry_assert|35_chat_history_retry_recovery"

# ── Main Execution ──
echo ""
echo "Preparing device..."
ensure_gallery_photo

if [ $# -gt 0 ]; then
    echo ""
    echo "=== RUNNING ASSIGNED FLOWS ($# total) ==="
    for flow in "$@"; do
        [ -f "$flow" ] || continue
        fname=$(basename "$flow" .yaml)
        if echo "$fname" | grep -qE "$SKIP_FILES"; then
            continue
        fi
        run_flow "$flow"
    done
else
    echo ""
    echo "=== ONBOARDING ==="
    for flow in "$PROJECT_DIR/flows/onboarding"/*.yaml; do
        [ -f "$flow" ] && run_flow "$flow"
    done

    echo ""
    echo "=== HOME / CHAT / SETTINGS / AUTH / NAVIGATION ==="
    for flow in "$PROJECT_DIR/flows/home"/*.yaml; do
        [ -f "$flow" ] || continue
        fname=$(basename "$flow" .yaml)
        if echo "$fname" | grep -qE "$SKIP_FILES"; then
            continue
        fi
        run_flow "$flow"
    done

    echo ""
    echo "=== NETWORK ERROR TESTS ==="
    run_network_test "$SCRIPT_DIR/run_tc33_error_retry.sh" "TC38 - Error Screen No Internet + Retry"
    run_network_test "$SCRIPT_DIR/run_tc34_chat_error.sh" "TC39 - Chat Error State with Retry"
    run_network_test "$SCRIPT_DIR/run_tc35_chat_history_retry.sh" "TC40 - Chat History Retry"
fi

# ── Summary ──
END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))
TOTAL_MINS=$((TOTAL_DURATION / 60))
TOTAL_SECS=$((TOTAL_DURATION % 60))

echo ""
echo "============================================"
echo "  RESULTS SUMMARY"
echo "============================================"
echo "  Total:    $TOTAL"
echo "  Passed:   $PASSED"
echo "  Failed:   $FAILED"
echo "  Duration: ${TOTAL_MINS}m ${TOTAL_SECS}s"
echo "============================================"

# ── Generate device_info.json ──
bash "$SCRIPT_DIR/device_info.sh" "$DEVICE" "$RUN_DIR" "$TESTER_NAME"

# ── Generate test_results.json ──
source "$SCRIPT_DIR/tc_metadata.sh"

PASS_RATE=0
if [ $TOTAL -gt 0 ]; then
    PASS_RATE=$(( (PASSED * 100) / TOTAL ))
fi

{
echo "{"
echo "  \"summary\": {"
echo "    \"total\": $TOTAL,"
echo "    \"passed\": $PASSED,"
echo "    \"failed\": $FAILED,"
echo "    \"pass_rate\": $PASS_RATE,"
echo "    \"duration\": \"${TOTAL_MINS}m ${TOTAL_SECS}s\""
echo "  },"

# Device info inline
MANUFACTURER=$(adb -s "$DEVICE" shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r\n')
MODEL=$(adb -s "$DEVICE" shell getprop ro.product.model 2>/dev/null | tr -d '\r\n')
ANDROID_VER=$(adb -s "$DEVICE" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r\n')
echo "  \"device\": {"
echo "    \"manufacturer\": \"$MANUFACTURER\","
echo "    \"model\": \"$MODEL\","
echo "    \"android_version\": \"$ANDROID_VER\""
echo "  },"
echo "  \"tester\": \"$TESTER_NAME\","
echo "  \"timestamp\": \"$(date '+%Y-%m-%dT%H:%M:%S')\","
echo "  \"results\": ["

for i in "${!R_STATUS[@]}"; do
    status="${R_STATUS[$i]}"
    tcname="${R_TCNAME[$i]}"
    duration="${R_DURATION[$i]}"
    prep_time="${R_PREP_TIME[$i]}"
    test_time="${R_TEST_TIME[$i]}"

    tc_num=""
    if echo "$tcname" | grep -qo 'TC[0-9]\+'; then
        tc_num=$(echo "$tcname" | grep -o 'TC[0-9]\+')
    else
        tc_num="TC$(printf '%02d' "$((i + 1))")"
    fi

    tc_desc="$(get_tc_desc "$tc_num" 2>/dev/null || echo "")"
    tc_priority="$(get_tc_priority "$tc_num" 2>/dev/null || echo "P2")"
    tc_category="$(get_tc_category "$tc_num" 2>/dev/null || echo "Other")"

    # Extract numeric seconds from duration string
    dur_sec=$(echo "$duration" | sed 's/s$//')

    comma=""
    if [ $i -lt $(( ${#R_STATUS[@]} - 1 )) ]; then
        comma=","
    fi

    # Escape quotes in strings
    safe_name=$(echo "$tcname" | sed 's/"/\\"/g')
    safe_desc=$(echo "$tc_desc" | sed 's/"/\\"/g')

    echo "    {"
    echo "      \"tc\": \"$tc_num\","
    echo "      \"name\": \"$safe_name\","
    echo "      \"description\": \"$safe_desc\","
    echo "      \"category\": \"$tc_category\","
    echo "      \"priority\": \"$tc_priority\","
    echo "      \"status\": \"$status\","
    echo "      \"duration_sec\": $dur_sec,"
    echo "      \"prep_time\": \"$prep_time\","
    echo "      \"test_time\": \"$test_time\""
    echo "    }${comma}"
done

echo "  ]"
echo "}"
} > "$RUN_DIR/test_results.json"

echo "  Test results saved: $RUN_DIR/test_results.json"

# ── Generate HTML Report ──
source "$SCRIPT_DIR/generate_report.sh"

echo ""
echo "============================================"
echo "  REPORTS GENERATED"
echo "============================================"
echo "  HTML Report:    $RUN_DIR/report.html"
echo "  Device Info:    $RUN_DIR/device_info.json"
echo "  Test Results:   $RUN_DIR/test_results.json"
echo "  Logs:           $RUN_DIR/"
echo "  Recordings:     $RECORDINGS_DIR/"
echo "============================================"
echo ""

# Export for push_results.sh
export RUN_DIR TESTER_NAME DEVICE TIMESTAMP
