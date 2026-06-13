#!/usr/bin/env bash
# Empacota um .app de release (assinado ad-hoc) zipado para distribuição.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-0.1.0}"
swift build -c release
[ -f Resources/AppIcon.icns ] || bash scripts/make-icon.sh

STAGE="$(mktemp -d)/OpenShark.app"
mkdir -p "$STAGE/Contents/MacOS" "$STAGE/Contents/Resources"
cp .build/release/OpenSharkApp "$STAGE/Contents/MacOS/OpenShark"
cp Sources/OpenSharkApp/Info.plist "$STAGE/Contents/Info.plist"
cp Resources/AppIcon.icns "$STAGE/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$STAGE" 2>/dev/null || true

mkdir -p dist
ZIP="$(pwd)/dist/OpenShark-v${VERSION}-macos.zip"
rm -f "$ZIP"
( cd "$(dirname "$STAGE")" && ditto -c -k --keepParent OpenShark.app "$ZIP" )
echo "✓ $ZIP"
