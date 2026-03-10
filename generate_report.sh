#!/bin/bash

BASE_DIR="/Users/shaikmohamedimran/Documents/Maestro_automation_FarmerChat"
LOG_DIR="$BASE_DIR/reports/logs_20260305_155442"
REPORT_FILE="$BASE_DIR/reports/test_report_20260305_155442.html"

declare -a NAMES=(
    "TC01 - Splash Screen Verification"
    "TC02 - Language Selection Screen"
    "TC03 - Select Language and Proceed"
    "TC04 - Enter Name Screen"
    "TC05 - Skip Name Entry"
    "TC06 - Name Input Validation"
    "TC07 - Home Screen Verification"
    "TC08 - Home Feed Scroll and Card Interaction"
    "TC09 - Home Screen Type Question"
    "TC10 - Weather Widget Tap"
    "TC11 - Chat Type and Send Question"
    "TC12 - Chat Follow Up Question"
    "TC13 - Chat Related Questions"
    "TC14 - Chat Navigate Back to Home"
    "TC15 - Drawer Navigation Menu"
    "TC16 - Drawer Navigate to Settings"
    "TC17 - Drawer Navigate to Help"
    "TC18 - Chat History Screen"
    "TC19 - Settings Screen Verification"
    "TC20 - Settings Appearance Mode Toggle"
    "TC21 - Settings Edit Name"
    "TC22 - Settings Change Language"
    "TC23 - Help Screen Verification"
    "TC24 - Help Terms of Use Link"
    "TC25 - Help Privacy Policy Link"
    "TC26 - Account Sign Up Flow Entry"
    "TC27 - E2E: Full Onboarding to First Chat"
    "TC28 - E2E: Complete App Journey"
    "TC29 - E2E: Chat then Reopen from History"
)

declare -a FILES=(
    "01_splash_screen.log"
    "02_language_selection.log"
    "03_language_select_and_proceed.log"
    "04_enter_name.log"
    "05_enter_name_skip.log"
    "06_name_validation.log"
    "07_home_screen_verification.log"
    "08_home_feed_scroll.log"
    "09_home_input_type.log"
    "10_home_weather_widget.log"
    "11_chat_type_question.log"
    "12_chat_follow_up.log"
    "13_chat_related_questions.log"
    "14_chat_back_to_home.log"
    "15_drawer_navigation.log"
    "16_drawer_to_settings.log"
    "17_drawer_to_help.log"
    "18_chat_history.log"
    "19_settings_screen.log"
    "20_settings_appearance.log"
    "21_settings_edit_name.log"
    "22_settings_change_language.log"
    "23_help_screen.log"
    "24_help_terms_of_use.log"
    "25_help_privacy_policy.log"
    "26_account_signup_flow.log"
    "27_e2e_onboarding_to_chat.log"
    "28_e2e_full_app_journey.log"
    "29_e2e_chat_history_reopen.log"
)

declare -a CATEGORIES=(
    "onboarding" "onboarding" "onboarding" "onboarding" "onboarding" "onboarding"
    "home" "home" "home" "home"
    "chat" "chat" "chat" "chat"
    "navigation" "navigation" "navigation" "navigation"
    "settings" "settings" "settings" "settings"
    "help" "help" "help"
    "auth"
    "e2e" "e2e" "e2e"
)

declare -a DURATIONS=(24 23 29 104 34 27 55 40 95 89 140 124 126 49 61 52 75 94 87 94 122 64 88 125 75 107 146 154 192)

# Actual results from the test run
declare -a STATUSES=(
    "PASSED (with warnings)" "FAILED" "PASSED" "FAILED" "FAILED" "PASSED"
    "PASSED" "PASSED" "FAILED" "FAILED"
    "FAILED" "FAILED" "FAILED" "PASSED"
    "PASSED" "PASSED" "PASSED" "FAILED"
    "PASSED" "PASSED" "PASSED" "PASSED"
    "PASSED" "FAILED" "FAILED"
    "PASSED (with warnings)"
    "FAILED" "FAILED" "FAILED"
)
declare -a STATUS_CLASSES=(
    "warn" "fail" "pass" "fail" "fail" "pass"
    "pass" "pass" "fail" "fail"
    "fail" "fail" "fail" "pass"
    "pass" "pass" "pass" "fail"
    "pass" "pass" "pass" "pass"
    "pass" "fail" "fail"
    "warn"
    "fail" "fail" "fail"
)

