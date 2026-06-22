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

xcrun simctl ui "$UDID" appearance dark >/dev/null 2>&1   # on-brand dark shots

cap () { # filename  shot-mode   (shot-mode read by the app via FRANKLY_SHOT)
  local name="$1"; local shot="$2"
  xcrun simctl terminate "$UDID" "$BID" >/dev/null 2>&1 || true
  SIMCTL_CHILD_FRANKLY_SHOT="$shot" xcrun simctl launch "$UDID" "$BID" >/dev/null 2>&1
  sleep 14   # wait out cold-launch + the home->app transition before grabbing
  xcrun simctl io "$UDID" screenshot "$OUT/$name" >/dev/null 2>&1
  echo "  $name ($shot)"
}

echo "Capturing…"
cap welcome.png    welcome
cap onboarding.png onboarding
cap setup.png      setup
cap chat.png       chat
cap files.png      files
cap family.png     family
cap menu.png       drawer
echo "Done -> $OUT"
