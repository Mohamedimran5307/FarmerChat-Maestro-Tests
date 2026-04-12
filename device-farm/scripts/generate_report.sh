#!/bin/bash
# generate_report.sh — HTML report generator for FarmerChat DeviceFarm
# Sourced from run_tests.sh — expects all variables to be set.

REPORT_FILE="$RUN_DIR/report.html"

if [ $PASS_RATE -ge 80 ]; then
    PROGRESS_CLASS="good"
elif [ $PASS_RATE -ge 50 ]; then
    PROGRESS_CLASS="warn"
else
    PROGRESS_CLASS="bad"
fi

cp "$SCRIPT_DIR/report_style.css" "$RUN_DIR/style.css"
echo ".progress-fill { width: ${PASS_RATE}%; }" >> "$RUN_DIR/style.css"

ANDROID_VER=$(adb -s "$DEVICE" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r\n' || echo "N/A")
API_LEVEL=$(adb -s "$DEVICE" shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r\n' || echo "N/A")
DEVICE_MODEL=$(adb -s "$DEVICE" shell getprop ro.product.model 2>/dev/null | tr -d '\r\n' || echo "Unknown")
DEVICE_MANUFACTURER=$(adb -s "$DEVICE" shell getprop ro.product.manufacturer 2>/dev/null | tr -d '\r\n' || echo "Unknown")
MAESTRO_VER=$(maestro --version 2>&1 | head -1 | tr -d '\r\n' || echo "N/A")

if [ $FAILED -eq 0 ]; then
    EXEC_SUMMARY="All <span class=\"highlight\">$TOTAL test cases passed</span> across <span class=\"highlight\">8 functional areas</span> with a <span class=\"highlight\">${PASS_RATE}% pass rate</span>. The suite validates end-to-end user journeys including onboarding, AI-powered agricultural chat, photo-based crop disease diagnosis, authentication, settings management, and error recovery flows. No regressions detected. Total execution time: <span class=\"highlight\">${TOTAL_MINS}m ${TOTAL_SECS}s</span>."
    SUMMARY_CLASS="exec-summary"
else
    EXEC_SUMMARY="<span class=\"highlight\">$PASSED of $TOTAL</span> test cases passed (<span class=\"highlight\">${PASS_RATE}%</span>). <span class=\"highlight\">$FAILED test(s) failed</span> and require investigation. Review the failed test recordings and execution logs below for details."
    SUMMARY_CLASS="exec-summary has-failures"
fi

cat > "$REPORT_FILE" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>FarmerChat DeviceFarm Report - $TIMESTAMP</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
<div class="header">
  <h1>FarmerChat DeviceFarm — Test Report</h1>
  <p>Run: $TIMESTAMP &nbsp;|&nbsp; Tester: $TESTER_NAME &nbsp;|&nbsp; Device: $DEVICE_MANUFACTURER $DEVICE_MODEL &nbsp;|&nbsp; Duration: ${TOTAL_MINS}m ${TOTAL_SECS}s</p>
  <p class="subtitle">Physical Device Testing &bull; Digital Green &bull; FarmerChat Mobile Application</p>
</div>
<div class="$SUMMARY_CLASS">
  <h2>Executive Summary</h2>
  <p>$EXEC_SUMMARY</p>
</div>
<div class="env-section">
  <h2>Test Environment</h2>
  <div class="env-grid">
    <div class="env-item"><span class="env-label">Tester</span><span class="env-value">$TESTER_NAME</span></div>
    <div class="env-item"><span class="env-label">Manufacturer</span><span class="env-value">$DEVICE_MANUFACTURER</span></div>
    <div class="env-item"><span class="env-label">Device</span><span class="env-value">$DEVICE_MODEL ($DEVICE)</span></div>
    <div class="env-item"><span class="env-label">Android</span><span class="env-value">$ANDROID_VER (API $API_LEVEL)</span></div>
    <div class="env-item"><span class="env-label">Connection</span><span class="env-value">Physical Device (USB)</span></div>
    <div class="env-item"><span class="env-label">Maestro</span><span class="env-value">$MAESTRO_VER</span></div>
  </div>
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
    <div class="cov-card"><div class="area">Home / Feed</div><div class="count">6</div><div class="desc">TC05, TC07-10, TC12</div></div>
    <div class="cov-card"><div class="area">Chat</div><div class="count">9</div><div class="desc">TC06, TC11, TC13-14, TC24, TC26, TC28, TC30, TC34-35</div></div>
    <div class="cov-card"><div class="area">Settings</div><div class="count">5</div><div class="desc">TC15-18, TC27</div></div>
    <div class="cov-card"><div class="area">Authentication</div><div class="count">3</div><div class="desc">TC19, TC25-26</div></div>
    <div class="cov-card"><div class="area">Help &amp; Legal</div><div class="count">3</div><div class="desc">TC20-22</div></div>
    <div class="cov-card"><div class="area">Navigation</div><div class="count">5</div><div class="desc">TC23, TC29, TC33, TC36</div></div>
    <div class="cov-card"><div class="area">Error Recovery</div><div class="count">3</div><div class="desc">TC38-40</div></div>
  </div>
</div>
<div class="table-container">
<table>
<thead><tr><th>#</th><th>Test Case</th><th>Priority</th><th>Module</th><th>Status</th><th>Total</th><th>Prep</th><th>Test</th><th>Recording</th><th>Log</th></tr></thead>
<tbody>
HTMLEOF

source "$SCRIPT_DIR/tc_metadata.sh"

for i in "${!R_STATUS[@]}"; do
    status="${R_STATUS[$i]}"
    tcname="${R_TCNAME[$i]}"
    logfile="${R_LOGFILE[$i]}"
    duration="${R_DURATION[$i]}"
    video_file="${R_VIDEO[$i]:-}"
    prep_time="${R_PREP_TIME[$i]:-N/A}"
    test_time="${R_TEST_TIME[$i]:-N/A}"
    idx=$((i + 1))
    status_lower=$(echo "$status" | tr '[:upper:]' '[:lower:]')

    tc_num=""
    if echo "$tcname" | grep -qo 'TC[0-9]\+'; then
        tc_num=$(echo "$tcname" | grep -o 'TC[0-9]\+')
    else
        tc_num="TC$(printf '%02d' "$idx")"
    fi

    tc_desc="$(get_tc_desc "$tc_num" 2>/dev/null || echo "")"
    tc_priority="$(get_tc_priority "$tc_num" 2>/dev/null || echo "P2")"
    tc_category="$(get_tc_category "$tc_num" 2>/dev/null || echo "Other")"
    tc_cat_class="$(get_tc_cat_class "$tc_num" 2>/dev/null || echo "home")"
    priority_lower=$(echo "$tc_priority" | tr '[:upper:]' '[:lower:]')

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
  <td><div class="tc-name">$tcname</div><div class="tc-desc">$tc_desc</div></td>
  <td><span class="priority $priority_lower">$tc_priority</span></td>
  <td><span class="category $tc_cat_class">$tc_category</span></td>
  <td><span class="badge $status_lower">$status</span></td>
  <td class="duration">$duration</td>
  <td class="duration">$prep_time</td>
  <td class="duration">$test_time</td>
  <td>$video_html</td>
  <td>$log_html</td>
</tr>
ROWEOF
done

cat >> "$REPORT_FILE" << HTMLEOF
</tbody>
</table>
</div>
<div class="footer"><span class="org">Digital Green</span> &bull; FarmerChat DeviceFarm &bull; Powered by Maestro &bull; Tested by $TESTER_NAME</div>
</body>
</html>
HTMLEOF

echo "  HTML report saved: $REPORT_FILE"
