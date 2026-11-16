#!/bin/bash
# =============================================================================
# KKOS v5.2 Unified Bundle — Master Build Script (Linux / macOS)
# Builds KKOS C++ DAW engine AND sets up Odysseus AI workspace.
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ODYSSEUS_DIR="$SCRIPT_DIR/odysseus"
VERSION="5.2.0"
GAME_NAME="kkos_v520"

echo ""
echo "=================================================================="
echo "  KKOS v$VERSION Unified Bundle — Master Build (Linux/macOS)"
echo "=================================================================="
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 1 — KKOS C++ BUILD
# ─────────────────────────────────────────────────────────────────────────────
echo "[PHASE 1/3] KKOS C++ Build"
echo ""

if ! command -v g++ &>/dev/null; then
    echo "[WARNING] g++ not found — KKOS C++ compilation skipped."
    echo "          Install build-essential (Linux) or Xcode CLT (macOS) and re-run."
    KKOS_BUILT=0
else
    mkdir -p "$SCRIPT_DIR/bin"

    # 1a. Codex consolidation (KKOS + Odysseus docs)
    echo "[CODEX] Consolidating all documentation into KURFEW_KULT_CODEX.md..."
    CODEX="$SCRIPT_DIR/bin/KURFEW_KULT_CODEX.md"
    {
        echo "# KURFEW KULT CODEX"
        echo "Compiled on: $(date)"
        echo "Bundle: KKOS v$VERSION + Odysseus AI Workspace"
        echo ""
        echo "## KKOS Core Docs"
        echo ""
    } > "$CODEX"

    # KKOS docs (root level, skip odysseus/ subdir and the codex itself)
    while IFS= read -r -d '' f; do
        if [[ "$f" != *"/odysseus/"* && "$(basename "$f")" != "KURFEW_KULT_CODEX.md" ]]; then
            echo "[DOC] KKOS: $(basename "$f")"
            cat "$f" >> "$CODEX"
            printf '\n---\n\n' >> "$CODEX"
        fi
    done < <(find "$SCRIPT_DIR" -maxdepth 2 -name "*.md" -print0 2>/dev/null)

    {
        echo ""
        echo "## Odysseus AI Workspace Docs"
        echo ""
    } >> "$CODEX"

    if [ -d "$ODYSSEUS_DIR" ]; then
        while IFS= read -r -d '' f; do
            echo "[DOC] Odysseus: $(basename "$f")"
            cat "$f" >> "$CODEX"
            printf '\n---\n\n' >> "$CODEX"
        done < <(find "$ODYSSEUS_DIR" -name "*.md" -print0 2>/dev/null)
    else
        echo "[WARN] odysseus/ not found — Odysseus docs skipped from codex."
    fi

    # 1b. Resource embedding
    if command -v xxd &>/dev/null; then
        echo "[RESOURCE] Encoding Codex as C-Header..."
        pushd "$SCRIPT_DIR/bin" >/dev/null
        xxd -i KURFEW_KULT_CODEX.md > codex_resource.h
        popd >/dev/null
    else
        echo "[WARNING] xxd not found — resource generation skipped."
    fi

    # 1c. Compilation
    if [ -f "$SCRIPT_DIR/src/kkos_v520_unified.cpp" ]; then
        echo "[COMPILE] Running G++ Unified Build..."
        SOURCES="$SCRIPT_DIR/src/kkos_v520_unified.cpp"
        if ls "$SCRIPT_DIR/Single-Exe-1.0.0/raylib-5.5/src/"*.c &>/dev/null 2>&1; then
            SOURCES="$SOURCES $SCRIPT_DIR/Single-Exe-1.0.0/raylib-5.5/src/*.c"
        fi
        INCLUDES="-I$SCRIPT_DIR -I$SCRIPT_DIR/bin"
        if [ -d "$SCRIPT_DIR/Single-Exe-1.0.0/raylib-5.5/src" ]; then
            INCLUDES="$INCLUDES -I$SCRIPT_DIR/Single-Exe-1.0.0/raylib-5.5/src"
        fi
        DEFINES="-DKKOS_VERSION_STR=\"$VERSION\" -DKKOS_VERSION_MAJOR=5 -DKKOS_VERSION_MINOR=2 -DKKOS_ODYSSEUS_URL=\"http://127.0.0.1:7000\""
        FLAGS="-std=c++17 -O3 -ffast-math -Wall -Wno-missing-braces"
        # LTO can cause issues on macOS with Apple's ld; skip it there
        if [[ "$(uname)" != "Darwin" ]]; then
            FLAGS="$FLAGS -flto -fno-plt"
        fi

        if g++ $FLAGS $SOURCES -o "$SCRIPT_DIR/bin/$GAME_NAME" $INCLUDES $DEFINES -lpthread 2>&1; then
            echo "[SUCCESS] KKOS v$VERSION build: bin/$GAME_NAME"
            KKOS_BUILT=1
        else
            echo "[FAILURE] KKOS compilation failed — fix C++ errors and re-run."
            KKOS_BUILT=0
        fi
    else
        echo "[WARN] src/kkos_v520_unified.cpp not found — skipping compilation."
        KKOS_BUILT=0
    fi
fi

echo ""
# ─────────────────────────────────────────────────────────────────────────────
# PHASE 2 — ODYSSEUS AI WORKSPACE SETUP
# ─────────────────────────────────────────────────────────────────────────────
echo "[PHASE 2/3] Odysseus AI Workspace Setup"
echo ""

if [ ! -d "$ODYSSEUS_DIR" ]; then
    echo "[ERROR] odysseus/ directory not found at: $ODYSSEUS_DIR"
    echo "        Make sure the odysseus folder is inside the bundle root."
    ODYSSEUS_READY=0
