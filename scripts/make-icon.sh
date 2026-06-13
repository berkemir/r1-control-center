#!/usr/bin/env bash
# Gera Resources/AppIcon.icns a partir do gerador CoreGraphics.
set -euo pipefail
cd "$(dirname "$0")/.."

MASTER="Resources/AppIcon-1024.png"
mkdir -p Resources
swift scripts/gen-icon.swift "$MASTER"

ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
# (pixels:nome) — conjunto padrão exigido pelo iconutil
specs=( "16:16x16" "32:16x16@2x" "32:32x32" "64:32x32@2x"
        "128:128x128" "256:128x128@2x" "256:256x256" "512:256x256@2x"
        "512:512x512" "1024:512x512@2x" )
for spec in "${specs[@]}"; do
  px="${spec%%:*}"; name="${spec##*:}"
  sips -z "$px" "$px" "$MASTER" --out "$ICONSET/icon_${name}.png" >/dev/null
done

iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
echo "✓ Resources/AppIcon.icns"
