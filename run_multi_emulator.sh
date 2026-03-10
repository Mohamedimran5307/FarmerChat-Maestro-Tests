#!/bin/bash

APP_ID="org.digitalgreen.farmer.chat"
BASE_DIR="/Users/shaikmohamedimran/Documents/Maestro_automation_FarmerChat"
REPORT_DIR="$BASE_DIR/reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
COMPARISON_REPORT="$REPORT_DIR/comparison_report_${TIMESTAMP}.html"
APK_PATH="/Users/shaikmohamedimran/Documents/fc-compose/app/build/outputs/apk/stage/debug/app-stage-debug.apk"
EMULATOR_BIN="$HOME/Library/Android/sdk/emulator/emulator"
MAESTRO_SERVER="$BASE_DIR/../Maestro_Mobile_testing/maestro-server.apk"
MAESTRO_APP="$BASE_DIR/../Maestro_Mobile_testing/maestro-app.apk"

AVDS=("Pixel_4a_API_30" "Pixel_6_Pro_API_31" "Pixel_7_Pro")
LABELS=("Pixel 4a | Android 11 | 1536MB" "Pixel 6 Pro | Android 12 | 2048MB" "Pixel 7 Pro | Android 16 | 2560MB")
SHORT_LABELS=("Pixel4a_API30" "Pixel6Pro_API31" "Pixel7Pro_API36")

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

mkdir -p "$REPORT_DIR/multi_${TIMESTAMP}"

echo "================================================"
echo "  FarmerChat - Multi-Emulator Comparison Suite"
echo "  Testing on 3 devices (one at a time for stability)"
echo "  Started: $(date)"
echo "================================================"
echo ""

SUITE_START=$(date +%s)

kill_all_emulators() {
    adb devices | grep emulator | awk '{print $1}' | while read dev; do
        adb -s "$dev" emu kill > /dev/null 2>&1
    done
    sleep 3
    pkill -f "qemu-system-aarch64" 2>/dev/null
    sleep 2
}

setup_emulator() {
    local dev=$1
    local console_port=$2

    adb -s "$dev" install -r "$APK_PATH" > /dev/null 2>&1
    adb -s "$dev" install -r "$MAESTRO_SERVER" > /dev/null 2>&1
    adb -s "$dev" install -r "$MAESTRO_APP" > /dev/null 2>&1

    adb -s "$dev" shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS > /dev/null 2>&1
    adb -s "$dev" shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION > /dev/null 2>&1
    adb -s "$dev" shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION > /dev/null 2>&1
    adb -s "$dev" shell pm grant "$APP_ID" android.permission.RECORD_AUDIO > /dev/null 2>&1
    adb -s "$dev" shell settings put secure stylus_handwriting_enabled 0 > /dev/null 2>&1
    adb -s "$dev" shell settings put secure stylus_ever_used 0 > /dev/null 2>&1
    adb -s "$dev" shell appops set dev.mobile.maestro android:mock_location allow > /dev/null 2>&1

    local AUTH_TOKEN=$(cat "$HOME/.emulator_console_auth_token" 2>/dev/null)
    if [ -n "$AUTH_TOKEN" ]; then
        (echo "auth $AUTH_TOKEN"; echo "geo fix 35.9650 0.4717"; sleep 0.5) | nc -w 2 localhost "$console_port" > /dev/null 2>&1
    fi

    adb -s "$dev" shell mkdir -p /sdcard/Pictures/TestImages > /dev/null 2>&1
    adb -s "$dev" push "$BASE_DIR/test_assets/crop_disease.jpg" /sdcard/Pictures/TestImages/crop_disease.jpg > /dev/null 2>&1
    adb -s "$dev" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/TestImages/crop_disease.jpg > /dev/null 2>&1
}

