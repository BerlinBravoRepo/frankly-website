#!/bin/bash
#
# capture-screenshots.sh — exports real app screenshots from the iOS Simulator and
# drops them into ./screenshots for the website. Run after building the app.
#
# Usage: ./capture-screenshots.sh
# It builds the app, boots a simulator, and captures Welcome / Setup / Chat by
# pre-setting the onboarding flags in UserDefaults. (Files/Voice need navigation,
# so snap those on a real device.)
#
set -e
APPDIR="${APPDIR:-$HOME/Documents/_Companies/_BerlinBravo/Frankly}"
BID="com.berlinbravo.Frankly"
OUT="$(cd "$(dirname "$0")" && pwd)/screenshots"
mkdir -p "$OUT"

echo "Building…"
xcodebuild -project "$APPDIR/Frankly.xcodeproj" -scheme Frankly \
  -destination 'generic/platform=iOS Simulator' -configuration Debug \
  build CODE_SIGNING_ALLOWED=NO >/dev/null

APP=$(ls -d "$HOME"/Library/Developer/Xcode/DerivedData/Frankly-*/Build/Products/Debug-iphonesimulator/Frankly.app | head -1)
UDID=$(xcrun simctl list devices available | grep -oE "iPhone 1[567][^(]*\([0-9A-F-]{36}\)" | head -1 | grep -oE "[0-9A-F-]{36}")
echo "Sim $UDID"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
xcrun simctl install "$UDID" "$APP"

cap () { # filename, then AppStorage bool keys to preset
  local name="$1"; shift
  xcrun simctl terminate "$UDID" "$BID" >/dev/null 2>&1 || true
  xcrun simctl spawn "$UDID" defaults delete "$BID" >/dev/null 2>&1 || true
  for k in "$@"; do xcrun simctl spawn "$UDID" defaults write "$BID" "$k" -bool YES >/dev/null 2>&1; done
  xcrun simctl launch "$UDID" "$BID" >/dev/null 2>&1
  sleep 14   # wait out cold-launch + the home->app transition before grabbing
  xcrun simctl io "$UDID" screenshot "$OUT/$name" >/dev/null 2>&1
  echo "  $name"
}

echo "Capturing…"
cap welcome.png
cap setup.png hasSeenWelcome hasOnboarded
cap chat.png hasSeenWelcome hasOnboarded hasMetFamily
echo "Done -> $OUT"
