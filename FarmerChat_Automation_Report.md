# FarmerChat Mobile Automation -- Stakeholder Report

**Project:** FarmerChat (org.digitalgreen.farmer.chat)  
**App Version:** 4.0.0  
**Date:** March 2026  
**Prepared by:** Shaik Mohamed Imran

---

## 1. Executive Summary

A comprehensive end-to-end UI automation test suite has been built for the FarmerChat Android application using the **Maestro** framework. The suite covers **40 test cases** across 8 functional modules, running on both local emulators (via Jenkins CI/CD) and **BrowserStack real devices** (Samsung Galaxy S24, Android 14).

| Metric | Value |
|--------|-------|
| Total Test Cases Authored | 40 |
| BrowserStack-Compatible Tests | 35 |
| Reusable Helper Flows | 9 |
| Orchestration & Reporting Scripts | 8 |
| BrowserStack Real Device Pass Rate | **91% (32/35)** |
| Target Device (Cloud) | Samsung Galaxy S24 -- Android 14 |
| Target Device (Local) | Pixel 7 Pro Emulator -- API 34 |
| CI/CD Platform (Local) | Jenkins |
| CI/CD Platform (Cloud) | BrowserStack App Automate |

---

## 2. Functional Coverage

### 2.1 Module Breakdown

| Module | Test Cases | Priority Split | Coverage |
|--------|-----------|----------------|----------|
| **Onboarding** | TC01, TC02, TC03, TC04, TC31, TC32, TC37 | 2x P0, 1x P1, 4x P2 | Language selection, name entry, skip flows, legal links |
| **Home Feed** | TC05, TC07, TC08, TC09, TC10, TC12 | 2x P0, 4x P1 | Weather widget, feed scroll, Learn More, gender/crop cards |
| **Chat / AI** | TC06, TC11, TC13, TC14, TC24, TC26, TC28, TC30, TC34, TC35 | 5x P0, 5x P1 | Type question, AI response, share, save, listen, follow-up, gallery/camera upload, close chat |
| **Settings** | TC15, TC16, TC18, TC27 | 2x P0, 1x P1, 1x P2 | Display mode, update name, skip signup, logout |
| **Authentication** | TC17, TC19, TC25 | 3x P0 | Phone signup (settings & drawer), login with OTP |
| **Help & Support** | TC20, TC21, TC22 | 3x P2 | FAQ accordion, Terms of Use, Privacy Policy |
| **Navigation** | TC23, TC29, TC33, TC36 | 2x P1, 2x P2 | Language switch, location skip, recent chats, drawer home |
| **Error Handling** | TC38, TC39, TC40 | 2x P0, 1x P1 | Airplane mode recovery, chat retry, history retry |

### 2.2 Priority Distribution

| Priority | Count | Description |
|----------|-------|-------------|
| **P0 (Critical)** | 14 | Core user journeys -- onboarding, chat, auth, logout, error recovery |
| **P1 (High)** | 16 | Important feature validations -- feed content, sharing, settings |
| **P2 (Medium)** | 10 | Supporting features -- help pages, legal dialogs, display mode |

---

## 3. Test Architecture

### 3.1 Framework & Tools

| Component | Technology |
|-----------|-----------|
| Test Framework | Maestro (mobile UI automation) |
| App Under Test | FarmerChat Android (org.digitalgreen.farmer.chat) |
| Local Execution | Android Emulator (Pixel 7 Pro, API 34) |
| Cloud Execution | BrowserStack App Automate (Samsung Galaxy S24, Android 14) |
| CI/CD (Local) | Jenkins with automated HTML report generation |
| CI/CD (Cloud) | BrowserStack Maestro API v2 |
| Reporting | Custom HTML reports with video recordings, execution logs, priority badges |

### 3.2 Project Structure

