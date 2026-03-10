#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Running SMOKE test suite..."
echo ""

SMOKE_FLOWS=(
    "$PROJECT_DIR/flows/onboarding/01_splash_screen.yaml"
    "$PROJECT_DIR/flows/onboarding/02_language_selection.yaml"
    "$PROJECT_DIR/flows/home/07_home_screen_verification.yaml"
    "$PROJECT_DIR/flows/chat/11_chat_type_question.yaml"
    "$PROJECT_DIR/flows/navigation/15_drawer_navigation.yaml"
    "$PROJECT_DIR/flows/settings/19_settings_screen.yaml"
    "$PROJECT_DIR/flows/help/23_help_screen.yaml"
    "$PROJECT_DIR/flows/e2e/27_e2e_onboarding_to_chat.yaml"
)

TOTAL=${#SMOKE_FLOWS[@]}
PASSED=0
FAILED=0

for flow in "${SMOKE_FLOWS[@]}"; do
    NAME=$(basename "$flow" .yaml)
    echo "--- Running: $NAME ---"
    if ~/.maestro/bin/maestro --device emulator-5554 test "$flow" -e APP_ID=org.digitalgreen.farmer.chat -e LANGUAGE="English (Kenya)" -e LANGUAGE_CODE=en -e USER_NAME="Test Farmer" -e SHORT_NAME=TF -e WAIT_TIMEOUT=10000 2>&1; then
        PASSED=$((PASSED + 1))
        echo "  ✅ PASSED"
    else
        FAILED=$((FAILED + 1))
        echo "  ❌ FAILED"
    fi
    echo ""
done

echo "============================================"
echo "  SMOKE TEST RESULTS"
echo "  Total: $TOTAL | Passed: $PASSED | Failed: $FAILED"
echo "============================================"
