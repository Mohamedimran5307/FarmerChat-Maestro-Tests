# FarmerChat Maestro Automation Framework

Automated UI test suite for the **FarmerChat** Android app (`org.digitalgreen.farmer.chat`)
using [Maestro](https://maestro.mobile.dev/).

## Project Structure

```
Maestro_automation_FarmerChat_End_to_End_Flow/
├── config/
│   ├── env.yaml                  # Committed non-secret defaults (APP_ID, LANGUAGE, …)
│   ├── env.local.example.yaml    # Template for secrets — copy to env.local.yaml
│   └── env.local.yaml            # Gitignored secrets (PHONE_NUMBER, OTP_CODE); overrides env.yaml
├── flows/
│   ├── home/                     # The live suite: TC_NN_*.yaml (sequential TC_01–TC_35)
│   └── onboarding/               # Legacy flows — NOT run by the runners
├── helpers/                      # Reusable sub-flows invoked via runFlow:
│   ├── launch_app.yaml
│   ├── launch_app_fresh.yaml
│   ├── complete_onboarding.yaml  # Idempotent: skips onboarding if already on home
│   ├── full_signup.yaml
│   ├── grant_location.yaml
│   ├── dismiss_system_popup.yaml
│   └── navigate_to_*.yaml
├── run_tests.sh                  # The test runner (driver mgmt, retry, video, reports) — used locally and in CI
├── scripts/
│   ├── run_failed.sh             # Re-run only previously failed TCs
│   └── report_style.css          # HTML report styling
├── device-farm/                  # Run the suite on a physical USB device
├── app.apk                       # App under test (tracked via git LFS)
├── reports/                      # Generated HTML/JSON reports (gitignored)
└── README.md
```

## Prerequisites

- Maestro CLI installed (`~/.maestro/bin/maestro`)
- Android emulator or device running (Pixel 7 Pro / API 31+ recommended)
- FarmerChat app installed — `adb install -r app.apk` (run `git lfs pull` first)

## Configuration & secrets

- `config/env.yaml` holds committed defaults and is loaded first.
- `config/env.local.yaml` (gitignored) holds real secrets and **overrides** `env.yaml`.
  Copy `config/env.local.example.yaml` to `config/env.local.yaml` and fill in `PHONE_NUMBER`
  and `OTP_CODE`. Without it, sign-up tests are **skipped** (see `# requires:` below), not failed.

| Variable      | Source     | Description                          |
|---------------|------------|--------------------------------------|
| APP_ID        | env.yaml   | App package name                     |
| LANGUAGE      | env.yaml   | Display language (e.g. English (Kenya)) |
| LANGUAGE_CODE | env.yaml   | Language id used in element ids (`en`) |
| USER_NAME     | env.yaml   | Onboarding display name              |
| SHORT_NAME    | env.yaml   | Avatar initials                      |
| WAIT_TIMEOUT  | env.yaml   | Max wait (ms)                        |
| PHONE_NUMBER  | env.local  | Sign-up phone number (secret)        |
| OTP_CODE      | env.local  | Sign-up OTP (secret)                 |

## Running tests

`run_tests.sh` is the single entry point for running the suite — locally and in CI. It discovers
every `flows/home/TC_NN_*.yaml`, loads env config, retries each test up to 3 times, captures video +
debug output, and generates an HTML/JSON report under `reports/`. It does not clear app state
between tests; it relies on the idempotent `complete_onboarding.yaml` helper.

```bash
./run_tests.sh "Imran"            # tester name; run the whole suite
./run_tests.sh "Imran" TC01       # single test by ID (not filename)
./run_tests.sh "Imran" TC01,TC03  # comma-separated subset
```

### Run a single flow directly with Maestro

Flows interpolate `${...}` variables, so env flags are required:

```bash
maestro --device emulator-5554 test flows/home/TC_01_weather_widget_location.yaml \
  -e APP_ID=org.digitalgreen.farmer.chat -e LANGUAGE_CODE=en -e USER_NAME="Test Farmer"
```

## Flow conventions

Each flow's front-matter (above `---`) carries Maestro keys plus comment-encoded metadata that
`run_tests.sh` scrapes:

```yaml
appId: ${APP_ID}                              # always use ${APP_ID}, never hardcode
name: "TC01 - Location-Based Personalization via Weather Widget"
# priority: P0                                # P0/P1/P2 (defaults to P1)
# description: ...                            # one line, used in reports
# requires: PHONE_NUMBER,OTP_CODE             # gate execution on env vars (see below)
tags:
  - home
  - regression
```

- **`# requires:`** — comma-separated env-var gates. `KEY` requires a non-empty resolved value;
  `KEY=VALUE` requires equality. If any entry fails, the test is **skipped with a warning** rather
  than run-and-failed (cleaner signal than an OTP timeout 30s into a sign-up flow).
- File `TC_05_…` maps to report/CLI id **`TC05`** (underscore dropped, leading zero stripped).
- Most tests start with `launchApp` + `runFlow: ../../helpers/complete_onboarding.yaml`. Reuse
  helpers rather than inlining onboarding, sign-up, or permission handling.

## Test coverage

The live suite lives entirely in `flows/home/`. Tests are tagged by functional area; every test
also carries `regression`. Tests are numbered sequentially **TC01–TC35**.

| Area              | Tags                | Example TCs                                  |
|-------------------|---------------------|----------------------------------------------|
| Home feed         | `home`, `onboarding`| TC01, TC03–05, TC07, TC19, TC24              |
| Chat & AI         | `chat`              | TC02, TC06, TC08–09, TC23, TC25, TC33        |
| Settings          | `settings`          | TC10–13, TC22                                |
| Sign-up / Auth    | `auth`              | TC04, TC07, TC12–14, TC20–22, TC32           |
| Navigation/Drawer | `navigation`        | TC14, TC18, TC21, TC34                       |
| Help              | `help`              | TC15–17                                      |
| Legal (1st launch)| `legal`             | TC26–27, TC35                                |
| Error recovery    | `error`             | TC29–TC32                                    |
| Camera            | `camera`            | TC28                                         |

> The offline-network tests (TC29–TC32) are self-contained: each toggles the radio in-flow via
> `setAirplaneMode` and drives its own retry/recovery — no manual network toggling, no required order.

## Reports

`run_tests.sh` writes `reports/FarmerChat_TestReport_<Tester>_<date>.html` and a matching `.json`
summary, plus a `reports/logs_<date>_<time>/` directory with per-attempt logs, debug output, and
(when capture succeeds) per-attempt video. `reports/` is gitignored.

## Physical device testing

See `device-farm/` (`bash device-farm/setup.sh` then `bash device-farm/run.sh`) to run the suite
on a USB-connected Android device and auto-push results.
