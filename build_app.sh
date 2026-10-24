#!/bin/bash
set -e

echo "☕️ Собираем Doppio в Release режиме..."
swift build -c release

RELEASE_BIN="$(swift build -c release --show-bin-path)/Doppio"
APP_DIR="Doppio.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🎨 Проверяем наличие AppIcon.icns..."
if [ ! -f "AppIcon.icns" ]; then
    swift generate_icon.swift
    iconutil -c icns AppIcon.iconset -o AppIcon.icns
fi

echo "📦 Формируем структуру $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Копируем бинарный файл
cp "$RELEASE_BIN" "$MACOS_DIR/Doppio"
chmod +x "$MACOS_DIR/Doppio"

# Копируем иконку приложения
cp "AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

# Создаем Info.plist
cat <<EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Doppio</string>
    <key>CFBundleIdentifier</key>
    <string>com.doppio.app</string>
    <key>CFBundleName</key>
    <string>Doppio</string>
    <key>CFBundleDisplayName</key>
    <string>Doppio</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

echo "✍️ Подписываем приложение ad-hoc сигнатурой..."
codesign -s - --force --deep "$APP_DIR"

echo "✅ Приложение успешно собрано с иконкой: $(pwd)/$APP_DIR"
