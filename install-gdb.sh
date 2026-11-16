#!/bin/bash
# =============================================================================
# KKOS v5.2.0 — GDB Installer (Linux / macOS / MSYS2)
# Consolidates: install_gdb.sh (MSYS2 pacman version)
# =============================================================================
set -e

OS="$(uname -s)"
ARCH="$(uname -m)"

echo ""
echo "================================================"
echo "  KKOS — GDB Installer"
echo "  OS: $OS / $ARCH"
echo "================================================"
echo ""

case "$OS" in
    Linux)
        if command -v apt-get &>/dev/null; then
            echo "Installing GDB via apt..."
            sudo apt-get update -qq
            sudo apt-get install -y gdb
        elif command -v dnf &>/dev/null; then
            echo "Installing GDB via dnf..."
            sudo dnf install -y gdb
        elif command -v pacman &>/dev/null; then
            # Native Linux pacman (Arch), not MSYS2
            echo "Installing GDB via pacman..."
            sudo pacman -S --noconfirm gdb
        else
            echo "[ERROR] Unknown package manager. Install GDB manually."
            exit 1
        fi
        ;;
    Darwin)
        if command -v brew &>/dev/null; then
            echo "Installing GDB via Homebrew..."
            brew install gdb
            echo ""
            echo "[NOTE] macOS: GDB requires code signing to work with SIP."
            echo "       For debugging on macOS, LLDB (already installed) is recommended:"
            echo "         lldb bin/kkos_v520"
            echo "       VS Code uses lldb automatically on macOS."
        else
            echo "[ERROR] Homebrew not found."
            echo "  Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
        ;;
    MINGW*|MSYS*|CYGWIN*)
        # Running inside MSYS2 shell on Windows — use install-gdb.bat instead for full env
        echo "Detected MSYS2 environment. Installing via pacman..."
        pacman -Sy --noconfirm
        pacman -S --noconfirm mingw-w64-ucrt-x86_64-gdb
        # Verify
        GDB_PATH="/ucrt64/bin/gdb.exe"
        if [ -f "$GDB_PATH" ]; then
            echo "[ok] GDB installed: $GDB_PATH"
            "$GDB_PATH" --version | head -1
        else
            echo "[WARN] GDB not found at $GDB_PATH after install — check pacman output."
        fi
        exit 0
        ;;
    *)
        echo "[ERROR] Unsupported OS: $OS"
        exit 1
        ;;
esac

# Verify
if command -v gdb &>/dev/null; then
    echo ""
    echo "[ok] GDB installed: $(command -v gdb)"
    gdb --version | head -1
else
    echo "[WARN] GDB not found on PATH after install."
fi
