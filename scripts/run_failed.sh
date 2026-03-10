#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="$PROJECT_DIR/reports"
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
RUN_DIR="$REPORT_DIR/$TIMESTAMP"
DEVICE="emulator-5554"
APP_ID="org.digitalgreen.farmer.chat"
ACTIVITY="org.digitalgreen.farmer.chatbot.MainActivity"

mkdir -p "$RUN_DIR"

echo "============================================"
echo "  FarmerChat - Re-run Failed Tests"
echo "  Run: $TIMESTAMP"
echo "============================================"

FLOWS_DIR="$PROJECT_DIR/flows"
TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0
RESULTS=()

adb_clear_and_launch() {
    echo "  [ADB] Clearing app data and launching..."
    adb -s "$DEVICE" shell pm clear "$APP_ID" > /dev/null 2>&1 || true
    sleep 2
    adb -s "$DEVICE" shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n "$APP_ID/$ACTIVITY" > /dev/null 2>&1
    sleep 6
}

adb_launch() {
    echo "  [ADB] Launching app..."
    adb -s "$DEVICE" shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n "$APP_ID/$ACTIVITY" > /dev/null 2>&1
    sleep 3
}

run_flow() {
    local flow_file="$1"
    local needs_fresh="$2"
    local flow_name=$(basename "$flow_file" .yaml)
    local test_name=$(grep -m1 "^name:" "$flow_file" 2>/dev/null | sed 's/^name: *//' | tr -d '"' || echo "$flow_name")
    local log_file="$RUN_DIR/${flow_name}.log"
    TOTAL=$((TOTAL + 1))

    echo ""
    echo "--- [$TOTAL] Running: $test_name ---"

    if [ "$needs_fresh" = "fresh" ]; then
        adb_clear_and_launch
    else
        adb_launch
    fi

    if ~/.maestro/bin/maestro --device "$DEVICE" test "$flow_file" \
        -e APP_ID="$APP_ID" \
        -e LANGUAGE="English (Kenya)" \
        -e LANGUAGE_CODE=en \
        -e USER_NAME="Test Farmer" \
        -e SHORT_NAME=TF \
        -e WAIT_TIMEOUT=10000 \
        > "$log_file" 2>&1; then
        PASSED=$((PASSED + 1))
        STATUS="PASSED"
        echo "  ✅ PASSED"
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 2 ]; then
            SKIPPED=$((SKIPPED + 1))
            STATUS="SKIPPED"
            echo "  ⏭️  SKIPPED"
        else
            FAILED=$((FAILED + 1))
            STATUS="FAILED"
            FAIL_REASON=$(grep -E "AssertVisible|Element not found|Assertion|FAILED|timed out|Error" "$log_file" 2>/dev/null | tail -3 | head -1 || echo "See log")
            echo "  ❌ FAILED: $FAIL_REASON"
        fi
    fi

    RESULTS+=("$STATUS|$test_name|$flow_name")
}

FAILED_FLOWS=(
    "$FLOWS_DIR/onboarding/01_splash_screen.yaml|fresh"
    "$FLOWS_DIR/onboarding/06_name_validation.yaml|fresh"
    "$FLOWS_DIR/chat/11_chat_type_question.yaml|fresh"
    "$FLOWS_DIR/chat/12_chat_follow_up.yaml|fresh"
    "$FLOWS_DIR/chat/13_chat_related_questions.yaml|fresh"
    "$FLOWS_DIR/chat/14_chat_back_to_home.yaml|fresh"
    "$FLOWS_DIR/navigation/18_chat_history.yaml|fresh"
    "$FLOWS_DIR/e2e/27_e2e_onboarding_to_chat.yaml|fresh"
    "$FLOWS_DIR/e2e/28_e2e_full_app_journey.yaml|fresh"
    "$FLOWS_DIR/e2e/29_e2e_chat_history_reopen.yaml|fresh"
)

for entry in "${FAILED_FLOWS[@]}"; do
    IFS='|' read -r flow launch_type <<< "$entry"
    if [ -f "$flow" ]; then
        run_flow "$flow" "$launch_type"
    else
        echo "⚠️  Flow not found: $flow"
    fi
done

echo ""
echo "============================================"
echo "  RESULTS SUMMARY"
echo "============================================"
echo "  Total:   $TOTAL"
echo "  Passed:  $PASSED"
echo "  Failed:  $FAILED"
echo "  Skipped: $SKIPPED"
echo "============================================"

REPORT_FILE="$RUN_DIR/report.html"
PASS_RATE=0
if [ $TOTAL -gt 0 ]; then
    PASS_RATE=$(( (PASSED * 100) / TOTAL ))
fi

