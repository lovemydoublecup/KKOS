#!/bin/bash
# KKOS v5.2 Unified Bundle — Start Everything (Linux / macOS)
# Run ./build-all.sh first if this is a fresh install.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ODYSSEUS_DIR="$SCRIPT_DIR/odysseus"
VENV_PY="$ODYSSEUS_DIR/venv/bin/python3"
KKOS_BIN="$SCRIPT_DIR/bin/kkos_v520"

echo ""
echo "[KKOS Bundle] Starting KKOS + Odysseus AI..."
echo ""

ODYSSEUS_PID=""

if [ -x "$VENV_PY" ]; then
    echo "  Odysseus AI → http://127.0.0.1:7000"
    "$VENV_PY" -m uvicorn app:app --host 127.0.0.1 --port 7000 --app-dir "$ODYSSEUS_DIR" &
    ODYSSEUS_PID=$!
    sleep 2
else
    echo "[WARN] Odysseus venv not found at $VENV_PY"
    echo "       Run ./build-all.sh first to set up Odysseus."
fi

if [ -x "$KKOS_BIN" ]; then
    echo "  Launching KKOS..."
    "$KKOS_BIN" &
else
    echo "[WARN] KKOS binary not found at $KKOS_BIN"
    echo "       Run ./build-all.sh first to compile KKOS."
fi

echo ""
echo "[KKOS Bundle] Both services launched."
echo "  Odysseus: http://127.0.0.1:7000"
echo "  Press Ctrl+C to stop Odysseus (KKOS window manages itself)."
echo ""

trap '[ -n "$ODYSSEUS_PID" ] && kill "$ODYSSEUS_PID" 2>/dev/null' EXIT INT TERM
[ -n "$ODYSSEUS_PID" ] && wait "$ODYSSEUS_PID"
