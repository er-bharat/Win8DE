#!/usr/bin/env bash
set -e

# ================================
# Configuration
# ================================
ROOT_DIR="$(pwd)"
BUILD_ROOT="$ROOT_DIR/build"
BIN_DIR="$BUILD_ROOT/bin"
BUILD_TYPE=Release
GENERATOR="Ninja"

PROJECTS=(
    Win8Wall
    Win8Start
    Win8Settings
    Win8OSD
    Win8Lock
    Win8Corner
    battery
)

# ================================
# Checks
# ================================
command -v cmake >/dev/null || { echo "❌ cmake not found"; exit 1; }

if ! command -v ninja >/dev/null; then
    echo "⚠️ Ninja not found, using Makefiles"
    GENERATOR=""
fi

mkdir -p "$BUILD_ROOT"
mkdir -p "$BIN_DIR"

# ================================
# Build + Collect
# ================================
for proj in "${PROJECTS[@]}"; do
    echo
    echo "=============================="
    echo "🔨 Building $proj"
    echo "=============================="

    SRC_DIR="$ROOT_DIR/$proj"
    BUILD_DIR="$BUILD_ROOT/$proj"

    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    if [ -n "$GENERATOR" ]; then
        cmake "$SRC_DIR" \
            -G "$GENERATOR" \
            -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
    else
        cmake "$SRC_DIR" \
            -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
    fi

    cmake --build . --parallel

    # ================================
    # Copy executables
    # ================================
    echo "📦 Collecting binaries from $proj"

    find "$BUILD_DIR" -maxdepth 1 -type f -executable \
        ! -name "*.so*" \
        ! -name "cmake_install.cmake" \
        ! -name "Makefile" \
        -exec cp -u {} "$BIN_DIR/" \;

done

echo
echo "✅ All projects built"
echo "📁 Binaries collected in: $BIN_DIR"