```
Maestro_automation_FarmerChat/
├── flows/
│   ├── onboarding/          # 4 test flows (TC01-TC04)
│   └── home/                # 41 test flows (TC05-TC40 + sub-flows)
├── helpers/                 # 9 reusable sub-flows
│   ├── complete_onboarding.yaml
│   ├── navigate_to_settings.yaml
│   ├── navigate_to_help.yaml
│   ├── navigate_to_chat_history.yaml
│   ├── open_drawer.yaml
│   ├── weather_share_location_and_back_home.yaml
│   ├── launch_app.yaml
│   ├── launch_app_fresh.yaml
│   └── noop.yaml
├── scripts/
│   ├── run_all.sh           # Main orchestration + HTML report generator
│   ├── run_smoke.sh         # Smoke test subset
│   ├── run_failed.sh        # Re-run failed tests only
│   ├── tc_metadata.sh       # Test case metadata (descriptions, priorities, categories)
│   └── report_style.css     # External CSS for Jenkins-compatible reports
└── Jenkinsfile              # Pipeline definition
```

### 3.3 Key Design Decisions

- **Isolated test execution**: Each test clears app state and launches fresh, ensuring no cross-test contamination
- **Reusable helper flows**: Common sequences (onboarding, navigation) extracted into 9 shared helpers
- **Conditional recovery blocks**: `runFlow: when:` patterns handle transient UI states (loading screens, "Try again" dialogs, stylus bottom sheets)
- **Smart waits over fixed sleeps**: `extendedWaitUntil` with appropriate timeouts instead of arbitrary `sleep` calls
- **Video proof**: Each test execution is screen-recorded (local Jenkins runs)

---

## 4. BrowserStack Cloud Execution Results

### 4.1 Build Summary

| Field | Value |
|-------|-------|
| Build ID | `7824f1a16afa3c3968f2a80949a1ebeb6188486d` |
| Device | Samsung Galaxy S24 (Android 14.0) |
| Tests Executed | 35 |
| Passed | 32 |
| Failed | 3 |
| Skipped | 0 |
| Timed Out | 0 |
| **Pass Rate** | **91.4%** |

### 4.2 Detailed Results

#### Passed Tests (32/35)

| # | Test Case | Duration | Module |
|---|-----------|----------|--------|
| 1 | TC01 - Language Screen Load | 16s | Onboarding |
| 2 | TC02 - Language Selection & Navigation | 39s | Onboarding |
| 3 | TC03 - Skip Name Onboarding | 71s | Onboarding |
| 4 | TC04 - Enter Name Onboarding | 50s | Onboarding |
| 5 | TC05 - Weather Widget & Location | 55s | Home |
| 6 | TC06 - Type Question & AI Response | 147s | Chat |
| 7 | TC08 - Home Feed Scroll | 69s | Home |
| 8 | TC09 - Gender Selection Card | 66s | Home |
| 9 | TC09 - Home Input Type | 134s | Chat |
| 10 | TC10 - Home Weather Widget | 126s | Home |
| 11 | TC11 - Listen AI Response (TTS) | 114s | Chat |
| 12 | TC12 - Settings Display Mode | 51s | Settings |
| 13 | TC13 - Settings Update Name | 75s | Settings |
| 14 | TC14 - Settings Signup Phone | 53s | Auth |
| 15 | TC15 - Settings Signup Skip | 48s | Settings |
| 16 | TC16 - Drawer Signup Phone | 49s | Auth |
| 17 | TC17 - Help FAQ Accordion | 48s | Help |
| 18 | TC18 - Help Terms of Use | 50s | Help |
| 19 | TC19 - Help Privacy Policy | 63s | Help |
| 20 | TC20 - Drawer Change Language | 62s | Navigation |
| 21 | TC21 - Speak Button UI | 53s | Chat |
| 22 | TC23 - Login Phone OTP | 75s | Auth |
| 23 | TC24 - Chat History Screen | 114s | Chat |
| 24 | TC25 - Settings Logout | 85s | Settings |
| 25 | TC27 - Location Interstitial Skip | 61s | Navigation |
| 26 | TC28 - Chat Close Button | 81s | Chat |
| 27 | TC29 - Legal Terms of Use | 33s | Onboarding |
| 28 | TC30 - Legal Privacy Policy | 26s | Onboarding |
| 29 | TC31 - Drawer Recent Chat | 137s | Navigation |
| 30 | TC36 - Chat Follow-Up Question | 138s | Chat |
| 31 | TC37 - Drawer Home Navigation | 64s | Navigation |
| 32 | TC38 - Legal Dialog Close | 35s | Onboarding |

**Average test duration: ~72 seconds**