reset_app() {
    local dev=$1
    local console_port=$2

    adb -s "$dev" shell pm clear "$APP_ID" > /dev/null 2>&1
    adb -s "$dev" shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS > /dev/null 2>&1
    adb -s "$dev" shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION > /dev/null 2>&1
    adb -s "$dev" shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION > /dev/null 2>&1
    adb -s "$dev" shell pm grant "$APP_ID" android.permission.RECORD_AUDIO > /dev/null 2>&1
    adb -s "$dev" shell settings put secure stylus_handwriting_enabled 0 > /dev/null 2>&1
    adb -s "$dev" shell settings put secure stylus_ever_used 0 > /dev/null 2>&1
    adb -s "$dev" shell appops set dev.mobile.maestro android:mock_location allow > /dev/null 2>&1

    local AUTH_TOKEN=$(cat "$HOME/.emulator_console_auth_token" 2>/dev/null)
    if [ -n "$AUTH_TOKEN" ]; then
        (echo "auth $AUTH_TOKEN"; echo "geo fix 35.9650 0.4717"; sleep 0.5) | nc -w 2 localhost "$console_port" > /dev/null 2>&1
    fi

    adb -s "$dev" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
    sleep 2
}

for emu_i in 0 1 2; do
    avd="${AVDS[$emu_i]}"
    label="${LABELS[$emu_i]}"
    short="${SHORT_LABELS[$emu_i]}"
    dev="emulator-5554"
    console_port=5554

    echo "════════════════════════════════════════════════"
    echo "  EMULATOR $((emu_i + 1))/3: $label"
    echo "════════════════════════════════════════════════"

    echo "  Killing existing emulators..."
    kill_all_emulators

    echo "  Starting $avd..."
    $EMULATOR_BIN -avd "$avd" -port 5554 -no-snapshot-save -no-audio -no-boot-anim -gpu auto &
    EMU_PID=$!

    echo -n "  Waiting for boot..."
    timeout_count=0
    while [ "$(adb -s "$dev" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
        sleep 3
        timeout_count=$((timeout_count + 1))
        if [ $timeout_count -gt 60 ]; then
            echo " TIMEOUT - skipping"
            continue 2
        fi
        echo -n "."
    done
    echo " BOOTED"

    sleep 3

    echo "  Installing APK and configuring..."
    setup_emulator "$dev" "$console_port"
    echo "  Setup complete"
    echo ""

    emu_log_dir="$REPORT_DIR/multi_${TIMESTAMP}/${short}"
    result_file="$REPORT_DIR/multi_${TIMESTAMP}/${short}_results.txt"
    mkdir -p "$emu_log_dir"

    emu_start=$(date +%s)

    tc_idx=0
    for flow in "${FLOWS[@]}"; do
        tc_idx=$((tc_idx + 1))
        filename=$(basename "$flow")
        test_name=$(grep -m1 'name:' "$BASE_DIR/$flow" 2>/dev/null | sed 's/.*name: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/')
        [ -z "$test_name" ] && test_name=$(basename "$flow" .yaml)

        echo "  [$tc_idx/${#FLOWS[@]}] $test_name"

        reset_app "$dev" "$console_port"

        t_start=$(date +%s)
        log_file="$emu_log_dir/${filename%.yaml}.log"

        maestro --device "$dev" test \
            -e APP_ID="$APP_ID" \
            -e LANGUAGE="English (Kenya)" \
            -e LANGUAGE_CODE=en \
            -e USER_NAME="Test Farmer" \
            -e SHORT_NAME=TF \
            -e WAIT_TIMEOUT=10000 \
            "$BASE_DIR/$flow" > "$log_file" 2>&1
        exit_code=$?

        t_end=$(date +%s)
        duration=$((t_end - t_start))

        status="PASSED"
        [ $exit_code -ne 0 ] && status="FAILED"

        echo "$test_name|$filename|$status|$duration" >> "$result_file"
        echo "    $status (${duration}s)"
    done

    emu_end=$(date +%s)
    emu_total=$((emu_end - emu_start))
    echo "TOTAL_DURATION|$emu_total" >> "$result_file"

    emu_min=$((emu_total / 60))
    emu_sec=$((emu_total % 60))
    echo ""
    echo "  $avd COMPLETE: ${emu_min}m ${emu_sec}s"
    echo ""
done

SUITE_END=$(date +%s)
SUITE_DURATION=$((SUITE_END - SUITE_START))
SUITE_MIN=$((SUITE_DURATION / 60))
SUITE_SEC=$((SUITE_DURATION % 60))

echo "================================================"
echo "  All emulators done in ${SUITE_MIN}m ${SUITE_SEC}s"
echo "  Generating comparison report..."
echo "================================================"

# ── Generate comparison HTML report ──
generate_comparison_report() {

    declare -a EMU_PASSED EMU_FAILED EMU_TOTAL_TIME

    for i in 0 1 2; do
        local label="${SHORT_LABELS[$i]}"
        local result_file="$REPORT_DIR/multi_${TIMESTAMP}/${label}_results.txt"
        local p=0 f=0 tdur=0

        while IFS='|' read -r name file status duration; do
            if [ "$name" = "TOTAL_DURATION" ]; then
                tdur=$file
                continue
            fi
            if [ "$status" = "PASSED" ]; then p=$((p+1)); else f=$((f+1)); fi
        done < "$result_file"

        EMU_PASSED[$i]=$p
        EMU_FAILED[$i]=$f
        EMU_TOTAL_TIME[$i]=$tdur
    done

    cat > "$COMPARISON_REPORT" << 'HTMLHEAD'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>FarmerChat - Multi-Emulator Comparison Report</title>
<style>
  :root {
    --bg: #0f172a; --surface: #1e293b; --surface2: #334155;
    --text: #f1f5f9; --text2: #94a3b8; --accent: #38bdf8;
    --green: #22c55e; --red: #ef4444;
    --border: #475569; --radius: 12px;
    --emu1: #818cf8; --emu2: #34d399; --emu3: #fb923c;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: var(--bg); color: var(--text); padding: 24px; line-height: 1.6;
  }
  .container { max-width: 1400px; margin: 0 auto; }
  h1 { font-size: 28px; margin-bottom: 4px; }
  h2 { font-size: 20px; margin: 32px 0 16px; }
  .subtitle { color: var(--text2); font-size: 14px; margin-bottom: 32px; }
  .emu-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-bottom: 32px; }
  .emu-card {
    background: var(--surface); border-radius: var(--radius); padding: 24px;
    border: 1px solid var(--border); position: relative; overflow: hidden;
  }
  .emu-card::before { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 4px; }
  .emu-card:nth-child(1)::before { background: var(--emu1); }
  .emu-card:nth-child(2)::before { background: var(--emu2); }
  .emu-card:nth-child(3)::before { background: var(--emu3); }
  .emu-card .emu-name { font-size: 16px; font-weight: 700; margin-bottom: 4px; }
  .emu-card .emu-spec { color: var(--text2); font-size: 12px; margin-bottom: 16px; }
  .emu-stats { display: flex; gap: 16px; flex-wrap: wrap; }
  .emu-stat { text-align: center; }
  .emu-stat .val { font-size: 28px; font-weight: 700; }
  .emu-stat .lbl { font-size: 11px; color: var(--text2); text-transform: uppercase; }
  .emu-stat.pass .val { color: var(--green); }
  .emu-stat.fail .val { color: var(--red); }
  .emu-stat.time .val { color: var(--accent); font-size: 20px; }
  .emu-stat.rate .val { color: var(--accent); }
  table { width: 100%; border-collapse: collapse; background: var(--surface); border-radius: var(--radius); overflow: hidden; }
  thead th {
    background: var(--surface2); padding: 12px 14px; text-align: center;
    font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; color: var(--text2);
  }
  thead th:first-child, thead th:nth-child(2) { text-align: left; }
  tbody td { padding: 10px 14px; border-bottom: 1px solid var(--border); font-size: 13px; text-align: center; }
  tbody td:first-child { text-align: center; color: var(--text2); width: 40px; }
  tbody td:nth-child(2) { text-align: left; }
  tbody tr:last-child td { border-bottom: none; }
  tbody tr:hover { background: rgba(56,189,248,0.05); }
  .badge { display: inline-block; padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; text-transform: uppercase; }
  .badge.pass { background: rgba(34,197,94,0.15); color: var(--green); }
  .badge.fail { background: rgba(239,68,68,0.15); color: var(--red); }
  .dur { color: var(--text2); font-size: 12px; }
  .fastest { color: var(--green); font-weight: 600; }
  .slowest { color: var(--red); opacity: 0.7; }
  .bar-chart { margin: 24px 0; }
  .bar-row { display: flex; align-items: center; margin-bottom: 8px; }
  .bar-label { width: 200px; font-size: 12px; color: var(--text2); text-align: right; padding-right: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .bar-group { display: flex; gap: 3px; flex: 1; align-items: center; }
  .bar { height: 16px; border-radius: 3px; min-width: 2px; position: relative; }
  .bar span { position: absolute; right: -30px; font-size: 10px; color: var(--text2); white-space: nowrap; top: 1px; }
  .bar.emu1 { background: var(--emu1); }
  .bar.emu2 { background: var(--emu2); }
  .bar.emu3 { background: var(--emu3); }
  .legend { display: flex; gap: 24px; margin-bottom: 16px; }
  .legend-item { display: flex; align-items: center; gap: 6px; font-size: 12px; color: var(--text2); }
  .legend-dot { width: 12px; height: 12px; border-radius: 3px; }
  .legend-dot.emu1 { background: var(--emu1); }
  .legend-dot.emu2 { background: var(--emu2); }
  .legend-dot.emu3 { background: var(--emu3); }
  .toggle-btn { background: none; border: 1px solid var(--border); color: var(--text2); padding: 3px 8px; border-radius: 6px; cursor: pointer; font-size: 11px; }
  .toggle-btn:hover { border-color: var(--accent); color: var(--accent); }
  .log-panel {
    display: none; padding: 12px; background: var(--bg); border-radius: 8px;
    margin-top: 6px; font-family: 'SF Mono', 'Fira Code', monospace; font-size: 11px;
    white-space: pre-wrap; word-break: break-all; color: var(--text2);
    max-height: 300px; overflow-y: auto; line-height: 1.6;
  }
  .log-panel.open { display: block; }
  .log-failed { color: var(--red); background: rgba(239,68,68,0.1); font-weight: 600; }
  .log-error-detail { color: var(--red); opacity: 0.85; }
  .log-completed { color: var(--green); }
  .fail-summary {
    margin-top: 4px; padding: 6px 10px; background: rgba(239,68,68,0.08);
    border-left: 3px solid var(--red); border-radius: 4px;
    font-size: 11px; color: var(--red); line-height: 1.5; white-space: pre-wrap;
  }
  footer { text-align: center; margin-top: 40px; color: var(--text2); font-size: 12px; }
</style>
</head>
<body>
<div class="container">
  <h1>FarmerChat Multi-Emulator Comparison Report</h1>
HTMLHEAD

    cat >> "$COMPARISON_REPORT" << EOF
  <p class="subtitle">Generated on $(date "+%B %d, %Y at %I:%M %p") &bull; Sequential per device &bull; Total wall time: ${SUITE_MIN}m ${SUITE_SEC}s</p>
  <div class="emu-grid">
EOF

    for i in 0 1 2; do
        local p=${EMU_PASSED[$i]}
        local f=${EMU_FAILED[$i]}
        local t=${EMU_TOTAL_TIME[$i]}
        local total=$((p + f))
        local rate=0; [ $total -gt 0 ] && rate=$(( (p * 100) / total ))
        local tm=$((t / 60)); local ts=$((t % 60))
        cat >> "$COMPARISON_REPORT" << EOF
    <div class="emu-card">
      <div class="emu-name">${AVDS[$i]}</div>
      <div class="emu-spec">${LABELS[$i]}</div>
      <div class="emu-stats">
        <div class="emu-stat pass"><div class="val">$p</div><div class="lbl">Passed</div></div>
        <div class="emu-stat fail"><div class="val">$f</div><div class="lbl">Failed</div></div>
        <div class="emu-stat rate"><div class="val">${rate}%</div><div class="lbl">Pass Rate</div></div>
        <div class="emu-stat time"><div class="val">${tm}m ${ts}s</div><div class="lbl">Total Time</div></div>
      </div>
    </div>
EOF
    done
    echo "  </div>" >> "$COMPARISON_REPORT"

    cat >> "$COMPARISON_REPORT" << 'EOF'
  <h2>Duration Comparison (per test)</h2>
  <div class="legend">
EOF
    for i in 0 1 2; do
        echo "    <div class=\"legend-item\"><div class=\"legend-dot emu$((i+1))\"></div>${LABELS[$i]}</div>" >> "$COMPARISON_REPORT"
    done
    echo '  </div><div class="bar-chart">' >> "$COMPARISON_REPORT"

    declare -a R0_NAMES R0_STATUS R0_DUR R1_NAMES R1_STATUS R1_DUR R2_NAMES R2_STATUS R2_DUR
    for i in 0 1 2; do
        local l="${SHORT_LABELS[$i]}"
        local rf="$REPORT_DIR/multi_${TIMESTAMP}/${l}_results.txt"
        local idx=0
        while IFS='|' read -r name file status duration; do
            [ "$name" = "TOTAL_DURATION" ] && continue
            case $i in
                0) R0_NAMES[$idx]="$name"; R0_STATUS[$idx]="$status"; R0_DUR[$idx]="$duration" ;;
                1) R1_NAMES[$idx]="$name"; R1_STATUS[$idx]="$status"; R1_DUR[$idx]="$duration" ;;
                2) R2_NAMES[$idx]="$name"; R2_STATUS[$idx]="$status"; R2_DUR[$idx]="$duration" ;;
            esac
            idx=$((idx + 1))
        done < "$rf"
    done

    local max_dur=1
    for idx in $(seq 0 $((${#FLOWS[@]} - 1))); do
        for d in "${R0_DUR[$idx]}" "${R1_DUR[$idx]}" "${R2_DUR[$idx]}"; do
            [ "${d:-0}" -gt "$max_dur" ] && max_dur="$d"
        done
    done

    for idx in $(seq 0 $((${#FLOWS[@]} - 1))); do
        local tname="${R0_NAMES[$idx]}"
        local d0="${R0_DUR[$idx]:-0}"; local d1="${R1_DUR[$idx]:-0}"; local d2="${R2_DUR[$idx]:-0}"
        local w0=$(( (d0 * 500) / max_dur )); local w1=$(( (d1 * 500) / max_dur )); local w2=$(( (d2 * 500) / max_dur ))
        [ $w0 -lt 2 ] && w0=2; [ $w1 -lt 2 ] && w1=2; [ $w2 -lt 2 ] && w2=2
        cat >> "$COMPARISON_REPORT" << EOF
    <div class="bar-row">
      <div class="bar-label" title="$tname">TC$(printf '%02d' $((idx+1)))</div>
      <div class="bar-group">
        <div class="bar emu1" style="width:${w0}px"><span>${d0}s</span></div>
        <div class="bar emu2" style="width:${w1}px; margin-left: 30px"><span>${d1}s</span></div>
        <div class="bar emu3" style="width:${w2}px; margin-left: 30px"><span>${d2}s</span></div>
      </div>
    </div>
EOF
    done
    echo '  </div>' >> "$COMPARISON_REPORT"

    cat >> "$COMPARISON_REPORT" << 'EOF'
  <h2>Detailed Results</h2>
  <table>
    <thead><tr><th>#</th><th>Test Name</th>
EOF
    for i in 0 1 2; do
        echo "        <th>${AVDS[$i]}<br><small style=\"font-weight:400\">${LABELS[$i]}</small></th>" >> "$COMPARISON_REPORT"
    done
    echo '      </tr></thead><tbody>' >> "$COMPARISON_REPORT"

    for idx in $(seq 0 $((${#FLOWS[@]} - 1))); do
        local tname="${R0_NAMES[$idx]}"; local num=$((idx + 1))
        local d0="${R0_DUR[$idx]:-0}" s0="${R0_STATUS[$idx]:-N/A}"
        local d1="${R1_DUR[$idx]:-0}" s1="${R1_STATUS[$idx]:-N/A}"
        local d2="${R2_DUR[$idx]:-0}" s2="${R2_STATUS[$idx]:-N/A}"
        local min_d=$d0 max_d=$d0
        [ "$d1" -lt "$min_d" ] 2>/dev/null && min_d=$d1; [ "$d2" -lt "$min_d" ] 2>/dev/null && min_d=$d2
        [ "$d1" -gt "$max_d" ] 2>/dev/null && max_d=$d1; [ "$d2" -gt "$max_d" ] 2>/dev/null && max_d=$d2

        echo "      <tr><td>$num</td><td><strong>$tname</strong></td>" >> "$COMPARISON_REPORT"

        for emu_i in 0 1 2; do
            local ds ds_val elabel
            elabel="${SHORT_LABELS[$emu_i]}"
            case $emu_i in 0) ds=$d0; ds_val=$s0 ;; 1) ds=$d1; ds_val=$s1 ;; 2) ds=$d2; ds_val=$s2 ;; esac
            local bcls="pass"; [ "$ds_val" = "FAILED" ] && bcls="fail"
            local dur_cls=""
            [ "$ds" -eq "$min_d" ] && [ "$min_d" -ne "$max_d" ] && dur_cls="fastest"
            [ "$ds" -eq "$max_d" ] && [ "$min_d" -ne "$max_d" ] && dur_cls="slowest"
            local log_id="log-${num}-${emu_i}"
            local filename=$(basename "${FLOWS[$idx]}")
            local logfile="$REPORT_DIR/multi_${TIMESTAMP}/${elabel}/${filename%.yaml}.log"

            if [ "$ds_val" = "FAILED" ] && [ -f "$logfile" ]; then
                local log_content=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g' "$logfile")
                cat >> "$COMPARISON_REPORT" << EOF
        <td><span class="badge $bcls">$ds_val</span><br><span class="dur $dur_cls">${ds}s</span><br>
          <button class="toggle-btn" onclick="document.getElementById('$log_id').classList.toggle('open')">Log</button>
          <div id="$log_id" class="log-panel open">$log_content</div></td>
EOF
            else
                echo "        <td><span class=\"badge $bcls\">$ds_val</span><br><span class=\"dur $dur_cls\">${ds}s</span></td>" >> "$COMPARISON_REPORT"
            fi
        done
        echo "      </tr>" >> "$COMPARISON_REPORT"
    done

    cat >> "$COMPARISON_REPORT" << 'JSEOF'
    </tbody></table>
</div>
<footer>FarmerChat Automated Test Suite &bull; Multi-Emulator Comparison &bull; Powered by Maestro</footer>
<script>
document.querySelectorAll('.log-panel').forEach(function(panel) {
  var raw = panel.textContent;
  var lines = raw.split('\n');
  var inFail = false, failBlock = [];
  var hl = lines.map(function(line) {
    if (/FAILED/.test(line)) { inFail = true; failBlock.push(line.trim()); return '<span class="log-failed">' + escH(line) + '</span>'; }
    if (inFail) { if (/COMPLETED|SKIPPED|^\s*$/.test(line) && failBlock.length > 1) { inFail = false; } else { failBlock.push(line.trim()); return '<span class="log-error-detail">' + escH(line) + '</span>'; } }
    if (/COMPLETED/.test(line)) return '<span class="log-completed">' + escH(line) + '</span>';
    return escH(line);
  }).join('\n');
  panel.innerHTML = hl;
});
function escH(s) { var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }
</script>
</body>
</html>
JSEOF

    echo "Comparison report: $COMPARISON_REPORT"
}

generate_comparison_report
echo ""
echo "Done! Opening report..."
open "$COMPARISON_REPORT"
