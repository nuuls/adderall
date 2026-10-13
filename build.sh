#!/bin/bash
# Builds build/Adderall.app. Pass "install" to also copy it into /Applications.
set -euo pipefail
cd "$(dirname "$0")"

APP=build/Adderall.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
swiftc -O main.swift -o "$APP/Contents/MacOS/Adderall"
cp Info.plist "$APP/Contents/"
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "install" ]]; then
    pkill -x Adderall || true
    rm -rf /Applications/Adderall.app
    cp -R "$APP" /Applications/
    echo "Installed /Applications/Adderall.app"
fi
