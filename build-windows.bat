@echo off
setlocal EnableDelayedExpansion
:: =============================================================================
:: KKOS v5.2 Unified Bundle — Master Build Script (Windows)
:: Builds KKOS C++ DAW engine AND sets up Odysseus AI workspace.
:: =============================================================================

set VERSION=5.2.0
set GAME_NAME=kkos_v520
set CC="C:\msys64\mysys64_new\ucrt64\bin\g++.exe"
set XXD="C:\msys64\mysys64_new\ucrt64\bin\xxd.exe"
set SCRIPT_DIR=%~dp0
set ODYSSEUS_DIR=%SCRIPT_DIR%odysseus

echo.
echo [KKOS] ==================================================================
echo [KKOS]  KKOS v%VERSION% Unified Bundle — Master Build (Windows)
echo [KKOS]  Node: %COMPUTERNAME%
echo [KKOS] ==================================================================
echo.

:: ─────────────────────────────────────────────────────────────────────────────
:: PHASE 1 — KKOS C++ BUILD
:: ─────────────────────────────────────────────────────────────────────────────
echo [PHASE 1/3] KKOS C++ Build
echo.

:: Memory check — LTO is memory intensive
for /f "tokens=2 delims==" %%a in ('wmic os get freephysicalmemory /value') do set /a FREE_RAM=%%a / 1024
if %FREE_RAM% LSS 800 (
    echo [WARNING] Low RAM detected (%FREE_RAM%MB^). Compilation may be slow or fail.
)

:: Folder relabeling
for %%I in ("%SCRIPT_DIR%.") do set "CURRENT_FOLDER=%%~nxI"
if /i "%CURRENT_FOLDER%"=="KKOS_v4.5_Unified_Bundle" (
    echo [RELABEL] Legacy root folder detected — will rename after build.
)

:: File relabeling
if exist "%SCRIPT_DIR%src\kkos_v2_unified.cpp" (
    echo [RELABEL] Moving legacy kkos_v2_unified.cpp to kkos_v520_unified.cpp...
    ren "%SCRIPT_DIR%src\kkos_v2_unified.cpp" "kkos_v520_unified.cpp"
)

if not exist "%SCRIPT_DIR%bin" mkdir "%SCRIPT_DIR%bin"

:: 1a. Codex consolidation (both KKOS + Odysseus docs)
echo [CODEX] Consolidating all documentation into KURFEW_KULT_CODEX.md...
echo # KURFEW KULT CODEX > "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
echo Compiled on: %date% %time% >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
echo Bundle: KKOS v%VERSION% + Odysseus AI Workspace >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
echo. >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
echo ## KKOS Core Docs >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
echo. >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"

for /r "%SCRIPT_DIR%" %%f in (*.md) do (
    :: Skip the codex itself and odysseus subdir (handled separately below)
    set "FILEPATH=%%f"
    if not "%%~nxf"=="KURFEW_KULT_CODEX.md" (
        echo !FILEPATH! | findstr /i "\\odysseus\\" >nul
        if errorlevel 1 (
            echo [DOC] KKOS: %%~nxf
            type "%%f" >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
            echo. >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
            echo --- >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
            echo. >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
        )
    )
)

echo. >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
echo ## Odysseus AI Workspace Docs >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
echo. >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"

if exist "%ODYSSEUS_DIR%" (
    for /r "%ODYSSEUS_DIR%" %%f in (*.md) do (
        echo [DOC] Odysseus: %%~nxf
        type "%%f" >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
        echo. >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
        echo --- >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
        echo. >> "%SCRIPT_DIR%bin\KURFEW_KULT_CODEX.md"
    )
) else (
    echo [WARN] odysseus/ directory not found — skipping Odysseus docs
)

:: 1b. Resource embedding
if exist "%XXD%" (
    echo [RESOURCE] Encoding Codex as C-Header...
    pushd "%SCRIPT_DIR%bin"
    %XXD% -i KURFEW_KULT_CODEX.md > codex_resource.h
    popd
) else (
    echo [WARNING] xxd.exe not found — resource generation skipped.
)

:: 1c. Compilation
echo [COMPILE] Running G++ Unified Build...
set SOURCES="%SCRIPT_DIR%src\kkos_v520_unified.cpp" "%SCRIPT_DIR%Single-Exe-1.0.0\raylib-5.5\src\*.c"
set INCLUDES=-I"%SCRIPT_DIR%." -I"%SCRIPT_DIR%bin" -I"%SCRIPT_DIR%Single-Exe-1.0.0\raylib-5.5\src" -I"%SCRIPT_DIR%Single-Exe-1.0.0\raylib-5.5\src\external\glfw\include"
set DEFINES=-DUNICODE -D_UNICODE -DNOGDI -DNOUSER -DKKOS_VERSION_STR=\"%VERSION%\" -DKKOS_VERSION_MAJOR=5 -DKKOS_VERSION_MINOR=2 -DKKOS_ODYSSEUS_URL=\"http://127.0.0.1:7000\"
set FLAGS=-std=c++17 -O3 -flto -ffast-math -march=native -mtune=native -fno-plt -Wall -Wno-missing-braces
set LIBS=-lopengl32 -lgdi32 -lwinmm -lpthread

%CC% %FLAGS% %SOURCES% -o "%SCRIPT_DIR%bin\%GAME_NAME%.exe" %INCLUDES% %DEFINES% %LIBS%

