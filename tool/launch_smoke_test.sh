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

echo "Installing APK..."
adb -s emulator-5554 install -r -t "$APK"

echo "Clearing logcat..."
adb -s emulator-5554 logcat -c

echo "Launching MainActivity..."
adb -s emulator-5554 shell am start -n id.realita62.lifeboard/.MainActivity

echo "Waiting for app to settle (20s)..."
sleep 20

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
