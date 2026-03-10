#!/bin/bash

DEVICE="emulator-5554"
BASE_DIR="/Users/shaikmohamedimran/Documents/Maestro_automation_FarmerChat"
REPORT_DIR="$BASE_DIR/reports"
LOG_DIR="$REPORT_DIR/logs_20260307_195755"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$REPORT_DIR/test_report_${TIMESTAMP}.html"

FLOWS=(
    "flows/onboarding/01_language_screen.yaml"
    "flows/onboarding/02_language_selection.yaml"
    "flows/onboarding/03_skip_name.yaml"
    "flows/onboarding/04_enter_name.yaml"
    "flows/home/05_weather_widget_location.yaml"
    "flows/home/06_type_question_ai_response.yaml"
    "flows/home/07_home_screen_verification.yaml"
    "flows/home/08_home_feed_scroll.yaml"
    "flows/home/09_photo_query_gallery.yaml"
    "flows/home/10_share_ai_response.yaml"
    "flows/home/11_listen_ai_response.yaml"
    "flows/home/12_settings_display_mode.yaml"
    "flows/home/13_settings_update_name.yaml"
    "flows/home/14_settings_signup_phone.yaml"
    "flows/home/15_settings_signup_skip.yaml"
    "flows/home/16_drawer_signup_phone.yaml"
    "flows/home/17_help_faq_accordion.yaml"
    "flows/home/18_help_terms_of_use.yaml"
    "flows/home/19_help_privacy_policy.yaml"
    "flows/home/20_drawer_change_language.yaml"
    "flows/home/21_speak_button_ui.yaml"
    "flows/home/22_home_question_cards.yaml"
    "flows/home/23_login_phone_otp.yaml"
)

DURATIONS=(10 31 29 51 45 108 39 60 75 82 86 42 52 47 41 40 42 41 42 41 49 82 72)

TOTAL=23
PASSED=0
FAILED=0

declare -a RESULTS

for i in "${!FLOWS[@]}"; do
    flow="${FLOWS[$i]}"
    filename=$(basename "$flow")
    log_file="$LOG_DIR/${filename%.yaml}.log"
    duration="${DURATIONS[$i]}"

    test_name=$(grep -m1 'name:' "$BASE_DIR/$flow" 2>/dev/null | sed 's/.*name: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/')
    [ -z "$test_name" ] && test_name=$(basename "$flow" .yaml)

    if [ -f "$log_file" ] && grep -q "FAILED" "$log_file" 2>/dev/null; then
        status="FAILED"
        status_class="fail"
        FAILED=$((FAILED + 1))
    else
        status="PASSED"
        status_class="pass"
        PASSED=$((PASSED + 1))
    fi

    RESULTS+=("$test_name|$filename|$status|$status_class|$duration|$log_file")
done

