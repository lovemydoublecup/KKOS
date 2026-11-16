#!/bin/bash
# =============================================================================
# KKOS v5.2.0 + Odysseus — UNIFIED MASTER BUILD SCRIPT (Linux / macOS)
# Kurfew Kult Operating System
#
# Consolidates: build-all.sh, build_linux.sh, build-macos-app.sh,
#               start-macos.sh, start-all.sh, deploy.sh
#
# Usage:
#   ./build.sh                 Full build (KKOS C++ + Odysseus Python)
#   ./build.sh kkos            KKOS engine only
#   ./build.sh odysseus        Odysseus Python setup only
#   ./build.sh run             Build then launch everything
#   ./build.sh macos-app       Build macOS Odysseus.app + .dmg
#   ./build.sh diag            Compiler + environment report (no build)
#   ./build.sh clean           Archive legacy files, clear build artifacts
# =============================================================================
set -euo pipefail

# ── Always execute from the script's own directory ────────────────────────────
# ROOT CAUSE FIX: all prior build logs were empty and every exit was 1 because
# the scripts were invoked from a directory other than the project root.
# All relative paths (src/kkos_v520_unified.cpp, Single-Exe-1.0.0/...) failed
# silently since stderr wasn't captured. This line fixes it unconditionally.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERSION="5.2.0"
GAME_NAME="kkos_v520"
BIN_DIR="$SCRIPT_DIR/bin"
OBJ_DIR="$SCRIPT_DIR/obj"
LOG_DIR="$SCRIPT_DIR/logs"
SRC_DIR="$SCRIPT_DIR/src"
ODYSSEUS_DIR="$SCRIPT_DIR/odysseus"
RAYLIB_DIR="$SCRIPT_DIR/Single-Exe-1.0.0/raylib-5.5/src"

mkdir -p "$BIN_DIR" "$OBJ_DIR" "$LOG_DIR"

OS="$(uname -s)"
ARCH="$(uname -m)"
MODE="${1:-all}"

# ── Colors ────────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
    GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RED="\033[0;31m"; CYAN="\033[0;36m"; RESET="\033[0m"
else
    GREEN=""; YELLOW=""; RED=""; CYAN=""; RESET=""
fi
ok()   { echo -e "${GREEN}[ok]${RESET}  $*"; }
warn() { echo -e "${YELLOW}[!!]${RESET}  $*"; }
fail() { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }
step() { echo -e "\n${CYAN}==> $*${RESET}"; }

echo ""
echo "================================================================"
echo "  KKOS v$VERSION | Kurfew Kult Operating System"
echo "  Mode: $MODE   OS: $OS/$ARCH   Dir: $SCRIPT_DIR"
echo "================================================================"
echo ""

# =============================================================================
# DIAG MODE
# =============================================================================
if [ "$MODE" = "diag" ]; then
    step "Compiler Environment Report"
    echo "  Working directory: $(pwd)"
    echo ""

    # Compiler
    if command -v g++ &>/dev/null; then
        ok "g++ found: $(command -v g++)"
        g++ --version
    else
        warn "g++ NOT found on PATH"
    fi
    echo ""

    # Source
    if [ -f "$SRC_DIR/kkos_v520_unified.cpp" ]; then
        ok "src/kkos_v520_unified.cpp exists"
        echo "  Running -fsyntax-only probe..."
        INCLUDES="-I$SCRIPT_DIR -I$BIN_DIR"
        [ -d "$RAYLIB_DIR" ] && INCLUDES="$INCLUDES -I$RAYLIB_DIR"
        g++ -fsyntax-only -std=c++17 $INCLUDES \
            -DKKOS_VERSION_STR=\"$VERSION\" \
            "$SRC_DIR/kkos_v520_unified.cpp" 2>&1 || warn "Syntax probe failed (see errors above)"
    else
        warn "src/kkos_v520_unified.cpp NOT found — check working directory"
    fi
    echo ""

    # raylib
    if [ -f "$RAYLIB_DIR/raylib.h" ]; then
        ok "raylib.h found"
    else
        warn "raylib.h NOT found at $RAYLIB_DIR"
        warn "Expected: Single-Exe-1.0.0/raylib-5.5/src/raylib.h"
    fi
    echo ""

    # Python
    for cand in python3.13 python3.12 python3.11 python3; do
        p="$(command -v "$cand" 2>/dev/null)" || continue
        if "$p" -c 'import sys; exit(0 if sys.version_info[:2]>=(3,11) else 1)' 2>/dev/null; then
            ok "Python 3.11+: $("$p" --version) at $p"; break
        fi
    done

    echo ""
    echo "Run ./build.sh to proceed with the build."
    exit 0
