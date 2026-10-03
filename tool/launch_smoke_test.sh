#!/usr/bin/env bash
# Launch smoke test for the Realita +62 Life Board app on an Android emulator.
# Run inside reactivecircus/android-emulator-runner's `script:` step.
# Expects: emulator-5554 is online, $GITHUB_WORKSPACE/build/app/outputs/
# flutter-apk/app-debug.apk exists.
set -euo pipefail

APK="${GITHUB_WORKSPACE}/build/app/outputs/flutter-apk/app-debug.apk"
ADB="adb -s emulator-5554"

echo "Installing APK..."
"$ADB" install -r -t "$APK"

echo "Clearing logcat..."
"$ADB" logcat -c

echo "Launching MainActivity..."
"$ADB" shell am start -n id.realita62.lifeboard/.MainActivity

echo "Waiting for app to settle (20s)..."
sleep 20

echo "=== Focused window (must contain id.realita62.lifeboard) ==="
FOCUS=$("$ADB" shell dumpsys window | grep -E "mCurrentFocus|mFocusedApp" | head -2)
echo "$FOCUS"
if ! echo "$FOCUS" | grep -q "id.realita62.lifeboard"; then
  echo "FAIL: app is not the focused window — main menu not visible"
  exit 1
fi

echo "=== AndroidRuntime errors (must be empty) ==="
"$ADB" logcat -d -s AndroidRuntime:E | tee /tmp/are.txt || true
if [ -s /tmp/are.txt ]; then
  echo "FAIL: AndroidRuntime errors in logcat"
  cat /tmp/are.txt
  exit 1
fi

echo "=== FATAL EXCEPTION / ClassNotFoundException (must be empty) ==="
"$ADB" logcat -d | grep -E "FATAL EXCEPTION|ClassNotFoundException" | tee /tmp/fatal.txt || true
if [ -s /tmp/fatal.txt ]; then
  echo "FAIL: FATAL EXCEPTION in logcat"
  cat /tmp/fatal.txt
  exit 1
fi

echo "OK: app launched, focused window is ours, no fatal exceptions"
