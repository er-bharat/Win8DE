#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

BIN_SRC="$ROOT_DIR/build/bin"
BIN_DST="/usr/bin"

CONFIG_DST="$HOME/.config/labwc3"
SDDM_DST="/usr/share/sddm/themes/Win8Login"
WAYLAND_SESSION_DST="/usr/share/wayland-sessions/labwc-win8.desktop"

if [ ! -d "$BIN_SRC" ]; then
    echo "❌ build/bin not found. Nothing to uninstall."
    exit 1
fi

echo "🧹 Uninstalling binaries from $BIN_DST"

for bin in "$BIN_SRC"/*; do
    name="$(basename "$bin")"
    target="$BIN_DST/$name"

    if [ -f "$target" ]; then
        echo "❌ Removing $target"
        sudo rm -v "$target"
    else
        echo "⚠️  $name not installed"
    fi
done

echo
echo "🧹 Removing labwc3 config"

if [ -d "$CONFIG_DST" ]; then
    rm -rv "$CONFIG_DST"
else
    echo "⚠️  $CONFIG_DST not found"
fi

echo
echo "🧹 Removing SDDM theme Win8Login"

if [ -d "$SDDM_DST" ]; then
    sudo rm -rv "$SDDM_DST"
else
    echo "⚠️  SDDM theme not found"
fi

echo
echo "🧹 Removing Wayland session labwc-win8"

if [ -f "$WAYLAND_SESSION_DST" ]; then
    sudo rm -v "$WAYLAND_SESSION_DST"
else
    echo "⚠️  Wayland session file not found"
fi

echo
echo "✅ Uninstallation complete"
