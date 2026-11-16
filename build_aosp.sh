#!/bin/bash
# build_aosp.sh - Setup environment and build Cuttlefish target

# Navigate to your AOSP root (adjust path as necessary)
AOSP_ROOT="$HOME/aosp"

if [ ! -d "$AOSP_ROOT" ]; then
    echo "[ERROR] AOSP directory not found at $AOSP_ROOT"
    exit 1
fi

cd "$AOSP_ROOT" || exit

echo "[BUILD] Sourcing environment setup..."
source build/envsetup.sh

echo "[BUILD] Selecting lunch target: aosp_cf_x86_64_only_phone-aosp_current-userdebug"
lunch aosp_cf_x86_64_only_phone-aosp_current-userdebug

echo "[BUILD] Starting build (m)..."
# 'm' automatically detects available cores
m

echo "[SUCCESS] Build process completed."