#!/bin/bash
# =============================================================================
# KKOS v5.2.0 — Odysseus Quick Start for macOS
# Consolidates: start-macos.sh
#
# One command for a fresh Mac: installs Homebrew deps, sets up the Python
# environment, and launches Odysseus — safe to re-run.
#
# PORT: defaults to 7860 (macOS AirPlay Receiver holds 7000).
#       Override: ODYSSEUS_PORT=7900 ./start-macos.sh
# HOST: defaults to 127.0.0.1; set APP_BIND=0.0.0.0 in .env for LAN access.
# =============================================================================
set -e

# Always run from the script's own directory — fixes the empty-log issue
# where all relative paths failed silently when invoked from another dir.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load .env (file values yield to shell environment)
if [ -f .env ]; then
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${key// }" ]] && continue
        value="${value%%#*}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        [ -n "$key" ] && [ -z "${!key+x}" ] && export "$key=$value"
    done < .env
fi

PORT="${ODYSSEUS_PORT:-${APP_PORT:-7860}}"
HOST="${ODYSSEUS_HOST:-${APP_BIND:-127.0.0.1}}"
PROBE_HOST="$HOST"
[ "$PROBE_HOST" = "0.0.0.0" ] || [ "$PROBE_HOST" = "::" ] && PROBE_HOST="127.0.0.1"

trap 'echo; echo "Setup failed above. Re-running ./start-macos.sh is safe."; exit 1' ERR

echo "▶ KKOS v5.2.0 — Odysseus quick start for macOS"

# Port check
if (exec 3<>"/dev/tcp/$PROBE_HOST/$PORT") 2>/dev/null; then
    echo "✗ Port $PORT is already in use on $PROBE_HOST."
    echo "  Stop what's using it, or pick another port:"
    echo "    ODYSSEUS_PORT=7900 ./start-macos.sh"
    exit 1
fi

# Homebrew
if ! command -v brew &>/dev/null; then
    echo ""
    echo "Homebrew required. Install it then re-run:"
    echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
fi

# Python 3.11+ (Apple Silicon requires arm64 Homebrew Python)
PY=""
if [ "$(uname -m)" = "arm64" ]; then
    for cand in /opt/homebrew/bin/python3.13 /opt/homebrew/bin/python3.12 /opt/homebrew/bin/python3.11; do
        [ -x "$cand" ] && "$cand" -c 'import sys; exit(0 if sys.version_info[:2]>=(3,11) else 1)' 2>/dev/null \
            && PY="$cand" && break
    done
else
    for cand in python3 python3.13 python3.12 python3.11; do
        p="$(command -v "$cand" 2>/dev/null)" || continue
        "$p" -c 'import sys; exit(0 if sys.version_info[:2]>=(3,11) else 1)' 2>/dev/null \
            && PY="$p" && break
    done
fi

brew_ensure() {
    command -v "$1" &>/dev/null \
        && echo "  ✓ $2 already installed" \
        || { echo "  installing $2…"; brew install "$2" || \
            echo "  ⚠ Couldn't install $2 now — Cookbook may be limited. Run: brew install $2"; }
}

echo "▶ Checking dependencies (Homebrew)…"
if [ -n "$PY" ]; then
    echo "  (using $("$PY" --version 2>&1) at $PY)"
else
    echo "  installing python@3.11…"
    brew install python@3.11 || true
    PY="$(command -v /opt/homebrew/bin/python3.11 2>/dev/null || command -v python3.11 2>/dev/null || true)"
fi
brew_ensure tmux tmux
brew_ensure llama-server llama.cpp

[ -z "$PY" ] || [ ! -x "$PY" ] && {
    echo "✗ No Python 3.11+ found."
    echo "  Check: ls /opt/homebrew/bin/python3*  or: brew install python@3.11"
    exit 1
}

# Virtual environment
VENV_PY="./venv/bin/python3"
[ -d venv ] || { echo "▶ Creating Python environment…"; "$PY" -m venv venv; }

# Hash-gated install
REQ_HASH="$(md5 -q requirements.txt 2>/dev/null || md5sum requirements.txt | cut -d' ' -f1)"
REQ_HASH_FILE="venv/.requirements_hash"
if [ ! -f "$REQ_HASH_FILE" ] || [ "$REQ_HASH" != "$(cat "$REQ_HASH_FILE" 2>/dev/null)" ]; then
    echo "▶ Installing Python packages (first run may take a few minutes)…"
    "$VENV_PY" -m pip install --quiet --upgrade pip
    "$VENV_PY" -m pip install -r requirements.txt
    echo "$REQ_HASH" > "$REQ_HASH_FILE"
else
    echo "▶ Python packages up to date — skipping install"
fi

# Remove conflicting chromadb-client
"$VENV_PY" -m pip show chromadb-client &>/dev/null 2>&1 && {
    echo "▶ Cleaning up conflicting chromadb-client…"
    "$VENV_PY" -m pip uninstall -y chromadb-client
    "$VENV_PY" -m pip install --force-reinstall chromadb
}

echo "▶ Preparing Odysseus…"
ODYSSEUS_SKIP_RUN_HINT=1 ./venv/bin/python setup.py

# Browser opener (background)
URL="http://$PROBE_HOST:$PORT"
POLLER_PID=""
if [ -z "${ODYSSEUS_NO_OPEN:-}" ] && command -v open &>/dev/null; then
    (
        for _ in $(seq 1 90); do
            (exec 3<>"/dev/tcp/$PROBE_HOST/$PORT") 2>/dev/null && {
                printf '\n  ┌─────────────────────────────────────────────┐\n'
                printf '  │  ✓ Odysseus ready — opening your browser     │\n'
                printf "  │     %-41s │\n" "$URL"
                printf '  │     Press Ctrl+C in this window to stop      │\n'
                printf '  └─────────────────────────────────────────────┘\n\n'
                open "$URL"
                break
            }
            sleep 1
        done
    ) &
    POLLER_PID=$!
fi

trap - ERR
trap '[ -n "$POLLER_PID" ] && kill "$POLLER_PID" 2>/dev/null' EXIT INT TERM

echo ""
echo "▶ Starting Odysseus at $URL"
[ "$HOST" = "0.0.0.0" ] && echo "  (LAN/Tailscale access enabled)"
echo "  (Press Ctrl+C to stop)"
echo ""
"$VENV_PY" -m uvicorn app:app --host "$HOST" --port "$PORT"
