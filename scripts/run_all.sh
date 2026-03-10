#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="$PROJECT_DIR/reports"
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
RUN_DIR="$REPORT_DIR/$TIMESTAMP"
DEVICE="${MAESTRO_DEVICE:-emulator-5554}"
APP_ID="org.digitalgreen.farmer.chat"
ACTIVITY="org.digitalgreen.farmer.chatbot.MainActivity"
START_TIME=$(date +%s)

NEW_PHONE_NUMBER="777766666"

RECORDINGS_DIR="$RUN_DIR/recordings"
mkdir -p "$RUN_DIR" "$RECORDINGS_DIR"

echo "============================================"
echo "  FarmerChat Maestro Automation Suite"
echo "  Run: $TIMESTAMP"
echo "  Fresh phone number: $NEW_PHONE_NUMBER"
echo "============================================"

TOTAL=0
PASSED=0
FAILED=0
declare -a R_STATUS R_TCNAME R_LOGFILE R_DURATION R_VIDEO
RECORDING_PID=""

start_recording() {
    local safe_name
    safe_name=$(echo "$1" | sed 's/[^a-zA-Z0-9_-]/_/g')
    adb -s "$DEVICE" shell rm -f /sdcard/test_recording.mp4 2>/dev/null
    adb -s "$DEVICE" shell screenrecord --time-limit 180 --size 720x1560 --bit-rate 2000000 /sdcard/test_recording.mp4 &
    RECORDING_PID=$!
    RECORDING_START=$(date +%s)
}

stop_recording() {
    local safe_name
    safe_name=$(echo "$1" | sed 's/[^a-zA-Z0-9_-]/_/g')
    local elapsed=$(( $(date +%s) - RECORDING_START ))
    if [ "$elapsed" -lt 5 ]; then
        sleep $(( 5 - elapsed ))
    fi
    adb -s "$DEVICE" shell "kill \$(pidof screenrecord)" 2>/dev/null || true
    sleep 3
    adb -s "$DEVICE" pull /sdcard/test_recording.mp4 "$RECORDINGS_DIR/${safe_name}.mp4" > /dev/null 2>&1
    local pulled=$?
    adb -s "$DEVICE" shell rm -f /sdcard/test_recording.mp4 2>/dev/null
    kill "$RECORDING_PID" 2>/dev/null || true
    wait "$RECORDING_PID" 2>/dev/null || true
    RECORDING_PID=""
    RECORDING_START=""
    if [ $pulled -eq 0 ] && [ -f "$RECORDINGS_DIR/${safe_name}.mp4" ]; then
        local fsize
        fsize=$(wc -c < "$RECORDINGS_DIR/${safe_name}.mp4" | tr -d ' ')
        if [ "$fsize" -gt 10000 ]; then
            echo "recordings/${safe_name}.mp4"
        else
            rm -f "$RECORDINGS_DIR/${safe_name}.mp4"
            echo ""
        fi
    else
        echo ""
    fi
}

ENV_ARGS=(
  -e APP_ID="$APP_ID"
  -e LANGUAGE="English (Kenya)"
  -e LANGUAGE_CODE=en
  -e USER_NAME="Test Farmer"
  -e SHORT_NAME=TF
  -e WAIT_TIMEOUT=10000
  -e PHONE_NUMBER=7013733824
  -e NEW_PHONE_NUMBER="$NEW_PHONE_NUMBER"
  -e OTP_CODE=1111
)

grant_permissions() {
    adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS 2>/dev/null || true
    adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true
    adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION 2>/dev/null || true
    adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.RECORD_AUDIO 2>/dev/null || true
    adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.CAMERA 2>/dev/null || true
}