cat > "$REPORT_FILE" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>FarmerChat Re-run Failed Tests - $TIMESTAMP</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f0f2f5; color: #1a1a2e; }
  .header { background: linear-gradient(135deg, #1a7431, #2d9b4e); color: white; padding: 32px 40px; }
  .header h1 { font-size: 28px; margin-bottom: 4px; }
  .header p { opacity: 0.85; font-size: 14px; }
  .summary { display: flex; gap: 16px; padding: 24px 40px; flex-wrap: wrap; }
  .card { background: white; border-radius: 12px; padding: 20px 24px; flex: 1; min-width: 140px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); text-align: center; }
  .card .number { font-size: 36px; font-weight: 700; }
  .card .label { font-size: 13px; color: #666; margin-top: 4px; }
  .card.total .number { color: #1a7431; }
  .card.passed .number { color: #22c55e; }
  .card.failed .number { color: #ef4444; }
  .card.skipped .number { color: #f59e0b; }
  .card.rate .number { color: #3b82f6; }
  .progress-bar { margin: 0 40px 24px; background: #e5e7eb; border-radius: 8px; height: 12px; overflow: hidden; }
  .progress-fill { height: 100%; border-radius: 8px; transition: width 0.5s; }
  .progress-fill.good { background: linear-gradient(90deg, #22c55e, #16a34a); }
  .progress-fill.warn { background: linear-gradient(90deg, #f59e0b, #d97706); }
  .progress-fill.bad { background: linear-gradient(90deg, #ef4444, #dc2626); }
  .table-container { padding: 0 40px 40px; }
  table { width: 100%; border-collapse: collapse; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
  th { background: #f8fafc; padding: 14px 20px; text-align: left; font-size: 13px; color: #64748b; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }
  td { padding: 14px 20px; border-top: 1px solid #f1f5f9; font-size: 14px; }
  tr:hover td { background: #f8fafc; }
  .badge { padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; display: inline-block; }
  .badge.passed { background: #dcfce7; color: #166534; }
  .badge.failed { background: #fee2e2; color: #991b1b; }
  .badge.skipped { background: #fef3c7; color: #92400e; }
  .failure-reason { font-size: 12px; color: #991b1b; display: block; margin-top: 4px; }
  .footer { text-align: center; padding: 24px; color: #94a3b8; font-size: 13px; }
</style>
</head>
<body>
<div class="header">
  <h1>FarmerChat - Re-run Failed Tests Report</h1>
  <p>Run: $TIMESTAMP | App: $APP_ID | Device: $DEVICE</p>
</div>
<div class="summary">
  <div class="card total"><div class="number">$TOTAL</div><div class="label">Total Tests</div></div>
  <div class="card passed"><div class="number">$PASSED</div><div class="label">Passed</div></div>
  <div class="card failed"><div class="number">$FAILED</div><div class="label">Failed</div></div>
  <div class="card skipped"><div class="number">$SKIPPED</div><div class="label">Skipped</div></div>
  <div class="card rate"><div class="number">${PASS_RATE}%</div><div class="label">Pass Rate</div></div>
</div>
<div class="progress-bar">
  <div class="progress-fill $([ $PASS_RATE -ge 80 ] && echo good || ([ $PASS_RATE -ge 50 ] && echo warn || echo bad))" style="width: ${PASS_RATE}%"></div>
</div>
<div class="table-container">
<table>
<thead><tr><th>#</th><th>Test Case</th><th>Flow File</th><th>Status</th></tr></thead>
<tbody>
HTMLEOF

INDEX=0
for result in "${RESULTS[@]}"; do
    IFS='|' read -r status name file <<< "$result"
    INDEX=$((INDEX + 1))
    STATUS_LOWER=$(echo "$status" | tr '[:upper:]' '[:lower:]')
    FAIL_INFO=""
    if [ "$status" = "FAILED" ]; then
        LOG="$RUN_DIR/${file}.log"
        if [ -f "$LOG" ]; then
            FAIL_INFO=$(grep -E "AssertVisible|Element not found|Assertion|FAILED|timed out|Error" "$LOG" 2>/dev/null | tail -3 | head -1 | sed 's/</\&lt;/g; s/>/\&gt;/g' || echo "")
        fi
    fi
    if [ -n "$FAIL_INFO" ]; then
        cat >> "$REPORT_FILE" << ROWEOF
<tr><td>$INDEX</td><td>$name<span class="failure-reason">$FAIL_INFO</span></td><td>${file}.yaml</td><td><span class="badge $STATUS_LOWER">$status</span></td></tr>
ROWEOF
    else
        cat >> "$REPORT_FILE" << ROWEOF
<tr><td>$INDEX</td><td>$name</td><td>${file}.yaml</td><td><span class="badge $STATUS_LOWER">$status</span></td></tr>
ROWEOF
    fi
done

cat >> "$REPORT_FILE" << HTMLEOF
</tbody>
</table>
</div>
<div class="footer">Generated by FarmerChat Maestro Automation Framework</div>
</body>
</html>
HTMLEOF

echo ""
echo "📊 HTML Report: $REPORT_FILE"
echo "📁 Logs: $RUN_DIR/"
echo ""
