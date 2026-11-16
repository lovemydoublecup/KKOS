#!/bin/bash
# install_aosp_deps.sh - Install required packages for AOSP development

echo "[SYSTEM] Updating package lists..."
sudo apt-get update

echo "[SYSTEM] Installing build dependencies..."
sudo apt-get install -y git-core gnupg flex bison build-essential zip curl \
  zlib1g-dev libc6-dev-i386 x11proto-core-dev libx11-dev lib32z1-dev \
  libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig

echo "[SUCCESS] AOSP dependencies installed."