fi

# =============================================================================
# CLEAN MODE
# =============================================================================
if [ "$MODE" = "clean" ]; then
    step "Archiving legacy files"
    LEGACY="$SCRIPT_DIR/archive/legacy"
    mkdir -p "$LEGACY/src" "$LEGACY/bin" "$LEGACY/scripts" "$LEGACY/vscode_stray"

    for f in kkos_v2_unified.cpp kkos_v43_sharded.cpp kkos_v2_21_monolith.cpp \
              kkos_v2_unified_replacement.cpp kkos_v39_production.cpp; do
        [ -f "$SRC_DIR/$f" ] && mv "$SRC_DIR/$f" "$LEGACY/src/" && echo "  archived: src/$f"
    done
    for f in kkos_v2 kkos_v39 kkos_v43 kkos_v45; do
        [ -f "$BIN_DIR/$f" ] && mv "$BIN_DIR/$f" "$LEGACY/bin/" && echo "  archived: bin/$f"
    done
    for f in build-windows.bat build-all-steps.bat build-kkos-complete.bat \
              build_windows.bat launch-windows.ps1 build_and_run.ps1 \
              update_windows.bat install_gdb.bat install_gdb_proper.bat \
              cleanup.bat KKOS.bat KKOS_Installer.bat build-all.sh \
              build_linux.sh build-macos-app.sh start-macos.sh \
              start-all.sh deploy.sh install-gdb.sh install_gdb.sh \
              install_aosp_deps.sh build_aosp.sh; do
        [ -f "$SCRIPT_DIR/$f" ] && mv "$SCRIPT_DIR/$f" "$LEGACY/scripts/" && echo "  archived script: $f"
    done
    for f in c_cpp_properties.json launch.json settings.json tasks.json; do
        [ -f "$SCRIPT_DIR/$f" ] && mv "$SCRIPT_DIR/$f" "$LEGACY/vscode_stray/" && echo "  archived stray file: $f"
    done
    [ -d "$OBJ_DIR" ] && rm -rf "$OBJ_DIR" && echo "  cleared: obj/"
    ok "Clean complete. Legacy files → archive/legacy/"
    exit 0
fi

# =============================================================================
# MACOS APP MODE
# =============================================================================
if [ "$MODE" = "macos-app" ]; then
    [ "$OS" != "Darwin" ] && fail "macos-app mode requires macOS"
    step "Building Odysseus.app + .dmg"

    APP_NAME="Odysseus"
    PORT="${ODYSSEUS_PORT:-7860}"
    DIST="$SCRIPT_DIR/dist"
    APP="$DIST/$APP_NAME.app"

    rm -rf "$APP"
    mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$DIST"

    # Icon
    if [ -f "$SCRIPT_DIR/docs/odysseus.jpg" ] && command -v sips &>/dev/null; then
        TMPIMG="$(mktemp -d)"
        sips -c 720 720 "$SCRIPT_DIR/docs/odysseus.jpg" --out "$TMPIMG/sq.png" &>/dev/null || \
            cp "$SCRIPT_DIR/docs/odysseus.jpg" "$TMPIMG/sq.png"
        sips -z 512 512 "$TMPIMG/sq.png" --out "$TMPIMG/icon.png" &>/dev/null
        sips -s format icns "$TMPIMG/icon.png" \
            --out "$APP/Contents/Resources/odysseus.icns" &>/dev/null && \
            ok "Icon: odysseus.icns" || warn "Icon conversion skipped"
        rm -rf "$TMPIMG"
    else
        warn "Icon skipped (no docs/odysseus.jpg or sips unavailable)"
    fi

    # Info.plist
    cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>     <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>      <string>com.kkos.odysseus.launcher</string>
    <key>CFBundleVersion</key>         <string>$VERSION</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleExecutable</key>      <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>        <string>odysseus</string>
    <key>LSMinimumSystemVersion</key>  <string>11.0</string>
    <key>NSHighResolutionCapable</key> <true/>
