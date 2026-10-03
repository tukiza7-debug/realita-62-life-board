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
for i in $(seq 1 60); do
  BOOT=$(adb -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n')
  if [ "$BOOT" = "1" ]; then
    echo "Boot completed after ${i}s"
    break
  fi
  sleep 1
done
# Give the package manager a moment to settle after boot.
sleep 10

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

echo "Waiting for app to settle (30s)..."
sleep 30

echo "=== Focused window (must contain id.realita62.lifeboard) ==="
FOCUS=$(adb -s emulator-5554 shell dumpsys window | grep -E "mCurrentFocus|mFocusedApp" | head -2)
echo "$FOCUS"
if ! echo "$FOCUS" | grep -q "id.realita62.lifeboard"; then
  echo "FAIL: app is not the focused window — main menu not visible"
  exit 1
fi

echo "=== AndroidRuntime errors (must be empty) ==="
adb -s emulator-5554 logcat -d -s AndroidRuntime:E > /tmp/are.txt || true
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