TOTAL=29
PASSED=15
FAILED=14
WARNED=2
PASS_RATE=51
TOTAL_MIN=48
TOTAL_SEC=53

cat > "$REPORT_FILE" << 'HTMLHEAD'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>FarmerChat - Test Report</title>
<style>
  :root {
    --bg: #0f172a; --surface: #1e293b; --surface2: #334155;
    --text: #f1f5f9; --text2: #94a3b8; --accent: #38bdf8;
    --green: #22c55e; --red: #ef4444; --yellow: #eab308;
    --border: #475569; --radius: 12px;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: var(--bg); color: var(--text); padding: 24px; line-height: 1.6;
  }
  .container { max-width: 1200px; margin: 0 auto; }
  h1 { font-size: 28px; margin-bottom: 4px; }
  .subtitle { color: var(--text2); font-size: 14px; margin-bottom: 32px; }
  .summary-grid {
    display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 16px; margin-bottom: 32px;
  }
  .summary-card {
    background: var(--surface); border-radius: var(--radius); padding: 20px;
    border: 1px solid var(--border); text-align: center;
  }
  .summary-card .value { font-size: 36px; font-weight: 700; }
  .summary-card .label { color: var(--text2); font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; }
  .summary-card.total .value { color: var(--accent); }
  .summary-card.pass .value { color: var(--green); }
  .summary-card.fail .value { color: var(--red); }
  .summary-card.warn .value { color: var(--yellow); }
  .summary-card.rate .value { color: var(--accent); }
  .summary-card.time .value { color: var(--text2); font-size: 24px; }
  .progress-bar {
    width: 100%; height: 8px; background: var(--surface2); border-radius: 4px;
    margin-bottom: 32px; overflow: hidden; display: flex;
  }
  .progress-pass { background: var(--green); }
  .progress-fail { background: var(--red); }
  .section-title { font-size: 20px; margin-bottom: 16px; }
  table { width: 100%; border-collapse: separate; border-spacing: 0; background: var(--surface); border-radius: var(--radius); overflow: hidden; }
  thead th {
    background: var(--surface2); padding: 14px 16px; text-align: left;
    font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; color: var(--text2);
    position: sticky; top: 0; z-index: 1;
  }
  tbody td { padding: 14px 16px; border-bottom: 1px solid var(--border); font-size: 14px; vertical-align: top; }
  tbody tr:last-child td { border-bottom: none; }
  tbody tr:hover { background: rgba(56, 189, 248, 0.05); }
  .badge {
    display: inline-block; padding: 4px 12px; border-radius: 20px;
    font-size: 12px; font-weight: 600; text-transform: uppercase; white-space: nowrap;
  }
  .badge.pass { background: rgba(34, 197, 94, 0.15); color: var(--green); }
  .badge.fail { background: rgba(239, 68, 68, 0.15); color: var(--red); }
  .badge.warn { background: rgba(234, 179, 8, 0.15); color: var(--yellow); }
  .duration { color: var(--text2); font-size: 13px; }
  .category-badge {
    display: inline-block; padding: 2px 8px; border-radius: 6px;
    font-size: 11px; background: var(--surface2); color: var(--text2); margin-right: 4px;
  }
  .toggle-btn {
    background: none; border: 1px solid var(--border); color: var(--text2);
    padding: 4px 10px; border-radius: 6px; cursor: pointer; font-size: 12px;
    transition: all 0.2s;
  }
  .toggle-btn:hover { border-color: var(--accent); color: var(--accent); }
  .log-panel {
    display: none; padding: 16px; background: #0b1120; border-radius: 8px;
    margin-top: 8px; font-family: 'SF Mono', 'Fira Code', 'Menlo', monospace; font-size: 12px;
    white-space: pre-wrap; word-break: break-word; color: var(--text2);
    max-height: 400px; overflow-y: auto; line-height: 1.6;
    border: 1px solid var(--border);
  }
  .log-panel.open { display: block; }
  .filter-bar { display: flex; gap: 8px; margin-bottom: 16px; flex-wrap: wrap; }
  .filter-btn {
    padding: 6px 16px; border-radius: 20px; border: 1px solid var(--border);
    background: transparent; color: var(--text2); cursor: pointer; font-size: 13px;
    transition: all 0.2s;
  }
  .filter-btn:hover, .filter-btn.active { border-color: var(--accent); color: var(--accent); background: rgba(56,189,248,0.1); }
  footer { text-align: center; margin-top: 40px; padding: 20px 0; color: var(--text2); font-size: 12px; border-top: 1px solid var(--border); }
