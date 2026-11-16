#!/bin/bash
# =============================================================================
# KKOS v5.2.0 — Odysseus systemd Service Installer (Linux)
# Consolidates: install-service.sh, odysseus-ui.service
#
# Usage:
#   ./install-service.sh              — auto-detect user and paths
#   ./install-service.sh --uninstall  — remove service
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SERVICE_NAME="odysseus-ui"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# ── Uninstall ──────────────────────────────────────────────────────────────
if [ "${1:-}" = "--uninstall" ]; then
    echo "Removing $SERVICE_NAME service..."
    sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    sudo systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    sudo rm -f "$SERVICE_FILE"
    sudo systemctl daemon-reload
    echo "[ok] $SERVICE_NAME removed."
    exit 0
fi

# ── Detect user and paths ─────────────────────────────────────────────────
INSTALL_USER="${SUDO_USER:-$USER}"
ODY_DIR="$SCRIPT_DIR/odysseus"
VENV_UV="$ODY_DIR/venv/bin/uvicorn"
PORT="${ODYSSEUS_PORT:-7000}"
HOST="${ODYSSEUS_HOST:-0.0.0.0}"

echo ""
echo "================================================"
echo "  KKOS v5.2.0 — Odysseus Service Installer"
echo "================================================"
echo ""
echo "  User:       $INSTALL_USER"
echo "  WorkingDir: $ODY_DIR"
echo "  Uvicorn:    $VENV_UV"
echo "  Bind:       $HOST:$PORT"
echo ""

# Validate
if [ ! -f "$VENV_UV" ]; then
    echo "[ERROR] Uvicorn not found at $VENV_UV"
    echo "        Run ./build.sh first to set up Odysseus."
    exit 1
fi
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Must be run as root (sudo ./install-service.sh)"
    exit 1
fi

# Write service file
cat > "$SERVICE_FILE" <<SERVICE
[Unit]
Description=KKOS Odysseus AI Workspace v5.2.0
After=network.target

[Service]
Type=simple
User=$INSTALL_USER
WorkingDirectory=$ODY_DIR
ExecStart=$VENV_UV app:app --port $PORT --host $HOST
Restart=always
RestartSec=3
EnvironmentFile=-$SCRIPT_DIR/.env

[Install]
WantedBy=multi-user.target
SERVICE

echo "[ok] Service file written: $SERVICE_FILE"

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"
echo ""
systemctl status "$SERVICE_NAME" --no-pager
echo ""
echo "[ok] Odysseus is running as a service."
echo "     URL:  http://127.0.0.1:$PORT"
echo ""
echo "  Manage with:"
echo "    sudo systemctl status $SERVICE_NAME"
echo "    sudo systemctl restart $SERVICE_NAME"
echo "    sudo journalctl -u $SERVICE_NAME -f"
echo "    sudo ./install-service.sh --uninstall"
