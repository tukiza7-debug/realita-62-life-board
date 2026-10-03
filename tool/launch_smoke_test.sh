#!/usr/bin/env bash
# Launch smoke test for the Realita +62 Life Board app on an Android emulator.
# Run inside reactivecircus/android-emulator-runner's `script:` step.
# Expects: emulator-5554 is online, $GITHUB_WORKSPACE/build/app/outputs/
# flutter-apk/app-debug.apk exists.
set -euo pipefail

APK="${GITHUB_WORKSPACE}/build/app/outputs/flutter-apk/app-debug.apk"

if [ ! -f "$APK" ]; then
  echo "FAIL: APK not found at $APK"
  exit 1
fi

echo "Waiting for emulator to be fully ready (sys.boot_completed=1)..."
for i in $(seq 1 90); do
  BOOT=$(adb -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n')
  if [ "$BOOT" = "1" ]; then
    echo "Boot completed after ${i}s"
    break
  fi
  sleep 1
done
# Settle a bit longer.
sleep 15

# Skip the setup wizard so FallbackHome is not the foreground activity.
# Without this, the smoke test sees FallbackHome (SetupWizard) as the
# focused window instead of our app.
echo "Skipping setup wizard..."
adb -s emulator-5554 shell settings put global device_provisioned 1
adb -s emulator-5554 shell settings put secure user_setup_complete 1
# Stop the setup wizard if it is running.
adb -s emulator-5554 shell am force-stop com.google.android.setupwizard 2>/dev/null || true
adb -s emulator-5554 shell am force-stop com.android.settings 2>/dev/null || true
sleep 2

echo "Installing APK (with retries)..."
INSTALLED=0
for i in $(seq 1 3); do
  echo "Install attempt ${i}..."
  if adb -s emulator-5554 install -r -t "$APK" 2>&1; then
    INSTALLED=1
    break
  fi
  echo "Install attempt ${i} failed; retrying in 5s..."
  sleep 5
done
if [ "$INSTALLED" != "1" ]; then
  echo "FAIL: could not install APK after 3 attempts"
  exit 1
fi

echo "Clearing logcat..."
adb -s emulator-5554 logcat -c

echo "Launching MainActivity..."
adb -s emulator-5554 shell am start -n id.realita62.lifeboard/.MainActivity
sleep 5

# Some launches are slow on the software-GPU runner; retry the focus check
# up to 6 times with 10s gaps (total 60s after launch).
echo "Checking focused window (retries up to 6x with 10s gaps)..."
FOCUS=""
for i in $(seq 1 6); do
  FOCUS=$(adb -s emulator-5554 shell dumpsys window 2>/dev/null | grep -E "mCurrentFocus|mFocusedApp" | head -2)
  if echo "$FOCUS" | grep -q "id.realita62.lifeboard"; then
    echo "OK on attempt ${i}: focused window is ours"
    break
  fi
  echo "Attempt ${i}: focused window is not ours yet:"
  echo "$FOCUS"
  sleep 10
done

echo "=== Final focused window ==="
echo "$FOCUS"
if ! echo "$FOCUS" | grep -q "id.realita62.lifeboard"; then
  echo "FAIL: app is not the focused window — main menu not visible"
  echo "=== AndroidRuntime errors ==="
  adb -s emulator-5554 logcat -d -s AndroidRuntime:E 2>/dev/null || true
  echo "=== FATAL EXCEPTION / ClassNotFoundException ==="
  adb -s emulator-5554 logcat -d 2>/dev/null | grep -E "FATAL EXCEPTION|ClassNotFoundException" || echo "(none)"
  echo "=== Last 30 lines of full logcat ==="
  adb -s emulator-5554 logcat -d 2>/dev/null | tail -30
  exit 1
fi

echo "=== AndroidRuntime errors (must be empty) ==="
adb -s emulator-5554 logcat -d -s AndroidRuntime:E > /tmp/are.txt 2>/dev/null || true
if [ -s /tmp/are.txt ]; then
  echo "FAIL: AndroidRuntime errors in logcat"
  cat /tmp/are.txt
  exit 1
fi
echo "(none)"

echo "=== FATAL EXCEPTION / ClassNotFoundException (must be empty) ==="
adb -s emulator-5554 logcat -d | grep -E "FATAL EXCEPTION|ClassNotFoundException" > /tmp/fatal.txt || true
if [ -s /tmp/fatal.txt ]; then
  echo "FAIL: FATAL EXCEPTION in logcat"
  cat /tmp/fatal.txt
  exit 1
fi
echo "(none)"

echo "OK: app launched, focused window is ours, no fatal exceptions"
