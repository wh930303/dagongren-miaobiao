#!/bin/zsh
# 一键构建「打工人的秒表」：通用二进制 + .app + .dmg
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="打工人的秒表"
BUNDLE_ID="com.dagongren.miaobiao"
EXEC_NAME="miaobiao"
VERSION="1.0.0"
MIN_MACOS="13.0"

BUILD="$ROOT/.build"
DIST="$ROOT/dist"

echo "==> 清理"
rm -rf "$BUILD"
mkdir -p "$BUILD" "$DIST"

# ---------- 图标 ----------
if [[ ! -f "$ROOT/assets/AppIcon.icns" ]]; then
  echo "==> 生成图标"
  swiftc "$ROOT/assets/draw_icon.swift" -o "$BUILD/draw_icon"
  "$BUILD/draw_icon" "$BUILD/icon_master.png" >/dev/null
  sips -Z 1024 "$BUILD/icon_master.png" --out "$BUILD/icon_1024.png" >/dev/null
  rm -rf "$BUILD/AppIcon.iconset"
  mkdir -p "$BUILD/AppIcon.iconset"
  for s in 16 32 64 128 256 512; do
    sips -z $s $s "$BUILD/icon_1024.png" --out "$BUILD/AppIcon.iconset/icon_${s}x${s}.png" >/dev/null
    d=$((s * 2))
    sips -z $d $d "$BUILD/icon_1024.png" --out "$BUILD/AppIcon.iconset/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$BUILD/AppIcon.iconset" -o "$ROOT/assets/AppIcon.icns"
fi

# ---------- 编译（arm64 + x86_64） ----------
echo "==> 编译 arm64"
swiftc -O -target arm64-apple-macos$MIN_MACOS "$ROOT/src/main.swift" -o "$BUILD/$EXEC_NAME-arm64"
echo "==> 编译 x86_64"
swiftc -O -target x86_64-apple-macos$MIN_MACOS "$ROOT/src/main.swift" -o "$BUILD/$EXEC_NAME-x86_64"
lipo -create -output "$BUILD/$EXEC_NAME" "$BUILD/$EXEC_NAME-arm64" "$BUILD/$EXEC_NAME-x86_64"

# ---------- 组装 .app ----------
echo "==> 组装 App"
APP="$DIST/$APP_NAME.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BUILD/$EXEC_NAME" "$APP/Contents/MacOS/$EXEC_NAME"
cp "$ROOT/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key><string>$EXEC_NAME</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>LSMinimumSystemVersion</key><string>$MIN_MACOS</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>NSHumanReadableCopyright</key><string>MIT License</string>
</dict>
</plist>
PLIST

codesign --force --deep -s - "$APP" >/dev/null 2>&1 || echo "    (ad-hoc 签名失败，可忽略；用户首次打开需右键)"

# ---------- 打包 DMG ----------
echo "==> 打包 DMG"
DMG="$DIST/dagongren-miaobiao-v$VERSION.dmg"
rm -f "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$APP" -ov -format UDZO "$DMG" >/dev/null

echo ""
echo "构建完成："
echo "  App: $APP"
echo "  DMG: $DMG"
lipo -info "$APP/Contents/MacOS/$EXEC_NAME"