</dict>
</plist>
PLIST

    # Launcher executable
    INSTALL_DIR="$SCRIPT_DIR"
    cat > "$APP/Contents/MacOS/$APP_NAME" <<LAUNCHER
#!/bin/bash
INSTALL_DIR="$INSTALL_DIR"
PORT="$PORT"
URL="http://127.0.0.1:\${PORT}"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:\$PATH"
UVICORN="\$INSTALL_DIR/venv/bin/uvicorn"
LOG="\$INSTALL_DIR/logs/odysseus-app.log"
notify() { /usr/bin/osascript -e "display notification \"\$1\" with title \"Odysseus\"" &>/dev/null; }
die_gui() {
  /usr/bin/osascript -e "display dialog \"\$1\" with title \"Odysseus\" buttons {\"OK\"} default button 1 with icon stop" &>/dev/null
  exit 1
}
[ -x "\$UVICORN" ] || die_gui "Odysseus isn't set up yet. Open Terminal and run:\n\ncd \$INSTALL_DIR\n./build.sh odysseus"
open_ui() {
  for b in "Google Chrome" "Microsoft Edge" "Brave Browser" "Chromium"; do
    for base in "/Applications" "\$HOME/Applications"; do
      if [ -d "\$base/\$b.app" ]; then
        exe="\$(/usr/bin/defaults read "\$base/\$b.app/Contents/Info" CFBundleExecutable 2>/dev/null)"
        bin="\$base/\$b.app/Contents/MacOS/\$exe"
        [ -x "\$bin" ] && "\$bin" --app="\$URL" --new-window &>/dev/null & return 0
      fi
    done
  done
  /usr/bin/open "\$URL"
}
mkdir -p "\$INSTALL_DIR/logs"
if /usr/bin/curl -s -o /dev/null --max-time 2 "\$URL"; then open_ui; exit 0; fi
notify "Starting Odysseus…"
cd "\$INSTALL_DIR"
[ "\$(uname -m)" = "arm64" ] && ARCH_PREFIX="arch -arm64" || ARCH_PREFIX=""
\$ARCH_PREFIX "\$UVICORN" app:app --host 127.0.0.1 --port "\$PORT" >>"\$LOG" 2>&1 &
SERVER_PID=\$!
trap 'kill \$SERVER_PID 2>/dev/null; exit 0' TERM INT
READY=0
for i in \$(seq 1 120); do
  /usr/bin/curl -s -o /dev/null --max-time 2 "\$URL" && { READY=1; break; }
  kill -0 "\$SERVER_PID" 2>/dev/null || die_gui "Odysseus failed to start.\nLog: \$LOG"
  sleep 1
done
[ "\$READY" = "1" ] && open_ui || notify "Odysseus is taking a while — open \$URL manually"
wait "\$SERVER_PID"
LAUNCHER
    chmod +x "$APP/Contents/MacOS/$APP_NAME"
    touch "$APP"
    ok "$APP"

    # .dmg
    echo "Packaging $APP_NAME.dmg..."
    STAGE="$(mktemp -d)/dmg"
    mkdir -p "$STAGE"
    cp -R "$APP" "$STAGE/"
    ln -s /Applications "$STAGE/Applications"
    rm -f "$DIST/$APP_NAME.dmg"
    hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO \
        "$DIST/$APP_NAME.dmg" >/dev/null
    rm -rf "$STAGE"
    ok "$DIST/$APP_NAME.dmg"
    echo ""
    echo "Run it:    open '$APP'"
    echo "Install:   open '$DIST/$APP_NAME.dmg'  → drag Odysseus to Applications"
    exit 0
