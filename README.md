# FarmerChat Maestro Automation Framework

Automated UI test suite for the **FarmerChat** Android app using [Maestro](https://maestro.mobile.dev/).

## Project Structure

```
Maestro_automation_FarmerChat/
├── config/
│   └── env.yaml                  # Shared environment variables
├── flows/
│   ├── onboarding/               # TC01-TC06: Splash, Language, Name
│   ├── home/                     # TC07-TC10: Home screen, Feed, Weather
│   ├── chat/                     # TC11-TC14: Chat, Follow-ups, Navigation
│   ├── navigation/               # TC15-TC18: Drawer, History
│   ├── settings/                 # TC19-TC22: Appearance, Name, Language
│   ├── help/                     # TC23-TC25: Help, Terms, Privacy
│   ├── auth/                     # TC26: Sign up flow
│   └── e2e/                      # TC27-TC29: End-to-end journeys
├── helpers/                      # Reusable sub-flows
│   ├── launch_app.yaml
│   ├── launch_app_fresh.yaml
│   ├── complete_onboarding.yaml
│   ├── open_drawer.yaml
│   └── navigate_to_*.yaml
├── scripts/
│   ├── run_all.sh                # Run all tests + generate HTML report
│   └── run_smoke.sh              # Run smoke tests only
├── reports/                      # Generated test reports
└── README.md
```

## Prerequisites

- Maestro CLI installed (`~/.maestro/bin/maestro`)
- Android emulator running (Pixel 6 Pro API 31 recommended)
- FarmerChat app installed (`org.digitalgreen.farmer.chat`)

## Running Tests

### Run all tests with HTML report
```bash
chmod +x scripts/run_all.sh
./scripts/run_all.sh
```

### Run smoke tests only
```bash
chmod +x scripts/run_smoke.sh
./scripts/run_smoke.sh
```

### Run a single flow
```bash
~/.maestro/bin/maestro test flows/onboarding/01_splash_screen.yaml \
  -e APP_ID=org.digitalgreen.farmer.chat \
  -e LANGUAGE="English (Kenya)" \
  -e USER_NAME="Test Farmer"
```

### Run by category
```bash
~/.maestro/bin/maestro test flows/onboarding/ \
  -e APP_ID=org.digitalgreen.farmer.chat \
  -e LANGUAGE="English (Kenya)" \
  -e USER_NAME="Test Farmer"
```

## Test Coverage

| Category    | Tests   | Type       |
|-------------|---------|------------|
| Onboarding  | TC01-06 | Smoke + Regression |
| Home        | TC07-10 | Smoke + Regression |
| Chat        | TC11-14 | Smoke + Regression |
| Navigation  | TC15-18 | Smoke + Regression |
| Settings    | TC19-22 | Smoke + Regression |
| Help        | TC23-25 | Smoke + Regression |
| Auth        | TC26    | Regression |
| E2E         | TC27-29 | Smoke + Regression |
| **Total**   | **29**  |            |

## Environment Variables

| Variable     | Default              | Description                |
|-------------|----------------------|----------------------------|
| APP_ID      | org.digitalgreen.farmer.chat | App package name   |
| LANGUAGE    | English (Kenya)      | Language to select         |
| USER_NAME   | Test Farmer          | Name for onboarding        |
| WAIT_TIMEOUT| 10000                | Max wait in milliseconds   |

## Reports

HTML reports are generated in `reports/<timestamp>/report.html` after each full run.
Each test also produces a `.log` file in the same directory.