else
    # 2a. Find Python 3.11+
    PY=""
    if [[ "$(uname -m)" == "arm64" && "$(uname)" == "Darwin" ]]; then
        # Apple Silicon: require arm64 Python from Homebrew
        for cand in /opt/homebrew/bin/python3.13 /opt/homebrew/bin/python3.12 /opt/homebrew/bin/python3.11; do
            if [ -x "$cand" ] && "$cand" -c 'import sys; exit(0 if sys.version_info[:2]>=(3,11) else 1)' 2>/dev/null; then
                PY="$cand"; break
            fi
        done
        if [ -z "$PY" ]; then
            echo "[INFO] No Homebrew Python 3.11+ found. Installing via Homebrew..."
            brew install python@3.11 || true
            PY="$(command -v /opt/homebrew/bin/python3.11 || true)"
        fi
    else
        for cand in python3.13 python3.12 python3.11 python3; do
            p="$(command -v "$cand" 2>/dev/null)" || continue
            if "$p" -c 'import sys; exit(0 if sys.version_info[:2]>=(3,11) else 1)' 2>/dev/null; then
                PY="$p"; break
            fi
        done
    fi

    if [ -z "$PY" ]; then
        echo "[ERROR] Python 3.11+ not found. Install it and re-run."
        ODYSSEUS_READY=0
    else
        echo "[ok] Python: $($PY --version)"

        # 2b. Virtual environment
        VENV_PY="$ODYSSEUS_DIR/venv/bin/python3"
        if [ ! -f "$VENV_PY" ]; then
            echo "[1/4] Creating Odysseus virtual environment..."
            "$PY" -m venv "$ODYSSEUS_DIR/venv"
        else
            echo "[1/4] Odysseus venv already exists — skipping."
        fi

        # 2c. Dependencies (hash-gated to skip on re-runs)
        REQ_HASH="$(md5sum "$ODYSSEUS_DIR/requirements.txt" 2>/dev/null | cut -d' ' -f1 || md5 -q "$ODYSSEUS_DIR/requirements.txt" 2>/dev/null)"
        HASH_FILE="$ODYSSEUS_DIR/venv/.requirements_hash"
        if [ ! -f "$HASH_FILE" ] || [ "$REQ_HASH" != "$(cat "$HASH_FILE" 2>/dev/null)" ]; then
            echo "[2/4] Installing Odysseus dependencies (first run takes a few minutes)..."
            "$VENV_PY" -m pip install --quiet --upgrade pip
            "$VENV_PY" -m pip install -r "$ODYSSEUS_DIR/requirements.txt"
            echo "$REQ_HASH" > "$HASH_FILE"
        else
            echo "[2/4] Odysseus dependencies up to date — skipping install."
        fi

        # Remove conflicting chromadb-client
        if "$VENV_PY" -m pip show chromadb-client &>/dev/null 2>&1; then
            echo "[2/4] Removing conflicting chromadb-client..."
            "$VENV_PY" -m pip uninstall -y chromadb-client
            "$VENV_PY" -m pip install --force-reinstall chromadb
        fi

        # 2d. First-time setup
        echo "[3/4] Running Odysseus first-time setup..."
        ODYSSEUS_SKIP_RUN_HINT=1 "$VENV_PY" "$ODYSSEUS_DIR/setup.py"

        # 2e. Write start-all.sh
        echo "[4/4] Writing start-all.sh launch helper..."
        KKOS_BIN="$SCRIPT_DIR/bin/$GAME_NAME"
        cat > "$SCRIPT_DIR/start-all.sh" <<STARTSCRIPT
#!/bin/bash
# KKOS v$VERSION Unified Bundle — Start Everything
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
ODYSSEUS_DIR="\$SCRIPT_DIR/odysseus"
VENV_PY="\$ODYSSEUS_DIR/venv/bin/python3"
KKOS_BIN="\$SCRIPT_DIR/bin/$GAME_NAME"

echo "Starting KKOS + Odysseus..."

# Start Odysseus in the background
echo "  Odysseus AI → http://127.0.0.1:7000"
"\$VENV_PY" -m uvicorn app:app --host 127.0.0.1 --port 7000 --app-dir "\$ODYSSEUS_DIR" &
ODYSSEUS_PID=\$!

# Wait briefly, then launch KKOS
sleep 2
if [ -x "\$KKOS_BIN" ]; then
    echo "  Launching KKOS..."
    "\$KKOS_BIN" &
fi

# Keep script alive; Ctrl+C stops both
trap "kill \$ODYSSEUS_PID 2>/dev/null" EXIT INT TERM
wait \$ODYSSEUS_PID
STARTSCRIPT
        chmod +x "$SCRIPT_DIR/start-all.sh"
        echo "[ok] start-all.sh written."
        ODYSSEUS_READY=1
    fi
fi

echo ""
# ─────────────────────────────────────────────────────────────────────────────
# PHASE 3 — SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
echo "[PHASE 3/3] Build Summary"
echo ""
[ "$KKOS_BUILT"    = "1" ] && echo "  [ok] KKOS binary:   bin/$GAME_NAME" || echo "  [--] KKOS binary:   not built (see errors above)"
[ "$ODYSSEUS_READY" = "1" ] && echo "  [ok] Odysseus:      odysseus/ (venv + data ready)" || echo "  [--] Odysseus:      not ready (see errors above)"
echo "  [ok] Codex:         bin/KURFEW_KULT_CODEX.md"
[ -f "$SCRIPT_DIR/start-all.sh" ] && echo "  [ok] Launcher:      start-all.sh"
echo ""
echo "  To start everything:"
echo "    ./start-all.sh"
echo ""
echo "  Odysseus will be at: http://127.0.0.1:7000"
echo "  Log in with the admin credentials shown by setup above."
echo ""
echo "Build complete."