fi

# =============================================================================
# PHASE 0 — ENVIRONMENT VALIDATION
# =============================================================================
step "Environment Validation"

# Legacy source rename
if [ -f "$SRC_DIR/kkos_v2_unified.cpp" ] && [ ! -f "$SRC_DIR/kkos_v520_unified.cpp" ]; then
    mv "$SRC_DIR/kkos_v2_unified.cpp" "$SRC_DIR/kkos_v520_unified.cpp"
    warn "Renamed kkos_v2_unified.cpp → kkos_v520_unified.cpp"
fi

# Compiler detection
SKIP_KKOS=0
GPP=""
if command -v g++ &>/dev/null; then
    GPP="$(command -v g++)"
    ok "g++: $(g++ --version | head -1)"
else
    warn "g++ not found — skipping KKOS C++ build"
    warn "  Linux:  sudo apt install build-essential"
    warn "  macOS:  xcode-select --install  OR  brew install gcc"
    SKIP_KKOS=1
fi

# Build flags — macOS disables LTO (Apple ld incompatibility)
if [ "$OS" = "Darwin" ]; then
    CXXFLAGS="-std=c++17 -O3 -ffast-math -march=native -Wall -Wno-missing-braces"
    warn "macOS: LTO disabled (Apple ld incompatibility)"
else
    CXXFLAGS="-std=c++17 -O3 -flto -ffast-math -march=native -mtune=native -fno-plt -Wall -Wno-missing-braces"
fi

INCLUDES="-I$SCRIPT_DIR -I$BIN_DIR"
[ -d "$RAYLIB_DIR" ] && INCLUDES="$INCLUDES -I$RAYLIB_DIR -I$RAYLIB_DIR/external/glfw/include"

DEFINES="-DPLATFORM_DESKTOP -DKKOS_VERSION_STR=\"$VERSION\" -DKKOS_VERSION_MAJOR=5 -DKKOS_VERSION_MINOR=2 -DKKOS_ODYSSEUS_URL=\"http://127.0.0.1:7000\""

echo ""
if [ "$MODE" = "odysseus" ]; then SKIP_KKOS=1; fi