TOTAL_DURATION=1343
TOTAL_MIN=$((TOTAL_DURATION / 60))
TOTAL_SEC=$((TOTAL_DURATION % 60))
PASS_RATE=$(( (PASSED * 100) / TOTAL ))

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
  .summary-card.rate .value { color: var(--accent); }
  .summary-card.time .value { color: var(--text2); font-size: 24px; }
  .progress-bar {
    width: 100%; height: 8px; background: var(--surface2); border-radius: 4px;
    margin-bottom: 32px; overflow: hidden; display: flex;
  }
  .progress-pass { background: var(--green); }
  .progress-fail { background: var(--red); }
  .section-title { font-size: 20px; margin-bottom: 16px; }
  table { width: 100%; border-collapse: collapse; background: var(--surface); border-radius: var(--radius); overflow: hidden; }
  thead th {
    background: var(--surface2); padding: 14px 16px; text-align: left;
    font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; color: var(--text2);
  }
  tbody td { padding: 14px 16px; border-bottom: 1px solid var(--border); font-size: 14px; }
  tbody tr:last-child td { border-bottom: none; }
  tbody tr:hover { background: rgba(56, 189, 248, 0.05); }
  .badge {
    display: inline-block; padding: 4px 12px; border-radius: 20px;
    font-size: 12px; font-weight: 600; text-transform: uppercase;
  }
  .badge.pass { background: rgba(34, 197, 94, 0.15); color: var(--green); }
  .badge.fail { background: rgba(239, 68, 68, 0.15); color: var(--red); }
  .duration { color: var(--text2); font-size: 13px; }
  .category-badge {
    display: inline-block; padding: 2px 8px; border-radius: 6px;
    font-size: 11px; background: var(--surface2); color: var(--text2); margin-right: 4px;
  }
  .toggle-btn {
    background: none; border: 1px solid var(--border); color: var(--text2);
    padding: 4px 10px; border-radius: 6px; cursor: pointer; font-size: 12px;
  }
  .toggle-btn:hover { border-color: var(--accent); color: var(--accent); }
  .log-panel {
    display: none; padding: 16px; background: var(--bg); border-radius: 8px;
    margin-top: 8px; font-family: 'SF Mono', 'Fira Code', monospace; font-size: 12px;
    white-space: pre-wrap; word-break: break-all; color: var(--text2);
    max-height: 500px; overflow-y: auto; line-height: 1.8;
  }
  .log-panel.open { display: block; }
  .log-completed { color: var(--green); }
  .log-failed { color: var(--red); background: rgba(239,68,68,0.1); font-weight: 600; }
  .log-error-detail { color: var(--red); opacity: 0.85; }
  .log-skipped { color: #64748b; font-style: italic; }
  .fail-summary {
    margin-top: 6px; padding: 8px 12px; background: rgba(239,68,68,0.08);
    border-left: 3px solid var(--red); border-radius: 4px;
    font-size: 12px; color: var(--red); line-height: 1.6; white-space: pre-wrap;
  }
  .filter-bar { display: flex; gap: 8px; margin-bottom: 16px; flex-wrap: wrap; }
  .filter-btn {
    padding: 6px 16px; border-radius: 20px; border: 1px solid var(--border);
    background: transparent; color: var(--text2); cursor: pointer; font-size: 13px;
    transition: all 0.2s;
  }
  .filter-btn:hover, .filter-btn.active { border-color: var(--accent); color: var(--accent); background: rgba(56,189,248,0.1); }
  footer { text-align: center; margin-top: 40px; color: var(--text2); font-size: 12px; }
</style>
</head>
<body>
<div class="container">
  <h1>FarmerChat Test Report</h1>
HTMLHEAD

cat >> "$REPORT_FILE" << EOF
  <p class="subtitle">Generated on $(date "+%B %d, %Y at %I:%M %p") &bull; Device: $DEVICE &bull; Duration: ${TOTAL_MIN}m ${TOTAL_SEC}s</p>

  <div class="summary-grid">
    <div class="summary-card total"><div class="value">$TOTAL</div><div class="label">Total Tests</div></div>
    <div class="summary-card pass"><div class="value">$PASSED</div><div class="label">Passed</div></div>
    <div class="summary-card fail"><div class="value">$FAILED</div><div class="label">Failed</div></div>
    <div class="summary-card rate"><div class="value">${PASS_RATE}%</div><div class="label">Pass Rate</div></div>
    <div class="summary-card time"><div class="value">${TOTAL_MIN}m ${TOTAL_SEC}s</div><div class="label">Total Time</div></div>
  </div>

  <div class="progress-bar">
    <div class="progress-pass" style="width:${PASS_RATE}%"></div>
    <div class="progress-fail" style="width:$(( (FAILED * 100) / TOTAL ))%"></div>
  </div>

  <h2 class="section-title">Test Results</h2>
  <div class="filter-bar">
    <button class="filter-btn active" onclick="filterTests('all')">All</button>
    <button class="filter-btn" onclick="filterTests('pass')">Passed</button>
    <button class="filter-btn" onclick="filterTests('fail')">Failed</button>
  </div>
  <table>
    <thead>
      <tr>
        <th style="width:40px">#</th>
        <th>Test Name</th>
        <th>Category</th>
        <th>Status</th>
        <th>Duration</th>
        <th>Log</th>
      </tr>
    </thead>
    <tbody>
EOF

idx=0
for result in "${RESULTS[@]}"; do
    idx=$((idx + 1))
    IFS='|' read -r name file status status_class duration log_path <<< "$result"

    category=""
    case "$file" in
        0[1-4]*) category="onboarding" ;;
        0[5-8]*) category="home" ;;
        09*|1[0-1]*) category="chat" ;;
        1[2-3]*) category="settings" ;;
        1[4-6]*|23*) category="auth" ;;
        17*|18*|19*) category="help" ;;
        20*|21*) category="navigation" ;;
        22*) category="home" ;;
    esac

    log_escaped=""
    if [ -f "$log_path" ]; then
        log_escaped=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g' "$log_path")
    fi

    cat >> "$REPORT_FILE" << ROWEOF
      <tr class="test-row" data-status="$status_class">
        <td style="color:var(--text2)">$idx</td>
        <td><strong>$name</strong><div class="inline-summary" id="summary-$idx"></div></td>
        <td><span class="category-badge">$category</span></td>
        <td><span class="badge $status_class">$status</span></td>
        <td class="duration">${duration}s</td>
        <td><button class="toggle-btn" onclick="toggleLog('log-$idx')">Show Log</button>
            <div id="log-$idx" class="log-panel">$log_escaped</div></td>
      </tr>