#### Failed Tests (3/35)

| Test Case | Duration | Root Cause | Severity |
|-----------|----------|------------|----------|
| TC07 - Home Screen Verification | 80s | "Learn More" feed card not present in server response on real device | Low -- server content timing |
| TC10 - Share AI Response | 105s | Share sheet text differs on Samsung Galaxy S24 vs emulator | Low -- device-specific UI |
| TC26 - Save AI Response | 100s | Save confirmation toast disappeared before assertion | Low -- timing sensitivity |

**All 3 failures are environment/timing-related, not functional bugs in the app.**

### 4.3 Tests Excluded from BrowserStack (5)

| Test Case | Reason |
|-----------|--------|
| TC32 - Photo Query Camera | Requires camera hardware simulation (not supported on BrowserStack) |
| TC33 - Error Screen Retry | Requires airplane mode toggle via ADB (not available on cloud) |
| TC34 - Chat Error Recovery | Requires network manipulation via ADB |
| TC35 - Chat History Retry | Requires network manipulation via ADB |
| TC09 - Photo Query Gallery | Requires pre-pushed gallery image via ADB |

---

## 5. CI/CD Pipeline

### 5.1 Jenkins (Local)

- **Automated pipeline** via `Jenkinsfile` with stages: Emulator Setup, App Install, Test Execution, Report Generation
- **HTML reports** with:
  - Executive summary with pass/fail/skip counts and progress bar
  - Per-test priority badges (P0/P1/P2) and module category tags
  - Embedded screen recording videos for each test case
  - Collapsible execution logs with color-coded step results
  - Environment details (device, OS, app version, Maestro version)
- **Content Security Policy** configured for inline styles, scripts, and video playback

### 5.2 BrowserStack (Cloud)

- **REST API integration** for app upload, test suite upload, and build triggering
- **Real device execution** on Samsung Galaxy S24 (Android 14)
- Tests packaged as self-contained zip with hardcoded configuration (no external environment dependency)
- Device logs and network logs enabled for debugging

---

## 6. Key Challenges & Solutions

| Challenge | Solution |
|-----------|----------|
| Emulator screen recordings were empty (0 bytes) | Switched from SIGTERM to SIGINT (`kill -2`) for graceful `screenrecord` shutdown |
| Jenkins CSP blocked inline styles and videos | Created persistent Groovy init script + external CSS file |
| BrowserStack env vars not propagating to sub-flows | Hardcoded all configuration values directly in YAML flows |
| BrowserStack test suite path resolution failures | Restructured zip with single parent folder as per BrowserStack docs |
| "Try out your stylus" overlay blocking input | Added conditional dismiss logic + ADB settings to disable stylus features |
| Server-side content changes (gender/crops cards) | Read-only assertions without clicking to preserve server state |
| Slow test execution on Jenkins | Replaced fixed sleeps with smart polling loops; batched ADB commands |

---

## 7. Recommendations & Next Steps

1. **Fix 3 BrowserStack failures**: Make assertions device-agnostic (flexible text matchers, longer toast wait times)
2. **Multi-device testing**: Expand BrowserStack runs to additional devices (Pixel 8, OnePlus, different Android versions)
3. **Scheduled runs**: Set up daily/nightly automated test runs on BrowserStack
4. **App version gating**: Integrate test suite into the release pipeline to block releases with P0 test failures
5. **Flaky test monitoring**: Track pass rates over time to identify and address intermittent failures
6. **Accessibility testing**: Add accessibility checks using BrowserStack's accessibility scanning tools

---

## 8. Summary

The FarmerChat automation suite provides **comprehensive coverage of 40 test scenarios** across all critical user journeys. With a **91% pass rate on real Samsung Galaxy S24 hardware** via BrowserStack, the suite validates that the app's core functionality -- onboarding, AI chat, authentication, navigation, and settings -- works reliably for end users. The 3 failures are attributable to environment differences, not application defects.

The infrastructure supports both local Jenkins execution with rich HTML reporting (including video proof) and cloud-based real device testing via BrowserStack, giving the team confidence in every release.

---

*Report generated: March 2026*  
*Framework: Maestro | Cloud: BrowserStack App Automate | CI: Jenkins*
