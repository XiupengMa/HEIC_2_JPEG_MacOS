#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"
export CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/.build/ModuleCache"

BUILD_FLAGS=(-c release --disable-sandbox --cache-path "$PROJECT_DIR/.build/cache")
SIGN_FLAGS=(--force --options runtime --sign -)
APP_NAME="HEIC to JPG"
BUNDLE_ID="com.matthewma.heic-to-jpg"
case "${1:-local}" in
    local) ;;
    --sandbox)
        BUILD_FLAGS+=(--scratch-path "$PROJECT_DIR/.build/sandbox" -Xswiftc -DAPP_STORE)
        SIGN_FLAGS+=(--entitlements Resources/AppStore.entitlements)
        APP_NAME="HEIC to JPG Sandbox"
        BUNDLE_ID="com.matthewma.heic-to-jpg.sandbox-preview"
        ;;
    *) printf 'Usage: bash scripts/build.sh [--sandbox]\n' >&2; exit 2 ;;
esac
swift build "${BUILD_FLAGS[@]}"
BINARY_DIR="$(swift build "${BUILD_FLAGS[@]}" --show-bin-path)"
APP="$PROJECT_DIR/dist/$APP_NAME.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BINARY_DIR/HEICToJPG" "$APP/Contents/MacOS/HEICToJPG"
cp Resources/Info.plist "$APP/Contents/Info.plist"
VERSION="$(awk -F ' = ' '$1 == "MARKETING_VERSION" { print $2 }' Configuration/Version.xcconfig)"
BUILD_NUMBER="$(awk -F ' = ' '$1 == "CURRENT_PROJECT_VERSION" { print $2 }' Configuration/Version.xcconfig)"
test -n "$VERSION" && test -n "$BUILD_NUMBER"
/usr/libexec/PlistBuddy -c 'Set :CFBundleExecutable HEICToJPG' "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp Resources/PrivacyInfo.xcprivacy "$APP/Contents/Resources/PrivacyInfo.xcprivacy"
plutil -lint "$APP/Contents/Info.plist"
codesign "${SIGN_FLAGS[@]}" "$APP"
codesign --verify --strict "$APP"
touch "$APP"
printf '\nBuilt: %s\n' "$APP"