ROWEOF
done

cat >> "$REPORT_FILE" << 'JSEOF'
    </tbody>
  </table>
</div>

<footer>FarmerChat Automated Test Suite &bull; Powered by Maestro</footer>

<script>
function toggleLog(id) {
  var el = document.getElementById(id);
  el.classList.toggle('open');
}
function filterTests(status) {
  document.querySelectorAll('.filter-btn').forEach(function(b){b.classList.remove('active')});
  event.target.classList.add('active');
  document.querySelectorAll('.test-row').forEach(function(row){
    if (status === 'all') { row.style.display = ''; return; }
    row.style.display = row.dataset.status === status ? '' : 'none';
  });
}

document.querySelectorAll('.log-panel').forEach(function(panel, i) {
  var raw = panel.textContent;
  var lines = raw.split('\n');
  var inFailBlock = false;
  var failBlock = [];

  var highlighted = lines.map(function(line) {
    if (/FAILED/.test(line)) {
      inFailBlock = true;
      failBlock = [line.trim()];
      return '<span class="log-failed">' + escH(line) + '</span>';
    }
    if (inFailBlock) {
      if (/COMPLETED|SKIPPED|^\s*$/.test(line) && failBlock.length > 1) {
        inFailBlock = false;
      } else {
        failBlock.push(line.trim());
        return '<span class="log-error-detail">' + escH(line) + '</span>';
      }
    }
    if (/COMPLETED/.test(line)) return '<span class="log-completed">' + escH(line) + '</span>';
    if (/SKIPPED/.test(line)) return '<span class="log-skipped">' + escH(line) + '</span>';
    return escH(line);
  }).join('\n');
  panel.innerHTML = highlighted;

  var idx = i + 1;
  var summaryEl = document.getElementById('summary-' + idx);
  if (summaryEl) {
    var row = panel.closest('.test-row');
    var st = row ? row.dataset.status : '';
    if (st === 'fail' && failBlock.length) {
      summaryEl.innerHTML = '<div class="fail-summary">' + failBlock.map(function(l){return escH(l)}).join('\n') + '</div>';
      panel.classList.add('open');
    }
  }
});

function escH(s) {
  var d = document.createElement('div'); d.textContent = s; return d.innerHTML;
}
</script>
</body>
</html>
JSEOF

echo "HTML report saved to: $REPORT_FILE"