ensure_gallery_photo() {
    local TEST_IMG="$PROJECT_DIR/assets/test_crop_disease.png"
    echo "  Pushing crop disease test image to gallery..."
    adb -s "$DEVICE" shell mkdir -p /sdcard/DCIM/Camera 2>/dev/null || true
    adb -s "$DEVICE" push "$TEST_IMG" /sdcard/DCIM/Camera/IMG_20260101_120000.png > /dev/null 2>&1
    adb -s "$DEVICE" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
        -d file:///sdcard/DCIM/Camera/IMG_20260101_120000.png > /dev/null 2>&1
    sleep 2
    local count
    count=$(adb -s "$DEVICE" shell content query --uri content://media/external/images/media --projection _id 2>/dev/null | grep -c "Row:" || echo "0")
    echo "  Gallery ready ($count photo(s) available)."
}

ensure_gallery_photo_quiet() {
    local TEST_IMG="$PROJECT_DIR/assets/test_crop_disease.png"
    adb -s "$DEVICE" shell mkdir -p /sdcard/DCIM/Camera 2>/dev/null || true
    adb -s "$DEVICE" push "$TEST_IMG" /sdcard/DCIM/Camera/IMG_20260101_120000.png > /dev/null 2>&1
    adb -s "$DEVICE" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
        -d file:///sdcard/DCIM/Camera/IMG_20260101_120000.png > /dev/null 2>&1
    sleep 1
}

prepare_device() {
    adb -s "$DEVICE" shell settings put secure stylus_handwriting_enabled 0 2>/dev/null
    adb -s "$DEVICE" shell settings put secure show_stylus_handwriting_intro 0 2>/dev/null
    adb -s "$DEVICE" shell am force-stop "$APP_ID" 2>/dev/null
    sleep 2
    adb -s "$DEVICE" shell pm clear "$APP_ID" 2>/dev/null
    adb -s "$DEVICE" shell pm clear com.google.android.inputmethod.latin 2>/dev/null
    sleep 3
    grant_permissions
    sleep 1
    adb -s "$DEVICE" shell am start -n "$APP_ID/$ACTIVITY" 2>/dev/null
    sleep 20

    for attempt in 1 2 3 4 5; do
        local ui_dump
        ui_dump=$(adb -s "$DEVICE" exec-out uiautomator dump /dev/tty 2>/dev/null || true)
        local has_error=$(echo "$ui_dump" | grep -c "Try again" | tr -d '[:space:]')
        has_error="${has_error:-0}"
        local is_loading=$(echo "$ui_dump" | grep -c "Starting" | tr -d '[:space:]')
        is_loading="${is_loading:-0}"

        if [ "$has_error" -gt 0 ] 2>/dev/null; then
            echo "  [retry $attempt] Error screen detected, restarting app..."
            adb -s "$DEVICE" shell am force-stop "$APP_ID" 2>/dev/null
            sleep 5
            adb -s "$DEVICE" shell am start -n "$APP_ID/$ACTIVITY" 2>/dev/null
            sleep 20
        elif [ "$is_loading" -gt 0 ] 2>/dev/null; then
            echo "  [wait $attempt] App still loading, waiting 10s..."
            sleep 10
        else
            break
        fi
    done

    local launched
    launched=$(adb -s "$DEVICE" shell dumpsys activity activities 2>/dev/null | grep -c "$APP_ID" | tr -d '[:space:]' || echo "0")
    launched="${launched:-0}"
    if [ "$launched" -lt 1 ] 2>/dev/null; then
        echo "  [retry] App not detected, relaunching..."
        adb -s "$DEVICE" shell am force-stop "$APP_ID" 2>/dev/null
        sleep 3
        adb -s "$DEVICE" shell am start -n "$APP_ID/$ACTIVITY" 2>/dev/null
        sleep 15
    fi
    adb -s "$DEVICE" forward tcp:7001 tcp:7001 2>/dev/null || true
}

run_flow() {
    local flow_file="$1"
    local test_name
    test_name=$(grep -m1 "^name:" "$flow_file" 2>/dev/null | sed 's/^name: *//' | tr -d '"' || echo "$(basename "$flow_file" .yaml)")
    local log_file="$RUN_DIR/${test_name}.log"
    local tc_start
    tc_start=$(date +%s)
    TOTAL=$((TOTAL + 1))

    echo ""
    echo "--- [$TOTAL] $test_name ---"

    prepare_device

    start_recording "$test_name"

    if maestro --device "$DEVICE" test "${ENV_ARGS[@]}" "$flow_file" \
        > "$log_file" 2>&1; then
        PASSED=$((PASSED + 1))
        STATUS="PASSED"
    else
        FAILED=$((FAILED + 1))
        STATUS="FAILED"
    fi

    local video_path
    video_path=$(stop_recording "$test_name")

    local tc_end
    tc_end=$(date +%s)
    local duration=$((tc_end - tc_start))
    echo "  $STATUS (${duration}s)"

    R_STATUS+=("$STATUS")
    R_TCNAME+=("$test_name")
    R_LOGFILE+=("${test_name}.log")
    R_DURATION+=("${duration}s")
    R_VIDEO+=("$video_path")
}

run_network_test() {
    local script_file="$1"
    local test_name="$2"
    local log_file="$RUN_DIR/${test_name}.log"
    local tc_start
    tc_start=$(date +%s)
    TOTAL=$((TOTAL + 1))

    echo ""
    echo "--- [$TOTAL] $test_name ---"

    start_recording "$test_name"

    if bash "$script_file" > "$log_file" 2>&1; then
        PASSED=$((PASSED + 1))
        STATUS="PASSED"
    else
        FAILED=$((FAILED + 1))
        STATUS="FAILED"
        adb -s "$DEVICE" shell cmd connectivity airplane-mode disable 2>/dev/null || true
    fi

    local video_path
    video_path=$(stop_recording "$test_name")

    local tc_end
    tc_end=$(date +%s)
    local duration=$((tc_end - tc_start))
    echo "  $STATUS (${duration}s)"

    R_STATUS+=("$STATUS")
    R_TCNAME+=("$test_name")
    R_LOGFILE+=("${test_name}.log")
    R_DURATION+=("${duration}s")
    R_VIDEO+=("$video_path")
}

SKIP_FILES="33_error_screen_assert|33_error_screen_retry|34_chat_error_offline|34_chat_error_onboarding|34_chat_error_recovery|35_chat_history_retry_setup|35_chat_history_retry_assert|35_chat_history_retry_recovery"

echo ""
echo "Preparing emulator..."
adb -s "$DEVICE" forward tcp:7001 tcp:7001 > /dev/null 2>&1 || true
ensure_gallery_photo

# ── Run onboarding flows ──
echo ""
echo "=== ONBOARDING ==="
for flow in "$PROJECT_DIR/flows/onboarding"/*.yaml; do
    [ -f "$flow" ] && run_flow "$flow"
done

# ── Run standalone home flows ──
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

# ── Run network-dependent tests ──
echo ""
echo "=== NETWORK ERROR TESTS ==="
run_network_test "$SCRIPT_DIR/run_tc33_error_retry.sh" "TC38 - Error Screen No Internet + Retry"
run_network_test "$SCRIPT_DIR/run_tc34_chat_error.sh" "TC39 - Chat Error State with Retry"
run_network_test "$SCRIPT_DIR/run_tc35_chat_history_retry.sh" "TC40 - Chat History Retry"

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

# ── Generate HTML Report ──
REPORT_FILE="$RUN_DIR/report.html"
PASS_RATE=0
if [ $TOTAL -gt 0 ]; then
    PASS_RATE=$(( (PASSED * 100) / TOTAL ))
fi

if [ $PASS_RATE -ge 80 ]; then
    PROGRESS_CLASS="good"
elif [ $PASS_RATE -ge 50 ]; then
    PROGRESS_CLASS="warn"
else
    PROGRESS_CLASS="bad"
fi

cat > "$RUN_DIR/style.css" << 'CSSEOF'
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f0f2f5; color: #1a1a2e; }
.header { background: linear-gradient(135deg, #1a7431, #2d9b4e); color: white; padding: 32px 40px; }
.header h1 { font-size: 28px; margin-bottom: 4px; }
.header p { opacity: 0.85; font-size: 14px; }
.summary { display: flex; gap: 16px; padding: 24px 40px; flex-wrap: wrap; }
.card { background: white; border-radius: 12px; padding: 20px 24px; flex: 1; min-width: 120px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); text-align: center; }
.card .number { font-size: 36px; font-weight: 700; }
.card .label { font-size: 13px; color: #666; margin-top: 4px; }
.card.total .number { color: #1a7431; }
.card.passed .number { color: #22c55e; }
.card.failed .number { color: #ef4444; }
.card.rate .number { color: #3b82f6; }
.card.time .number { font-size: 28px; color: #8b5cf6; }
.progress-bar { margin: 0 40px 24px; background: #e5e7eb; border-radius: 8px; height: 12px; overflow: hidden; }
.progress-fill { height: 100%; border-radius: 8px; transition: width 0.5s; }
.progress-fill.good { background: linear-gradient(90deg, #22c55e, #16a34a); }
.progress-fill.warn { background: linear-gradient(90deg, #f59e0b, #d97706); }
.progress-fill.bad { background: linear-gradient(90deg, #ef4444, #dc2626); }
.table-container { padding: 0 40px 40px; }
table { width: 100%; border-collapse: collapse; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
th { background: #f8fafc; padding: 14px 20px; text-align: left; font-size: 13px; color: #64748b; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }
td { padding: 14px 20px; border-top: 1px solid #f1f5f9; font-size: 14px; vertical-align: top; }
tr:hover td { background: #f8fafc; }
.badge { padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; display: inline-block; }
.badge.passed { background: #dcfce7; color: #166534; }
.badge.failed { background: #fee2e2; color: #991b1b; }
.duration { color: #64748b; font-size: 13px; }
.log-file { color: #64748b; font-size: 12px; font-family: monospace; }
details { margin-top: 6px; }
details summary { cursor: pointer; color: #3b82f6; font-size: 12px; font-weight: 600; }
details summary:hover { text-decoration: underline; }
.log-content { margin-top: 8px; padding: 12px; background: #1e293b; color: #e2e8f0; border-radius: 8px; font-family: 'SF Mono', Monaco, Consolas, monospace; font-size: 11px; line-height: 1.5; white-space: pre-wrap; word-break: break-word; max-height: 400px; overflow-y: auto; }
.log-content .completed { color: #4ade80; }
.log-content .failed-line { color: #f87171; font-weight: bold; }
.log-content .skipped { color: #94a3b8; }
.video-cell video { border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.12); }
.video-cell a { color: #3b82f6; font-size: 12px; font-weight: 600; text-decoration: none; }
.video-cell a:hover { text-decoration: underline; }
.no-video { color: #94a3b8; font-size: 12px; }
.footer { text-align: center; padding: 24px; color: #94a3b8; font-size: 13px; }
.coverage { padding: 0 40px 24px; }
.coverage h2 { font-size: 18px; margin-bottom: 12px; color: #1a1a2e; }
.coverage-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 12px; }
.cov-card { background: white; border-radius: 10px; padding: 16px; box-shadow: 0 2px 6px rgba(0,0,0,0.05); }
.cov-card .area { font-weight: 600; font-size: 14px; margin-bottom: 4px; }
.cov-card .count { font-size: 24px; font-weight: 700; color: #1a7431; }
.cov-card .desc { font-size: 12px; color: #94a3b8; }
CSSEOF

echo ".progress-fill { width: ${PASS_RATE}%; }" >> "$RUN_DIR/style.css"

cat > "$REPORT_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
HTMLEOF

cat >> "$REPORT_FILE" << HTMLEOF
<title>FarmerChat Test Report - $TIMESTAMP</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
<div class="header">
  <h1>FarmerChat Maestro Test Report</h1>
  <p>Run: $TIMESTAMP &nbsp;|&nbsp; App: $APP_ID &nbsp;|&nbsp; Device: $DEVICE &nbsp;|&nbsp; Duration: ${TOTAL_MINS}m ${TOTAL_SECS}s</p>
</div>
<div class="summary">
  <div class="card total"><div class="number">$TOTAL</div><div class="label">Total Tests</div></div>
  <div class="card passed"><div class="number">$PASSED</div><div class="label">Passed</div></div>
  <div class="card failed"><div class="number">$FAILED</div><div class="label">Failed</div></div>
  <div class="card rate"><div class="number">${PASS_RATE}%</div><div class="label">Pass Rate</div></div>
  <div class="card time"><div class="number">${TOTAL_MINS}m ${TOTAL_SECS}s</div><div class="label">Total Time</div></div>
</div>
<div class="progress-bar">
  <div class="progress-fill $PROGRESS_CLASS"></div>
</div>
<div class="coverage">
  <h2>Coverage by Area</h2>
  <div class="coverage-grid">
    <div class="cov-card"><div class="area">Onboarding</div><div class="count">6</div><div class="desc">TC01-04, TC31-32, TC37</div></div>
    <div class="cov-card"><div class="area">Home / Feed</div><div class="count">7</div><div class="desc">TC05, TC07-10, TC12</div></div>
    <div class="cov-card"><div class="area">Chat</div><div class="count">8</div><div class="desc">TC06, TC11, TC13-14, TC28, TC30, TC34-35</div></div>
    <div class="cov-card"><div class="area">Settings</div><div class="count">5</div><div class="desc">TC15-18, TC27</div></div>
    <div class="cov-card"><div class="area">Auth</div><div class="count">3</div><div class="desc">TC19, TC25-26</div></div>
    <div class="cov-card"><div class="area">Help</div><div class="count">3</div><div class="desc">TC20-22</div></div>
    <div class="cov-card"><div class="area">Navigation</div><div class="count">4</div><div class="desc">TC23-24, TC29, TC33, TC36</div></div>
    <div class="cov-card"><div class="area">Error / Retry</div><div class="count">3</div><div class="desc">TC38-40</div></div>
  </div>
</div>
<div class="table-container">
<table>
<thead><tr><th>#</th><th>Test Case</th><th>Status</th><th>Duration</th><th>Recording</th><th>Execution Log</th></tr></thead>
<tbody>
HTMLEOF

for i in "${!R_STATUS[@]}"; do
    status="${R_STATUS[$i]}"
    tcname="${R_TCNAME[$i]}"
    logfile="${R_LOGFILE[$i]}"
    duration="${R_DURATION[$i]}"
    video_file="${R_VIDEO[$i]:-}"
    idx=$((i + 1))
    status_lower=$(echo "$status" | tr '[:upper:]' '[:lower:]')

    tc_num=""
    if echo "$tcname" | grep -qo 'TC[0-9]\+'; then
        tc_num=$(echo "$tcname" | grep -o 'TC[0-9]\+')
    else
        tc_num="TC$(printf '%02d' "$idx")"
    fi

    log_path="$RUN_DIR/$logfile"
    log_html=""
    if [ -f "$log_path" ]; then
        log_raw=$(cat "$log_path" | \
            sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' | \
            sed 's/COMPLETED/<span class="completed">COMPLETED<\/span>/g' | \
            sed 's/FAILED/<span class="failed-line">FAILED<\/span>/g' | \
            sed 's/SKIPPED/<span class="skipped">SKIPPED<\/span>/g' | \
            sed 's/WARNED/<span class="skipped">WARNED<\/span>/g')
        log_html="<details><summary>View Log</summary><div class=\"log-content\">${log_raw}</div></details>"
    else
        log_html="<span class=\"log-file\">No log</span>"
    fi

    video_html=""
    if [ -n "$video_file" ] && [ -f "$RUN_DIR/$video_file" ]; then
        video_html="<div class=\"video-cell\"><video width=\"300\" controls preload=\"metadata\"><source src=\"$video_file\" type=\"video/mp4\"></video><br><a href=\"$video_file\" download>Download MP4</a></div>"
    else
        video_html="<span class=\"no-video\">No recording</span>"
    fi

    cat >> "$REPORT_FILE" << ROWEOF
<tr>
  <td><strong>$tc_num</strong></td>
  <td>$tcname</td>
  <td><span class="badge $status_lower">$status</span></td>
  <td class="duration">$duration</td>
  <td>$video_html</td>
  <td>$log_html</td>
</tr>
ROWEOF
done

cat >> "$REPORT_FILE" << HTMLEOF
</tbody>
</table>
</div>
<div class="footer">Generated by FarmerChat Maestro Automation Framework</div>
</body>
</html>
HTMLEOF

VIDEO_COUNT=$(ls "$RECORDINGS_DIR"/*.mp4 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "Report:     $REPORT_FILE"
echo "Logs:       $RUN_DIR/"
echo "Recordings: $RECORDINGS_DIR/ ($VIDEO_COUNT videos)"
echo ""