</style>
</head>
<body>
<div class="container">
  <h1>FarmerChat Test Report</h1>
HTMLHEAD

cat >> "$REPORT_FILE" << EOF
  <p class="subtitle">Generated on March 05, 2026 at 04:43 PM &bull; Device: emulator-5554 &bull; Duration: ${TOTAL_MIN}m ${TOTAL_SEC}s</p>

  <div class="summary-grid">
    <div class="summary-card total"><div class="value">$TOTAL</div><div class="label">Total Tests</div></div>
    <div class="summary-card pass"><div class="value">$PASSED</div><div class="label">Passed</div></div>
    <div class="summary-card fail"><div class="value">$FAILED</div><div class="label">Failed</div></div>
    <div class="summary-card warn"><div class="value">$WARNED</div><div class="label">Warnings</div></div>
    <div class="summary-card rate"><div class="value">${PASS_RATE}%</div><div class="label">Pass Rate</div></div>
    <div class="summary-card time"><div class="value">${TOTAL_MIN}m ${TOTAL_SEC}s</div><div class="label">Total Time</div></div>
  </div>

  <div class="progress-bar">
    <div class="progress-pass" style="width:${PASS_RATE}%"></div>
    <div class="progress-fail" style="width:$((100 - PASS_RATE))%"></div>
  </div>
EOF

cat >> "$REPORT_FILE" << 'EOF'
  <h2 class="section-title">Test Results</h2>
  <div class="filter-bar">
    <button class="filter-btn active" onclick="filterTests('all')">All</button>
    <button class="filter-btn" onclick="filterTests('pass')">Passed</button>
    <button class="filter-btn" onclick="filterTests('fail')">Failed</button>
    <button class="filter-btn" onclick="filterTests('warn')">Warnings</button>
  </div>
  <table>
    <thead>
      <tr>
        <th style="width:40px">#</th>
        <th>Test Name</th>
        <th>Category</th>
        <th>Status</th>
        <th>Duration</th>
        <th>Details</th>
      </tr>
    </thead>
    <tbody>
EOF

for i in "${!NAMES[@]}"; do
    idx=$((i + 1))
    name="${NAMES[$i]}"
    category="${CATEGORIES[$i]}"
    status="${STATUSES[$i]}"
    status_class="${STATUS_CLASSES[$i]}"
    duration="${DURATIONS[$i]}"
    logfile="$LOG_DIR/${FILES[$i]}"

    log_content=""
    if [ -f "$logfile" ]; then
        log_content=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g' "$logfile" | \
            sed 's/\.\.\. COMPLETED/... <span style="color:#22c55e">COMPLETED<\/span>/g' | \
            sed 's/\.\.\. FAILED/... <span style="color:#ef4444">FAILED<\/span>/g' | \
            sed 's/\.\.\. WARNED/... <span style="color:#eab308">WARNED<\/span>/g')
    fi

    cat >> "$REPORT_FILE" << EOF
      <tr class="test-row" data-status="$status_class">
        <td style="color:var(--text2)">$idx</td>
        <td><strong>$name</strong></td>
        <td><span class="category-badge">$category</span></td>
        <td><span class="badge $status_class">$status</span></td>
        <td class="duration">${duration}s</td>
        <td><button class="toggle-btn" onclick="toggleLog('log-$idx')">View Log</button>
            <div id="log-$idx" class="log-panel">$log_content</div></td>
      </tr>
EOF
done

cat >> "$REPORT_FILE" << 'EOF'
    </tbody>
  </table>
</div>

<footer>FarmerChat Automated Test Suite &bull; Powered by Maestro</footer>

<script>
function toggleLog(id) {
  document.getElementById(id).classList.toggle('open');
}
function filterTests(status) {
  document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
  event.target.classList.add('active');
  document.querySelectorAll('.test-row').forEach(row => {
    if (status === 'all') { row.style.display = ''; return; }
    row.style.display = row.dataset.status === status ? '' : 'none';
  });
}
</script>
</body>
</html>
EOF

echo "Report generated: $REPORT_FILE"
