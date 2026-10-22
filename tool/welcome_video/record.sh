#!/bin/zsh
# Records the welcome screen clip on an iOS simulator and writes
# assets/video/welcome_demo.mp4 (+ .jpg poster). See README.md.
#
#   tool/welcome_video/record.sh <simulator udid> [height ÷ width to keep]
set -e
UDID=${1:?usage: record.sh <simulator udid> [crop]}
CROP=${2:-2.1741}
ROOT=${0:A:h:h:h}
OUT=${TMPDIR:-/tmp}/kindose_welcome_video
mkdir -p "$OUT"
FLUTTER="$ROOT/.fvm/flutter_sdk/bin/flutter"
[[ -x "$FLUTTER" ]] || FLUTTER=flutter

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
# A tidy status bar, and a fresh install so the app starts with no data.
xcrun simctl status_bar "$UDID" override --time 9:41 --dataNetwork wifi \
  --wifiBars 3 --cellularMode active --cellularBars 4 \
  --batteryState charged --batteryLevel 100
xcrun simctl uninstall "$UDID" app.kindose 2>/dev/null || true

xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$OUT/raw.mp4" &
REC=$!
sleep 1
REC_START=$(python3 -c 'import time; print(int(time.time() * 1000))')

cd "$ROOT"
"$FLUTTER" test integration_test/welcome_video_test.dart -d "$UDID" | tee "$OUT/run.log"

kill -INT $REC
wait $REC || true
xcrun simctl status_bar "$UDID" clear

mark() { grep -o "WELCOME_VIDEO $1 [0-9]*" "$OUT/run.log" | awk '{print $3}' | tail -1; }
START=$(python3 -c "print(($(mark start) - $REC_START) / 1000)")
END=$(python3 -c "print(($(mark end) - $REC_START) / 1000)")
echo "cutting $START s → $END s"
swift "$ROOT/tool/welcome_video/edit.swift" "$OUT/raw.mp4" \
  "$ROOT/assets/video/welcome_demo.mp4" "$ROOT/assets/video/welcome_demo.jpg" \
  "$START" "$END" "$CROP" 540 0.5
