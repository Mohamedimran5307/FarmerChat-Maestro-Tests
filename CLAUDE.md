# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A [Maestro](https://maestro.mobile.dev/) UI test suite for the **FarmerChat** Android app
(`appId` = `org.digitalgreen.farmer.chat`). There is no application code here — only declarative
YAML flows, reusable sub-flows, and bash runners that orchestrate Maestro + adb and generate HTML/JSON reports.

## Test layout & conventions

- **`flows/home/TC_NN_*.yaml`** — the live test suite, numbered sequentially **TC_01–TC_35**. All
  runners discover tests by globbing `flows/home/TC_[0-9]*_*.yaml`, so adding/removing a flow doesn't
  require touching the runner — but if you delete one, renumber the rest to keep the sequence gapless.
- **`flows/onboarding/`** — legacy, *not* picked up by the runners. Ignore unless explicitly asked.
- Filename `TC_05_…` maps to CLI/report id `TC05` (underscore dropped). The runner derives the id
  from the leading digits of the filename.
- **`helpers/`** — reusable sub-flows invoked via `runFlow: ../../helpers/<name>.yaml`. Most tests
  start with `launchApp` + `runFlow: ../../helpers/complete_onboarding.yaml`. `complete_onboarding.yaml`
  is **idempotent** — it short-circuits if already on `home_screen` and tolerates legacy onboarding
  screens, so a flow can rerun without a clean app state. Prefer reusing helpers over inlining
  onboarding/sign-up/permission steps.

### Front-matter contract (parsed by `run_tests.sh`)

Above the `---` separator, flows carry both real Maestro keys and comment-encoded metadata the
runner scrapes for reporting and gating:

```yaml
appId: ${APP_ID}
name: "TC01 - Location-Based Personalization via Weather Widget"
# priority: P0          # P0/P1/P2 — defaults to P1 if absent
# description: ...      # one line; falls back to name minus "TC## - " prefix
# requires: PHONE_NUMBER,OTP_CODE   # see below
tags:
  - home
  - regression
```

- **`# requires:`** gates execution on env vars. Comma-separated; each entry is either `KEY`
  (must be non-empty and not an unresolved `${KEY}`) or `KEY=VALUE` (must equal). If any fails the
  test is **skipped with a yellow warning**, not run-and-failed. Sign-up flows use
  `# requires: PHONE_NUMBER,OTP_CODE`; the TTS test uses `# requires: LANGUAGE_CODE=en`.
- Always use `${APP_ID}` for `appId` (project convention — do not hardcode the package).
- Tags in use: `regression` (on all), plus `home`, `chat`, `settings`, `auth`, `onboarding`,
  `navigation`, `legal`, `help`, `error`, `camera`.

## Configuration & secrets

- **`config/env.yaml`** — committed non-secret defaults (`APP_ID`, `LANGUAGE`, `LANGUAGE_CODE`,
  `USER_NAME`, `SHORT_NAME`, `WAIT_TIMEOUT`, and placeholder phone/OTP).
- **`config/env.local.yaml`** — gitignored; holds real secrets (`PHONE_NUMBER`, `OTP_CODE`).
  Keys here **override** `env.yaml`. Copy from `config/env.local.example.yaml`. Without it,
  sign-up tests are skipped via their `# requires:` guards.
- `run_tests.sh` loads `env.yaml` then `env.local.yaml`, exports each key, and passes them all to
  Maestro as `--env KEY=VALUE`. The flows reference them as `${VAR}`.

## Running tests

`run_tests.sh` is the **single test runner** — used both locally and in CI (Maestro driver
management, retry with video capture, debug-output dirs, JSON+HTML report, optional Google Drive
upload). Run from repo root:

```bash
./run_tests.sh "Imran"                 # tester name; runs all discovered TCs
./run_tests.sh "Imran" TC01            # single test (id, not filename)
./run_tests.sh "Imran" TC01,TC03       # comma-separated subset
```

- Each test gets **up to 3 attempts** (`MAX_RETRIES=2`). Between attempts it `am force-stop`s the
  app but does **not** clear state — it relies on idempotent onboarding.
- Run a single flow directly with Maestro (bypassing the runner) — env flags are required because
  flows use `${...}` interpolation:

```bash
maestro --device emulator-5554 test flows/home/TC_01_weather_widget_location.yaml \
  -e APP_ID=org.digitalgreen.farmer.chat -e LANGUAGE_CODE=en -e USER_NAME="Test Farmer"
```

### Auxiliary scripts (`scripts/`)

- `scripts/run_failed.sh` — re-run only the TCs that failed in the last run.
- **Offline-network tests are self-contained.** TC_29/TC_30 (global no-internet error + retry),
  TC_31 (chat send offline → inline error + retry), and TC_32 (chat history offline → error + retry)
  each toggle the radio in-flow via `setAirplaneMode: enabled/disabled` and drive their own
  recovery — no manual network toggling and no required run order. (These were previously
  `_setup`/`_assert`/`_recovery` triplets; now consolidated into one flow apiece.)
- **Note on `device-farm/`:** it is a self-contained physical-device harness with its **own** copies
  of `run_tests.sh` / `tc_metadata.sh` / `generate_report.sh` under `device-farm/scripts/`. Its docs
  still describe an older 40-TC mapping — verify against the actual `flows/home/` glob, not those.

## App binary & CI

- **`app.apk`** is tracked via **git LFS** (`.gitattributes`). Note `.gitignore` also lists `*.apk`,
  but the committed binary is the LFS object — CI does `git lfs pull` then `adb install -r app.apk`.
- CI: `.github/workflows/maestro-tests.yml` runs on a **self-hosted macOS ARM64** runner (push/PR to
  `main`, daily cron, manual dispatch). It boots an emulator, grants permissions, disables animations,
  `adb forward tcp:7001`, then runs `./run_tests.sh "CI"`. The Post Summary step parses the
  `reports/FarmerChat_TestReport_*.json` summary block for the pass/fail counts.

## When editing flows

- Re-inspect the live screen hierarchy before targeting elements — prefer stable resource `id`s
  (e.g. `home_screen`, `language_item_${LANGUAGE_CODE}`, `chat_suggested_questions`) over text,
  which varies by language. Use the Maestro MCP tools (`list_devices` → `inspect_screen` → `run`)
  to validate against a running emulator.
- AI-response waits are slow: existing flows use `extendedWaitUntil` / `scrollUntilVisible` with
  long timeouts (up to 90s). Match that pattern rather than fixed sleeps.
- Guard optional/OEM-specific UI (permission dialogs, "Try again" error screens) with
  `runFlow: { when: { visible: ... } }` blocks, as `complete_onboarding.yaml` does.
