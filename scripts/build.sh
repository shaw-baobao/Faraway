#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release
APP="$PWD/dist/Faraway.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Faraway "$APP/Contents/MacOS/Faraway"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>app.faraway.rest</string>
<key>CFBundleName</key><string>Faraway</string>
<key>CFBundleDisplayName</key><string>远眺</string>
<key>CFBundleExecutable</key><string>Faraway</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>CFBundleIconFile</key><string>AppIcon</string>
</dict></plist>
PLIST
if [ -f Assets/AppIcon.icns ]; then cp Assets/AppIcon.icns "$APP/Contents/Resources/"; fi
codesign --force --sign - "$APP"
printf '\nBuilt: %s\n' "$APP"
