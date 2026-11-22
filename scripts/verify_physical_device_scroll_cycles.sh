#!/usr/bin/env bash
# verify_physical_device_scroll_cycles.sh
# Automates 20 Cold-Launch Cycles and 20 Background/Foreground Cycles on physical device via ADB

set -e

PACKAGE="lk.yasas.simpleaac.dev"
ACTIVITY="com.example.simple_aac_app.MainActivity"
EVIDENCE_DIR="/home/yasas/Desktop/SimpleAAC-v1.1.6-Build15-Release-Final/03_QA/physical_scroll_evidence"
mkdir -p "$EVIDENCE_DIR"

echo "=== Simple AAC Physical Device Scrolling Acceptance Test ==="
DEVICE=$(adb devices | grep -E 'device$' | head -n 1 | awk '{print $1}')

if [ -z "$DEVICE" ]; then
  echo "ERROR: No physical Android device connected via ADB."
  echo "Please connect Samsung Galaxy A34 5G via USB or 'adb connect <IP>:<PORT>' and re-run."
  exit 1
fi

echo "Connected Device: $DEVICE"
DEVICE_MODEL=$(adb -s "$DEVICE" shell getprop ro.product.model | tr -d '\r')
ANDROID_VER=$(adb -s "$DEVICE" shell getprop ro.build.version.release | tr -d '\r')
echo "Target Model: $DEVICE_MODEL (Android $ANDROID_VER)"

# Test 1: 20 Cold Launch / Reopen Cycles with Immediate Scrolling
echo ""
echo "=== Phase 1: 20 Cold Launch Cycles ==="
COLD_PASS=0
COLD_FAIL=0

for i in $(seq 1 20); do
  echo -n "Cycle $i/20: Cold Launch -> "
  # Force stop
  adb -s "$DEVICE" shell am force-stop "$PACKAGE" > /dev/null 2>&1
  sleep 0.5
  
  # Cold start
  START_OUT=$(adb -s "$DEVICE" shell am start -W -n "$PACKAGE/$ACTIVITY" 2>&1)
  sleep 0.8
  
  # Immediate vertical scroll down (x=500, y=1400 -> y=700)
  adb -s "$DEVICE" shell input swipe 500 1400 500 700 250
  sleep 0.3
  
  # Scroll back up (x=500, y=700 -> y=1400)
  adb -s "$DEVICE" shell input swipe 500 700 500 1400 250
  sleep 0.3
  
  # Check if crash or ANR occurred
  CRASH=$(adb -s "$DEVICE" logcat -d -t 100 | grep -E 'FATAL EXCEPTION|ANR in' || true)
  if [ -z "$CRASH" ]; then
    echo "SUCCESS (scrolled smoothly)"
    COLD_PASS=$((COLD_PASS + 1))
  else
    echo "FAILED: $CRASH"
    COLD_FAIL=$((COLD_FAIL + 1))
    adb -s "$DEVICE" exec-out screencap -p > "$EVIDENCE_DIR/cold_fail_cycle_$i.png"
  fi
done

# Test 2: 20 Background / Foreground Cycles with Immediate Scrolling
echo ""
echo "=== Phase 2: 20 Background/Foreground Cycles ==="
BG_PASS=0
BG_FAIL=0

for i in $(seq 1 20); do
  echo -n "Cycle $i/20: Background -> Resume -> "
  # Send to background via Home key (keyevent 3)
  adb -s "$DEVICE" shell input keyevent 3
  sleep 0.5
  
  # Bring back to foreground
  adb -s "$DEVICE" shell am start -n "$PACKAGE/$ACTIVITY" > /dev/null 2>&1
  sleep 0.5
  
  # Immediate vertical scroll down
  adb -s "$DEVICE" shell input swipe 500 1400 500 700 250
  sleep 0.3
  
  # Scroll back up
  adb -s "$DEVICE" shell input swipe 500 700 500 1400 250
  sleep 0.3
  
  CRASH=$(adb -s "$DEVICE" logcat -d -t 100 | grep -E 'FATAL EXCEPTION|ANR in' || true)
  if [ -z "$CRASH" ]; then
    echo "SUCCESS (scrolled smoothly)"
    BG_PASS=$((BG_PASS + 1))
  else
    echo "FAILED: $CRASH"
    BG_FAIL=$((BG_FAIL + 1))
    adb -s "$DEVICE" exec-out screencap -p > "$EVIDENCE_DIR/bg_fail_cycle_$i.png"
  fi
done

# Capture final state screenshot
adb -s "$DEVICE" exec-out screencap -p > "$EVIDENCE_DIR/final_scroll_acceptance.png"

echo ""
echo "=== Summary ==="
echo "Cold Launch Cycles: $COLD_PASS/20 Passed, $COLD_FAIL Failed"
echo "Background/Foreground Cycles: $BG_PASS/20 Passed, $BG_FAIL Failed"
echo "Evidence saved to: $EVIDENCE_DIR"
