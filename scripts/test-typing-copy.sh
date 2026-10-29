#!/bin/sh
set -eu

device_id="${1:?Usage: scripts/test-typing-copy.sh <simulator-udid>}"
expected=$(printf '사랑이라는 선물은 억지로 줄 수 없고 받아들여지기를 기다릴 뿐이다.\n존우든')

xcodebuild -quiet \
  -project Fiilsa.xcodeproj \
  -scheme Fiilsa \
  -destination "platform=iOS Simulator,id=${device_id}" \
  -derivedDataPath /tmp/FiilsaDerivedData \
  -skipMacroValidation \
  -parallel-testing-enabled NO \
  -only-testing:FiilsaUITests/TypingLayoutUITests/testCopyButtonCanBeTappedOnTypingScreen \
  test

xcrun simctl boot "$device_id" 2>/dev/null || true
xcrun simctl bootstatus "$device_id" -b >/dev/null
actual=$(xcrun simctl pbpaste "$device_id")
if [ "$actual" != "$expected" ]; then
  printf 'Clipboard mismatch. Expected quote and author separated by a newline.\nActual: %s\n' "$actual" >&2
  exit 1
fi

printf 'Typing copy passed: selected Korean quote and author are on the simulator pasteboard.\n'
