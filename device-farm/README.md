# FarmerChat DeviceFarm — Physical Device Testing

Run the FarmerChat Maestro test suite on your physical Android device connected via USB. Results auto-push to this Git repo.

## Quick Start

```bash
# Clone the repo (if you haven't already)
git clone https://github.com/Mohamedimran5307/FarmerChat-Maestro-Tests.git
cd FarmerChat-Maestro-Tests/device-farm

# First time only (~5 minutes):
bash setup.sh

# Every test run (one command):
bash run.sh
```

## What It Does

1. Detects your physical Android device via USB
2. Runs all 40 test cases across 8 functional areas
3. Generates `device_info.json`, `test_results.json`, and `report.html`
4. Auto-pushes results to the shared Git repo

## Prerequisites

- macOS
- Android device with USB debugging enabled
- USB cable

`setup.sh` handles installing Maestro CLI and ADB if not already present.

## Results Structure

Results are pushed to `results/` at the repo root:

```
results/
  <your_name>/
    <Manufacturer_Model_AndroidVersion>/
      <timestamp>/
        device_info.json      # Device metadata (for dashboard)
        test_results.json     # TC pass/fail data (for dashboard)
        report.html           # Human-readable report
```

## Test Categories (40 TCs)

| Category | Tests | Priority |
|----------|-------|----------|
| Onboarding | TC01-04, TC31-32, TC37 | P0-P2 |
| Home Feed | TC05, TC07-10, TC12 | P0-P1 |
| Chat | TC06, TC11, TC13-14, TC24, TC26, TC28, TC30, TC34-35 | P0-P1 |
| Settings | TC15-18, TC27 | P1-P2 |
| Authentication | TC19, TC25-26 | P0 |
| Help & Legal | TC20-22 | P2 |
| Navigation | TC23, TC29, TC33, TC36 | P1 |
| Error Recovery | TC38-40 | P0-P1 |

## Troubleshooting

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed setup instructions and common issues.

## Maintainer

Shaik Mohamed Imran — for device-specific issues or script fixes, reach out directly.
