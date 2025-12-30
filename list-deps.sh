#!/usr/bin/env bash
set -e

echo "================================"
echo " Project Dependencies Summary"
echo "================================"
echo

for cmake in */CMakeLists.txt; do
    proj="$(basename "$(dirname "$cmake")")"
    echo "▶ $proj"
    echo "--------------------------------"

    grep -E \
        'find_package|pkg_check_modules|find_library|find_path' \
        "$cmake" \
    | sed 's/^[ \t]*//'

    echo
done