if %ERRORLEVEL% equ 0 (
    echo [SUCCESS] KKOS v%VERSION% build: bin\%GAME_NAME%.exe
    if /i "%CURRENT_FOLDER%"=="KKOS_v4.5_Unified_Bundle" (
        pushd "%SCRIPT_DIR%.."
        ren "KKOS_v4.5_Unified_Bundle" "KKOS_v5.2.0_Unified_Bundle" 2>nul
        if errorlevel 1 (
            echo [NOTICE] Automatic folder rename failed — rename manually to KKOS_v5.2.0_Unified_Bundle.
        ) else (
            echo [SUCCESS] Folder relabeled to KKOS_v5.2.0_Unified_Bundle.
        )
        popd
    )
) else (
    echo [FAILURE] KKOS compilation failed. Check syntax errors in source files.
    echo          Build continues to Odysseus setup — fix C++ errors and re-run.
)

echo.
:: ─────────────────────────────────────────────────────────────────────────────
:: PHASE 2 — ODYSSEUS AI WORKSPACE SETUP
:: ─────────────────────────────────────────────────────────────────────────────
echo [PHASE 2/3] Odysseus AI Workspace Setup
echo.

if not exist "%ODYSSEUS_DIR%" (
    echo [ERROR] odysseus\ directory not found at: %ODYSSEUS_DIR%
    echo         Make sure the odysseus folder is inside the bundle root.
    goto :phase3
)

:: 2a. Find Python 3.11+
set PYEXE=
for %%v in (3.13 3.12 3.11) do (
    if not defined PYEXE (
        py -%%v -c "import sys" >nul 2>&1
        if not errorlevel 1 (
            set PYEXE=py
            set PYVER=-%%v
        )
    )
)
if not defined PYEXE (
    python -c "import sys; exit(0 if sys.version_info[:2] >= (3,11) else 1)" >nul 2>&1
    if not errorlevel 1 (
        set PYEXE=python
        set PYVER=
    )
)
if not defined PYEXE (
    echo [ERROR] Python 3.11+ not found. Install from https://www.python.org/downloads/
    echo         Odysseus setup skipped.
    goto :phase3
)
echo [ok] Python found: %PYEXE% %PYVER%

:: 2b. Virtual environment
set VENV_PY=%ODYSSEUS_DIR%\venv\Scripts\python.exe
if not exist "%VENV_PY%" (
    echo [1/4] Creating Odysseus virtual environment...
    %PYEXE% %PYVER% -m venv "%ODYSSEUS_DIR%\venv"
    if errorlevel 1 (
        echo [ERROR] venv creation failed.
        goto :phase3
    )
) else (
    echo [1/4] Odysseus venv already exists — skipping creation.
)

:: 2c. Dependencies
echo [2/4] Installing Odysseus dependencies (first run takes a few minutes^)...
"%VENV_PY%" -m pip install --upgrade pip --quiet
"%VENV_PY%" -m pip install -r "%ODYSSEUS_DIR%\requirements.txt"
if errorlevel 1 (
    echo [ERROR] Odysseus dependency install failed. Check pip output above.
    goto :phase3
)

:: Remove conflicting chromadb-client if present
"%VENV_PY%" -m pip show chromadb-client >nul 2>&1
if not errorlevel 1 (
    echo [2/4] Removing conflicting chromadb-client...
    "%VENV_PY%" -m pip uninstall -y chromadb-client
    "%VENV_PY%" -m pip install --force-reinstall chromadb
)

:: 2d. First-time setup
echo [3/4] Running Odysseus first-time setup...
set ODYSSEUS_SKIP_RUN_HINT=1
"%VENV_PY%" "%ODYSSEUS_DIR%\setup.py"
if errorlevel 1 (
    echo [WARN] Odysseus setup.py returned an error — check output above.
)

:: 2e. Copy start script to bin for convenience
echo [4/4] Writing start-all.bat launch helper...
echo @echo off > "%SCRIPT_DIR%start-all.bat"
echo echo Starting KKOS + Odysseus... >> "%SCRIPT_DIR%start-all.bat"
echo echo Odysseus AI will be at http://127.0.0.1:7000 >> "%SCRIPT_DIR%start-all.bat"
echo start "" "%SCRIPT_DIR%bin\%GAME_NAME%.exe" >> "%SCRIPT_DIR%start-all.bat"
echo "%VENV_PY%" -m uvicorn app:app --host 127.0.0.1 --port 7000 --app-dir "%ODYSSEUS_DIR%" >> "%SCRIPT_DIR%start-all.bat"
echo [ok] start-all.bat written.

echo.
:phase3
:: ─────────────────────────────────────────────────────────────────────────────
:: PHASE 3 — SUMMARY
:: ─────────────────────────────────────────────────────────────────────────────
echo [PHASE 3/3] Build Summary
echo.
echo   KKOS binary:   bin\%GAME_NAME%.exe
echo   Odysseus:      odysseus\  (venv + data ready)
echo   Codex:         bin\KURFEW_KULT_CODEX.md
echo   Launcher:      start-all.bat
echo.
echo   To start everything:
echo     start-all.bat
echo.
echo   Odysseus web UI will open at: http://127.0.0.1:7000
echo   Log in with the admin credentials shown by setup above.
echo.
echo [KKOS] Build complete.
