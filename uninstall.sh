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

# ------------------------------------------------------------
# Detect and stop running binaries
# ------------------------------------------------------------

echo "🛑 Detecting and stopping running binaries"

RUNNING_BINS=()

for bin in "$BIN_SRC"/*; do
    if [ -f "$bin" ] && [ -x "$bin" ]; then
        name="$(basename "$bin")"

        if pgrep -x "$name" > /dev/null; then
            echo "⚠️  $name is running → stopping"
            RUNNING_BINS+=("$name")
            pkill -TERM -x "$name"
        fi
    fi
done

# Allow graceful shutdown
sleep 1

# Force kill if needed
for name in "${RUNNING_BINS[@]}"; do
    if pgrep -x "$name" > /dev/null; then
        echo "🔥 $name did not exit, killing"
        pkill -KILL -x "$name"
    fi
done

# ------------------------------------------------------------
# Uninstall binaries
# ------------------------------------------------------------

echo
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

# ------------------------------------------------------------
# Remove labwc3 config
# ------------------------------------------------------------

echo
echo "🧹 Removing labwc3 config"

if [ -d "$CONFIG_DST" ]; then
    rm -rv "$CONFIG_DST"
else
    echo "⚠️  $CONFIG_DST not found"
fi

# ------------------------------------------------------------
# Remove SDDM theme
# ------------------------------------------------------------

echo
echo "🧹 Removing SDDM theme Win8Login"

if [ -d "$SDDM_DST" ]; then
    sudo rm -rv "$SDDM_DST"
else
    echo "⚠️  SDDM theme not found"
fi

# ------------------------------------------------------------
# Remove Wayland session
# ------------------------------------------------------------

echo
echo "🧹 Removing Wayland session labwc-win8"

if [ -f "$WAYLAND_SESSION_DST" ]; then
    sudo rm -v "$WAYLAND_SESSION_DST"
else
    echo "⚠️  Wayland session file not found"
fi

echo
echo "✅ Uninstallation complete"
