#!/usr/bin/env bash
# Build + bundle OpenSharkApp into a signed .app that keeps its Input Monitoring
# permission across rebuilds (stable identity = TCC tracks by cert, not CDHash).
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-debug}"   # debug | release
BIN=".build/$CONFIG/OpenSharkApp"
CERT="OpenShark Dev"
ENTITLEMENTS="Sources/OpenSharkApp/OpenShark.entitlements"

if [ ! -f "$BIN" ]; then
    echo "Binary not found at $BIN — run: swift build${CONFIG:+ -c $CONFIG}"
    exit 1
fi

APP="dist/R1 Control Center.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/OpenShark"
cp Sources/OpenSharkApp/Info.plist "$APP/Contents/Info.plist"
[ -f Resources/AppIcon.icns ] || bash scripts/make-icon.sh
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Sign with named self-signed cert so TCC can track permission by signing
# identity (identifier + certificate subject) rather than CDHash.
# This means granting Input Monitoring once survives subsequent rebuilds.
if security find-identity -v -p codesigning 2>/dev/null | grep -q "\"$CERT\""; then
    codesign --force --sign "$CERT" --entitlements "$ENTITLEMENTS" "$APP"
    echo "✓ Signed with '$CERT'"
else
    echo "⚠ Certificate '$CERT' not found — falling back to ad-hoc signing (permissions won't persist across rebuilds)"
    echo "  To fix: run scripts/setup-codesign.sh"
    codesign --force --sign - "$APP" 2>/dev/null || true
fi

echo "✓ Bundle: $APP"
echo "  Open with: open $APP"
