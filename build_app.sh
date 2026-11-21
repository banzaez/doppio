#!/bin/bash
set -euo pipefail

# Чтение версии из единого источника истины (VERSION)
if [ -f "VERSION" ]; then
    # shellcheck disable=SC1091
    source "VERSION"
fi
APP_VERSION="${VERSION:-1.5.2}"
APP_BUILD="${BUILD:-8}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"

echo "☕️ Собираем Doppio v$APP_VERSION ($APP_BUILD) в Release режиме..."
swift build -c release

RELEASE_BIN="$(swift build -c release --show-bin-path)/Doppio"
APP_DIR="Doppio.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"

echo "🎨 Проверяем наличие AppIcon.icns..."
if [ ! -f "AppIcon.icns" ]; then
    swift generate_icon.swift
    iconutil -c icns AppIcon.iconset -o AppIcon.icns
fi

echo "📦 Формируем структуру $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$FRAMEWORKS_DIR"

# Копируем бинарный файл
cp "$RELEASE_BIN" "$MACOS_DIR/Doppio"
chmod +x "$MACOS_DIR/Doppio"

# Копируем иконку приложения
cp "AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

# Копируем Sparkle.framework (обязательная зависимость автообновлений)
SPARKLE_FRAMEWORK=".build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"
if [ ! -d "$SPARKLE_FRAMEWORK" ]; then
    echo "❌ Ошибка: Sparkle.framework не найден по пути $SPARKLE_FRAMEWORK" >&2
    exit 1
fi
cp -R "$SPARKLE_FRAMEWORK" "$FRAMEWORKS_DIR/"

# Настраиваем rpath для поиска Frameworks (без ошибки, если rpath уже прописан)
if ! otool -l "$MACOS_DIR/Doppio" | grep -q "@executable_path/../Frameworks"; then
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS_DIR/Doppio"
fi

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
    <string>$APP_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$APP_BUILD</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>SUFeedURL</key>
    <string>https://raw.githubusercontent.com/banzaez/doppio/main/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>kZkBwhYmagXqdsxVBtxrqaBArHVveE1Lqtbl6gjg2Jg=</string>
    <key>SUEnableAutomaticChecks</key>
    <true/>
</dict>
</plist>
EOF

sign_item() {
    local identity="$1"
    local target="$2"
    codesign --force --sign "$identity" "$target"
}

echo "✍️ Подписываем фреймворки и пакет (inside-out)..."
if [ -n "$CODESIGN_IDENTITY" ]; then
    SIGN_IDENTITY="$CODESIGN_IDENTITY"
else
    SIGN_IDENTITY="$(security find-identity -p codesigning -v 2>/dev/null | grep -E "DoppioDev" | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/' || true)"
fi

if [ -n "$SIGN_IDENTITY" ]; then
    echo "🔐 Подписание сертификатом: $SIGN_IDENTITY"
    ACTIVE_IDENTITY="$SIGN_IDENTITY"
else
    echo "ℹ️ Сертификат DoppioDev не найден, используется ad-hoc подпись..."
    ACTIVE_IDENTITY="-"
fi

# Подписываем вложенные компоненты Sparkle изнутри наружу
SPARKLE_DEST="$FRAMEWORKS_DIR/Sparkle.framework"
if [ -d "$SPARKLE_DEST" ]; then
    while IFS= read -r xpc; do
        sign_item "$ACTIVE_IDENTITY" "$xpc"
    done < <(find "$SPARKLE_DEST" -name "*.xpc" -type d)

    if [ -e "$SPARKLE_DEST/Versions/B/Updater.app" ]; then
        sign_item "$ACTIVE_IDENTITY" "$SPARKLE_DEST/Versions/B/Updater.app"
    elif [ -e "$SPARKLE_DEST/Updater.app" ]; then
        sign_item "$ACTIVE_IDENTITY" "$SPARKLE_DEST/Updater.app"
    fi

    if [ -e "$SPARKLE_DEST/Versions/B/Autoupdate" ]; then
        sign_item "$ACTIVE_IDENTITY" "$SPARKLE_DEST/Versions/B/Autoupdate"
    elif [ -e "$SPARKLE_DEST/Autoupdate" ]; then
        sign_item "$ACTIVE_IDENTITY" "$SPARKLE_DEST/Autoupdate"
    fi

    sign_item "$ACTIVE_IDENTITY" "$SPARKLE_DEST"
fi

sign_item "$ACTIVE_IDENTITY" "$APP_DIR"

echo "✅ Приложение успешно собрано с иконкой и Sparkle: $(pwd)/$APP_DIR"