# =============================================================================
# PHASE 1 — KKOS C++ BUILD
# =============================================================================
if [ "$SKIP_KKOS" -eq 0 ]; then
    step "KKOS C++ Build"

    if [ ! -f "$SRC_DIR/kkos_v520_unified.cpp" ]; then
        fail "Source not found: $SRC_DIR/kkos_v520_unified.cpp"
    fi

    # Syntax probe first — captures actual errors to log AND terminal
    echo "  Running syntax probe..."
    if ! g++ -fsyntax-only $CXXFLAGS $INCLUDES $DEFINES \
            "$SRC_DIR/kkos_v520_unified.cpp" 2>&1 | tee -a "$LOG_DIR/build.log"; then
        warn "Syntax probe failed — attempting full compile anyway (errors above)"
    else
        ok "Syntax probe passed"
    fi

    # Build object files
    OBJ_FILES=()

    # Compile raylib C sources if present
    if [ -d "$RAYLIB_DIR" ]; then
        echo "  Compiling raylib C sources..."
        for c_file in "$RAYLIB_DIR"/*.c; do
            [ -f "$c_file" ] || continue
            base="$(basename "$c_file" .c)"
            obj="$OBJ_DIR/$base.o"
            echo "    $base.c"
            gcc -std=c11 -O3 -march=native $DEFINES $INCLUDES \
                -c "$c_file" -o "$obj" >> "$LOG_DIR/build.log" 2>&1 \
                || fail "raylib compile failed: $base.c — see $LOG_DIR/build.log"
            OBJ_FILES+=("$obj")
        done
        ok "raylib sources compiled"
    fi

    # Compile KKOS C++ source
    echo "  Compiling kkos_v520_unified.cpp..."
    KKOS_OBJ="$OBJ_DIR/kkos_v520_unified.o"
    if ! g++ $CXXFLAGS $INCLUDES $DEFINES \
            -c "$SRC_DIR/kkos_v520_unified.cpp" \
            -o "$KKOS_OBJ" 2>&1 | tee -a "$LOG_DIR/build.log"; then
        echo ""
        echo "  ── Last errors ─────────────────────────────────────────────"
        tail -30 "$LOG_DIR/build.log"
        echo "  ────────────────────────────────────────────────────────────"
        fail "Compilation failed. Full log: $LOG_DIR/build.log  |  Run: ./build.sh diag"
    fi
    OBJ_FILES+=("$KKOS_OBJ")

    # Link
    echo "  Linking $GAME_NAME..."
    LINK_LIBS="-lpthread"
    [ "$OS" != "Darwin" ] && LINK_LIBS="$LINK_LIBS -lGL" || LINK_LIBS="$LINK_LIBS -framework OpenGL -framework Cocoa"

    if ! g++ $CXXFLAGS $INCLUDES $DEFINES \
            "${OBJ_FILES[@]}" \
            -o "$BIN_DIR/$GAME_NAME" $LINK_LIBS 2>&1 | tee -a "$LOG_DIR/build.log"; then
        fail "Link failed. See $LOG_DIR/build.log"
    fi
    chmod +x "$BIN_DIR/$GAME_NAME"
    ok "Built: $BIN_DIR/$GAME_NAME"

    # Codex
    if command -v xxd &>/dev/null; then
        echo "  Building KURFEW_KULT_CODEX.md..."
        {
            echo "# KURFEW KULT CODEX — KKOS v$VERSION"
            echo "Compiled: $(date)"
            echo ""
        } > "$BIN_DIR/KURFEW_KULT_CODEX.md"
        for f in "$SCRIPT_DIR"/*.md; do
            [ -f "$f" ] || continue
            [ "$(basename "$f")" = "KURFEW_KULT_CODEX.md" ] && continue
            cat "$f" >> "$BIN_DIR/KURFEW_KULT_CODEX.md"
            printf '\n---\n\n' >> "$BIN_DIR/KURFEW_KULT_CODEX.md"
        done
        if [ -d "$SCRIPT_DIR/docs" ]; then
            for f in "$SCRIPT_DIR/docs"/*.md; do
                [ -f "$f" ] || continue
                cat "$f" >> "$BIN_DIR/KURFEW_KULT_CODEX.md"
                printf '\n---\n\n' >> "$BIN_DIR/KURFEW_KULT_CODEX.md"
            done
        fi
        pushd "$BIN_DIR" >/dev/null
        xxd -i KURFEW_KULT_CODEX.md > codex_resource.h
        popd >/dev/null
        ok "codex_resource.h embedded"
    fi
    echo ""
fi

if [ "$MODE" = "kkos" ]; then
    # Still write launchers then exit
    goto_launchers=1
fi

# =============================================================================
# PHASE 2 — ODYSSEUS PYTHON SETUP
# =============================================================================
if [ "$MODE" != "kkos" ] || [ "${goto_launchers:-0}" -eq 0 ]; then
:
fi

if [ "$MODE" != "kkos" ]; then
    step "Odysseus AI Workspace Setup"

    if [ ! -d "$ODYSSEUS_DIR" ]; then
        warn "odysseus/ not found — skipping Python setup"
    else
        # Find Python 3.11+
        PY=""
        if [ "$ARCH" = "arm64" ] && [ "$OS" = "Darwin" ]; then
            for cand in /opt/homebrew/bin/python3.13 /opt/homebrew/bin/python3.12 /opt/homebrew/bin/python3.11; do
                [ -x "$cand" ] && "$cand" -c 'import sys; exit(0 if sys.version_info[:2]>=(3,11) else 1)' 2>/dev/null \
                    && PY="$cand" && break
            done
            [ -z "$PY" ] && brew install python@3.11 2>/dev/null || true
            [ -z "$PY" ] && PY="$(command -v /opt/homebrew/bin/python3.11 2>/dev/null || true)"
        else
            for cand in python3.13 python3.12 python3.11 python3; do
                p="$(command -v "$cand" 2>/dev/null)" || continue
                "$p" -c 'import sys; exit(0 if sys.version_info[:2]>=(3,11) else 1)' 2>/dev/null \
                    && PY="$p" && break
            done
        fi

        if [ -z "$PY" ]; then
            warn "Python 3.11+ not found — skipping Odysseus setup"
            warn "  Linux:  sudo apt install python3.11"
            warn "  macOS:  brew install python@3.11"
        else
            ok "Python: $("$PY" --version)"

            VENV_PY="$ODYSSEUS_DIR/venv/bin/python3"
            if [ ! -f "$VENV_PY" ]; then
                echo "  [1/4] Creating virtual environment..."
                "$PY" -m venv "$ODYSSEUS_DIR/venv"
            else
                echo "  [1/4] venv exists — skipping"
            fi

            # Hash-gated install (skip on re-runs if requirements unchanged)
            REQ_HASH="$(md5sum "$ODYSSEUS_DIR/requirements.txt" 2>/dev/null | cut -d' ' -f1 \
                        || md5 -q "$ODYSSEUS_DIR/requirements.txt" 2>/dev/null || echo "none")"
            HASH_FILE="$ODYSSEUS_DIR/venv/.requirements_hash"
            if [ ! -f "$HASH_FILE" ] || [ "$REQ_HASH" != "$(cat "$HASH_FILE" 2>/dev/null)" ]; then
                echo "  [2/4] Installing dependencies..."
                "$VENV_PY" -m pip install --quiet --upgrade pip
                "$VENV_PY" -m pip install -r "$ODYSSEUS_DIR/requirements.txt" 2>&1 \
                    | tee -a "$LOG_DIR/setup.log"
                echo "$REQ_HASH" > "$HASH_FILE"
            else
                echo "  [2/4] Dependencies up to date — skipping install"
            fi

            # Remove conflicting chromadb-client
            if "$VENV_PY" -m pip show chromadb-client &>/dev/null 2>&1; then
                echo "  [2/4] Removing conflicting chromadb-client..."
                "$VENV_PY" -m pip uninstall -y chromadb-client >> "$LOG_DIR/setup.log" 2>&1
                "$VENV_PY" -m pip install --force-reinstall chromadb >> "$LOG_DIR/setup.log" 2>&1
            fi

            echo "  [3/4] Running first-time setup..."
            ODYSSEUS_SKIP_RUN_HINT=1 "$VENV_PY" "$ODYSSEUS_DIR/setup.py" 2>&1 \
                | tee -a "$LOG_DIR/setup.log" || warn "setup.py returned error — check output"

            echo "  [4/4] Verifying imports..."
            "$VENV_PY" -c "import fastapi, chromadb; print('  ok  fastapi + chromadb loaded')" \
                2>/dev/null || warn "Import check failed — check $LOG_DIR/setup.log"

            ok "Odysseus ready"
        fi
    fi
    echo ""
fi

# =============================================================================
# PHASE 3 — WRITE LAUNCHER SCRIPTS
# =============================================================================
step "Writing Launcher Scripts"

# start-all.sh
cat > "$SCRIPT_DIR/start-all.sh" <<'STARTALL'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
ODYSSEUS_DIR="$SCRIPT_DIR/odysseus"
VENV_PY="$ODYSSEUS_DIR/venv/bin/python3"
KKOS_BIN="$SCRIPT_DIR/bin/kkos_v520"
PORT="${ODYSSEUS_PORT:-7000}"
HOST="${ODYSSEUS_HOST:-127.0.0.1}"

echo ""
echo "================================================"
echo "  KKOS v5.2.0 + Odysseus"
echo "  Odysseus: http://127.0.0.1:$PORT"
echo "================================================"
echo ""

ODY_PID=""
if [ -x "$VENV_PY" ]; then
    echo "  Starting Odysseus..."
    "$VENV_PY" -m uvicorn app:app --host "$HOST" --port "$PORT" \
        --app-dir "$ODYSSEUS_DIR" &
    ODY_PID=$!
    sleep 2
else
    echo "  [WARN] Odysseus not set up — run ./build.sh first"
fi

if [ -x "$KKOS_BIN" ]; then
    echo "  Launching KKOS..."
    "$KKOS_BIN" &
else
    echo "  [WARN] KKOS binary not found — run ./build.sh first"
fi

trap '[ -n "$ODY_PID" ] && kill "$ODY_PID" 2>/dev/null' EXIT INT TERM
[ -n "$ODY_PID" ] && wait "$ODY_PID"
STARTALL
chmod +x "$SCRIPT_DIR/start-all.sh"
ok "start-all.sh"

# start-kkos-only.sh
cat > "$SCRIPT_DIR/start-kkos-only.sh" <<'STARTKKOS'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
KKOS_BIN="$SCRIPT_DIR/bin/kkos_v520"
[ -x "$KKOS_BIN" ] || { echo "[ERROR] KKOS binary not found. Run ./build.sh first."; exit 1; }
"$KKOS_BIN"
STARTKKOS
chmod +x "$SCRIPT_DIR/start-kkos-only.sh"
ok "start-kkos-only.sh"

# start-odysseus-only.sh
cat > "$SCRIPT_DIR/start-odysseus-only.sh" <<'STARTODY'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
ODY_DIR="$SCRIPT_DIR/odysseus"
VENV_PY="$ODY_DIR/venv/bin/python3"
PORT="${ODYSSEUS_PORT:-7000}"
HOST="${ODYSSEUS_HOST:-127.0.0.1}"
[ -x "$VENV_PY" ] || { echo "[ERROR] Odysseus not set up. Run ./build.sh first."; exit 1; }
echo "Starting Odysseus at http://127.0.0.1:$PORT"
"$VENV_PY" -m uvicorn app:app --host "$HOST" --port "$PORT" --app-dir "$ODY_DIR"
STARTODY
chmod +x "$SCRIPT_DIR/start-odysseus-only.sh"
ok "start-odysseus-only.sh"

echo ""

# =============================================================================
# SUMMARY
# =============================================================================
echo "================================================================"
echo "  BUILD SUMMARY — KKOS v$VERSION"
echo "================================================================"
[ -f "$BIN_DIR/$GAME_NAME" ] && ok "KKOS Engine  : $BIN_DIR/$GAME_NAME" \
    || warn "KKOS Engine  : not built (check $LOG_DIR/build.log)"
[ -f "$ODYSSEUS_DIR/venv/bin/python3" ] && ok "Odysseus     : http://127.0.0.1:7000" \
    || warn "Odysseus     : not set up"
echo ""
echo "  Launchers:"
echo "    ./start-all.sh               KKOS + Odysseus"
echo "    ./start-kkos-only.sh         KKOS engine only"
echo "    ./start-odysseus-only.sh     Odysseus server only"
echo ""
echo "  Tools:"
echo "    ./build.sh diag              Environment diagnostic report"
echo "    ./build.sh macos-app         Build Odysseus.app + .dmg (macOS)"
echo "    ./build.sh clean             Archive legacy, clear obj/"
echo ""
echo "  Logs: $LOG_DIR/build.log  /  setup.log"
echo "================================================================"
echo ""

if [ "$MODE" = "run" ] && [ -f "$SCRIPT_DIR/start-all.sh" ]; then
    echo "Launching..."
    exec "$SCRIPT_DIR/start-all.sh"
fi
