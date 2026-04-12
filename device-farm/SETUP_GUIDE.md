# FarmerChat DeviceFarm — Setup Guide

Step-by-step guide to set up your machine for running FarmerChat tests on a physical Android device.

## Prerequisites

- macOS (Apple Silicon or Intel)
- An Android phone (any manufacturer, Android 10+)
- USB cable (USB-C or Micro-USB depending on your phone)

## Step 1: Enable Developer Options on Your Phone

1. Open **Settings** on your Android phone
2. Scroll down to **About Phone**
3. Find **Build Number** and tap it **7 times**
4. You'll see a toast message: "You are now a developer!"

## Step 2: Enable USB Debugging

1. Go back to **Settings**
2. Open **Developer Options** (usually under Settings > System or Settings directly)
3. Toggle **USB Debugging** to ON
4. Confirm the dialog if prompted

## Step 3: Connect Your Phone

1. Plug your phone into your Mac via USB
2. On your phone, a dialog will appear: **"Allow USB debugging?"**
3. Check **"Always allow from this computer"**
4. Tap **Allow**

## Step 4: Clone the Repository

```bash
git clone https://github.com/Mohamedimran5307/FarmerChat-Maestro-Tests.git
cd FarmerChat-Maestro-Tests
```

## Step 5: Run Setup

```bash
bash setup.sh
```

This will:
- Check/install ADB (Android Debug Bridge)
- Check/install Maestro CLI (the test framework)
- Detect your connected device
- Install FarmerChat APK (if not already installed)
- Grant required permissions (camera, location, audio)
- Ask for your name (used to identify your results)
- Verify Git connectivity

## Step 6: Run Tests

```bash
bash run.sh
```

This will:
- Run all 40 test cases on your device
- Record screen for each test (optional)
- Generate HTML report + JSON results
- Auto-push results to the shared Git repo

Typical duration: **20-30 minutes** on a physical device.

## Common Issues

### "No Android device detected"

- Make sure USB debugging is enabled (Step 2)
- Try a different USB cable (some cables are charge-only)
- Run `adb devices` — you should see your device listed as "device" (not "unauthorized")
- If it shows "unauthorized", unplug and replug — tap "Allow" on the phone

### "FarmerChat is NOT installed"

- Install FarmerChat manually from the Play Store or internal distribution
- Or place the APK at `app/farmerchat.apk` and run `bash setup.sh` again

### "Maestro not found" after install

Add Maestro to your PATH:
```bash
export PATH="$HOME/.maestro/bin:$PATH"
```
Add this line to your `~/.zshrc` or `~/.bash_profile` to make it permanent.

### Samsung-specific: Extra permission dialogs

Samsung devices may show additional battery optimization or "Sleeping apps" dialogs. If a test fails because of these:
- Go to Settings > Battery > Background usage limits
- Exclude FarmerChat from sleeping/restricted apps

### Xiaomi-specific: USB debugging keeps turning off

Some Xiaomi devices turn off USB debugging after a reboot. Re-enable it in Developer Options.

### Tests fail with "airplane mode" errors (TC38-40)

These tests toggle airplane mode via ADB. If your device blocks this:
- Ensure USB debugging is active (airplane mode does NOT affect USB connections)
- Some heavily customized OEM ROMs may block `cmd connectivity` — skip these 3 tests if needed

### Git push fails

If two people push at the same time, one may fail. Just re-run:
```bash
cd /path/to/FarmerChat-Maestro-Tests
git pull --rebase origin main && git push origin main
```

## After Running

Your results appear in:
```
results/<your_name>/<Device_Model_AndroidVersion>/<timestamp>/
```

The dashboard team will pick these up automatically from the Git repo.
