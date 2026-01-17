#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_SRC="$ROOT_DIR/build/bin"
BIN_DST="/usr/bin"

ASSET_SRC="$ROOT_DIR/assets/labwc3"
CONFIG_DST="/usr/share/labwc3"

SDDM_SRC="$ROOT_DIR/assets/SDDM/Win8Login"
SDDM_DST="/usr/share/sddm/themes/Win8Login"

WAYLAND_SESSION_SRC="$ROOT_DIR/assets/wayland-sessions/labwc-win8.desktop"
WAYLAND_SESSION_DST="/usr/share/wayland-sessions/labwc-win8.desktop"

echo "🔨 Building projects first"
"$ROOT_DIR/build.sh"

if [ ! -d "$BIN_SRC" ]; then
    echo "❌ build/bin not found after build"
    exit 1
fi

# ------------------------------------------------------------
# Detect and stop running binaries
# ------------------------------------------------------------

echo
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
# Install binaries
# ------------------------------------------------------------

echo
echo "📦 Installing binaries to $BIN_DST"

for bin in "$BIN_SRC"/*; do
    if [ -f "$bin" ] && [ -x "$bin" ]; then
        name="$(basename "$bin")"
        echo "➡️  Installing $name"
        sudo install -v -m 0755 "$bin" "$BIN_DST/$name"
    fi
done

# ------------------------------------------------------------
# Install labwc3 assets
# ------------------------------------------------------------

echo
echo "🎨 Installing labwc3 assets to $CONFIG_DST"

if [ ! -d "$ASSET_SRC" ]; then
    echo "❌ Asset directory not found: $ASSET_SRC"
    exit 1
fi

sudo mkdir -p "$CONFIG_DST"
sudo cp -a "$ASSET_SRC/." "$CONFIG_DST/"


# ------------------------------------------------------------
# Install SDDM theme
# ------------------------------------------------------------

echo
echo "🖥️  Installing SDDM theme Win8Login"

if [ ! -d "$SDDM_SRC" ]; then
    echo "❌ SDDM theme directory not found: $SDDM_SRC"
    exit 1
fi

sudo mkdir -p "$SDDM_DST"
sudo cp -a "$SDDM_SRC/." "$SDDM_DST/"

# ------------------------------------------------------------
# Install Wayland session
# ------------------------------------------------------------

echo
echo "🧩 Installing Wayland session labwc-win8"

if [ ! -f "$WAYLAND_SESSION_SRC" ]; then
    echo "❌ Wayland session file not found: $WAYLAND_SESSION_SRC"
    exit 1
fi

sudo install -v -m 0644 \
    "$WAYLAND_SESSION_SRC" \
    "$WAYLAND_SESSION_DST"

# ------------------------------------------------------------
# Restart previously running binaries
# ------------------------------------------------------------

echo
echo "🚀 Restarting previously running binaries"

for name in "${RUNNING_BINS[@]}"; do
    if command -v "$name" >/dev/null; then
        echo "▶️  Restarting $name"
        "$name" &
    else
        echo "❌ Cannot restart $name (not found in PATH)"
    fi
done

echo
echo "✅ Build + installation complete"
