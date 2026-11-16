#!/bin/bash
# setup_android.sh - Automated AOSP Source Initialization

WORKING_DIRECTORY="aosp_source"

echo "[SYSTEM] Creating working directory: $WORKING_DIRECTORY"
mkdir -p "$WORKING_DIRECTORY"
cd "$WORKING_DIRECTORY" || exit

echo "[REPO] Initializing client for android-latest-release..."
# -b: branch, -u: manifest URL
repo init --partial-clone --no-use-superproject -b android-latest-release -u https://android.googlesource.com/platform/manifest

if [ $? -eq 0 ]; then
    echo "[REPO] Initialization successful. Starting sync..."
    # -c: current branch only, -j8: parallel threads
    repo sync -c -j8
else
    echo "[ERROR] Repo initialization failed. Check your internet connection or manifest URL."
fi