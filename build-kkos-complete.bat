@echo off
setlocal EnableDelayedExpansion
REM =============================================================================
REM KKOS v5.2 Unified Bundle — Complete Build & Setup (Windows)
REM =============================================================================

set VERSION=5.2.0
set GAME_NAME=kkos_v520
set MSYS_BASE=C:\msys64\mysys64_new\ucrt64
set CC=%MSYS_BASE%\bin\g++.exe
set PYTHON=%MSYS_BASE%\bin\python.exe
set XXD=%MSYS_BASE%\bin\xxd.exe
set PATH=%MSYS_BASE%\bin;%PATH%

set SCRIPT_DIR=%~dp0
set ODYSSEUS_DIR=%SCRIPT_DIR%odysseus
set BIN_DIR=%SCRIPT_DIR%bin

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%SCRIPT_DIR%logs" mkdir "%SCRIPT_DIR%logs"

echo.
echo [KKOS] ==================================================================
echo [KKOS]  KKOS v%VERSION% Unified Bundle — Complete Build Setup
echo [KKOS]  Node: %COMPUTERNAME%
echo [KKOS] ==================================================================
echo.

REM ─────────────────────────────────────────────────────────────────────────────
REM PHASE 0 — VALIDATION
REM ─────────────────────────────────────────────────────────────────────────────
echo [PHASE 0/4] Environment Validation
echo.

if not exist "%CC%" (
    echo [ERROR] g++ not found at: %CC%
    exit /b 1
)
echo [ok] g++ found

if not exist "%PYTHON%" (
    echo [ERROR] Python not found at: %PYTHON%
    exit /b 1
)
echo [ok] Python found

if not exist "%XXD%" (
    echo [WARN] xxd not found - resource embedding will be skipped
    set XXD=
) else (
    echo [ok] xxd found
)

echo.

REM ─────────────────────────────────────────────────────────────────────────────
REM PHASE 1 — KKOS C++ BUILD  
REM ─────────────────────────────────────────────────────────────────────────────
echo [PHASE 1/4] KKOS C++ Build
echo.

REM Memory check — LTO is memory intensive
for /f "tokens=2 delims==" %%a in ('wmic os get freephysicalmemory /value') do set /a FREE_RAM=%%a / 1024
echo [SYSTEM] Free RAM: %FREE_RAM%MB
if %FREE_RAM% LSS 800 (
    echo [WARNING] Low RAM detected. Compilation may be slow.
    set FLAGS=-std=c++17 -O2 -ffast-math -march=native -Wall
) else (
    set FLAGS=-std=c++17 -O3 -flto -ffast-math -march=native -mtune=native -fno-plt -Wall -Wno-missing-braces
)

echo [BUILD] Compiling KKOS v%VERSION% unified engine...
echo [BUILD] Sources: src\kkos_v520_unified.cpp + raylib...

set CC_C=%MSYS_BASE%\bin\gcc.exe
set OBJ_DIR=%SCRIPT_DIR%obj
if not exist "%OBJ_DIR%" mkdir "%OBJ_DIR%"

set INCLUDES=-I"%SCRIPT_DIR%." -I"%BIN_DIR%" -I"%SCRIPT_DIR%Single-Exe-1.0.0\raylib-5.5\src" -I"%SCRIPT_DIR%Single-Exe-1.0.0\raylib-5.5\src\external\glfw\include"
set DEFINES=-DUNICODE -D_UNICODE -DNOGDI -DNOUSER -DKKOS_VERSION_STR=\"%VERSION%\" -DKKOS_VERSION_MAJOR=5 -DKKOS_VERSION_MINOR=2 -DKKOS_ODYSSEUS_URL=\"http://127.0.0.1:7000\"
set LIBS=-lopengl32 -lgdi32 -lwinmm -lpthread
set OBJ_FILES=

for %%F in (%SCRIPT_DIR%Single-Exe-1.0.0\raylib-5.5\src\*.c) do (
    echo [BUILD]   %%~nxF
    "%CC_C%" -std=c11 -O3 -march=native -mtune=native -Wall %INCLUDES% -c "%%~fF" -o "%OBJ_DIR%\%%~nF.o" 2>> "%SCRIPT_DIR%logs\build.log"
    if errorlevel 1 (
        echo [ERROR] Failed to compile C source: %%~nxF
        echo [ERROR] See %SCRIPT_DIR%logs\build.log
        exit /b 1
    )
    set OBJ_FILES=!OBJ_FILES! "%OBJ_DIR%\%%~nF.o"
)

echo [BUILD] Compiling KKOS C++ source with g++...
"%CC%" -std=c++17 -O3 -march=native -mtune=native -Wall %INCLUDES% %DEFINES% -c "%SCRIPT_DIR%src\kkos_v520_unified.cpp" -o "%OBJ_DIR%\kkos_v520_unified.o" 2>> "%SCRIPT_DIR%logs\build.log"
if errorlevel 1 (
    echo [ERROR] Failed to compile C++ source: kkos_v520_unified.cpp
    echo [ERROR] See %SCRIPT_DIR%logs\build.log
    exit /b 1
)
set OBJ_FILES=!OBJ_FILES! "%OBJ_DIR%\kkos_v520_unified.o"

echo [BUILD] Linking executable...
"%CC%" %INCLUDES% %DEFINES% %OBJ_FILES% -o "%BIN_DIR%\%GAME_NAME%.exe" %LIBS% 2>> "%SCRIPT_DIR%logs\build.log"

if %ERRORLEVEL% equ 0 (
    echo [SUCCESS] KKOS v%VERSION% built successfully
    echo [BINARY] %BIN_DIR%\%GAME_NAME%.exe
) else (
    echo [FAILURE] KKOS compilation failed. See logs\build.log
    echo           Continuing to Odysseus setup...
)

echo.

REM ─────────────────────────────────────────────────────────────────────────────
REM PHASE 2 — ODYSSEUS AI WORKSPACE SETUP
REM ─────────────────────────────────────────────────────────────────────────────
echo [PHASE 2/4] Odysseus AI Workspace Setup
echo.

if not exist "%ODYSSEUS_DIR%" (
    echo [ERROR] odysseus\ directory not found at: %ODYSSEUS_DIR%
    goto :phase3
)

set VENV_DIR=%ODYSSEUS_DIR%\venv
set VENV_PYTHON=%VENV_DIR%\Scripts\python.exe
set VENV_PIP=%VENV_DIR%\Scripts\pip.exe

echo [1/5] Creating virtual environment...
if not exist "%VENV_PYTHON%" (
    "%PYTHON%" -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo [ERROR] venv creation failed
        goto :phase3
    )
) else (
    echo [ok] venv already exists
)

echo [2/5] Upgrading pip in venv...
"%VENV_PYTHON%" -m pip install --upgrade pip --quiet 2>> "%SCRIPT_DIR%logs\setup.log"

echo [3/5] Installing Python dependencies (this may take several minutes)...
echo        FastAPI, SQLAlchemy, ChromaDB, CalDAV, and 40+ other packages...
"%VENV_PIP%" install -r "%ODYSSEUS_DIR%\requirements.txt" 2>> "%SCRIPT_DIR%logs\setup.log"
if errorlevel 1 (
    echo [WARN] Some dependencies may have failed. Check logs\setup.log
)

echo [4/5] Running Odysseus first-time setup...
set ODYSSEUS_SKIP_RUN_HINT=1
"%VENV_PYTHON%" "%ODYSSEUS_DIR%\setup.py" 2>> "%SCRIPT_DIR%logs\setup.log"

echo [5/5] Verifying Odysseus installation...
"%VENV_PYTHON%" -c "import fastapi, chromadb, caldav; print('[ok] All core dependencies loaded')" 2>> "%SCRIPT_DIR%logs\setup.log"

echo [SUCCESS] Odysseus setup complete
echo [VENV] %VENV_DIR%

echo.

REM ─────────────────────────────────────────────────────────────────────────────
REM PHASE 3 — CREATE LAUNCHER SCRIPTS
REM ─────────────────────────────────────────────────────────────────────────────

:phase3
echo [PHASE 3/4] Launcher Script Generation
echo.

echo [WRITE] Creating start-all.bat launcher...

(
    echo @echo off
    echo setlocal EnableDelayedExpansion
    echo.
    echo echo ================================================================
    echo echo  KKOS v%VERSION% + Odysseus AI Workspace Launcher
    echo echo ================================================================
    echo echo.
    echo echo Starting services...
    echo echo.
    echo echo Odysseus AI will open at: http://127.0.0.1:7000
    echo echo KKOS Game Engine will launch in separate window
    echo echo.
    echo echo (Press Ctrl+C in either window to stop)
    echo echo.
    echo.
    echo start "KKOS v%VERSION%" "%BIN_DIR%\%GAME_NAME%.exe"
    echo.
    echo if exist "%VENV_PYTHON%" (
    echo     echo Starting Odysseus API server...
    echo     "%VENV_PYTHON%" -m uvicorn app:app --host 127.0.0.1 --port 7000 --app-dir "%ODYSSEUS_DIR%"
    echo ) else (
    echo     echo [ERROR] Odysseus setup incomplete. Run this script again.
    echo     pause
    echo )
) > "%SCRIPT_DIR%start-all.bat"

echo [ok] %SCRIPT_DIR%start-all.bat created

echo [WRITE] Creating start-kkos-only.bat launcher...
(
    echo @echo off
    echo "%BIN_DIR%\%GAME_NAME%.exe"
) > "%SCRIPT_DIR%start-kkos-only.bat"
echo [ok] %SCRIPT_DIR%start-kkos-only.bat created

echo [WRITE] Creating start-odysseus-only.bat launcher...
(
    echo @echo off
    echo if exist "%VENV_PYTHON%" (
    echo     "%VENV_PYTHON%" -m uvicorn app:app --host 127.0.0.1 --port 7000 --app-dir "%ODYSSEUS_DIR%"
    echo ) else (
    echo     echo [ERROR] Odysseus setup incomplete.
    echo     pause
    echo )
) > "%SCRIPT_DIR%start-odysseus-only.bat"
echo [ok] %SCRIPT_DIR%start-odysseus-only.bat created

echo.

REM ─────────────────────────────────────────────────────────────────────────────
REM PHASE 4 — SUMMARY & NEXT STEPS
REM ─────────────────────────────────────────────────────────────────────────────

:phase4
echo [PHASE 4/4] Build Summary
echo.
echo ================================================================
if exist "%BIN_DIR%\%GAME_NAME%.exe" (
    echo [ok] KKOS Engine: %BIN_DIR%\%GAME_NAME%.exe
    for /f %%a in ('dir /b "%BIN_DIR%\%GAME_NAME%.exe"') do (
        for /f %%b in ('powershell -Command "(Get-Item \"%BIN_DIR%\%GAME_NAME%.exe\").Length / 1MB"') do echo        Size: %%bMB
    )
) else (
    echo [FAIL] KKOS Engine build failed
)

if exist "%VENV_PYTHON%" (
    echo [ok] Odysseus Environment: %VENV_DIR%
    echo        - FastAPI server ready
    echo        - Port: 7000
    echo        - URL: http://127.0.0.1:7000
) else (
    echo [WARN] Odysseus environment incomplete
)

echo [ok] Launcher Scripts:
echo        - start-all.bat (KKOS + Odysseus)
echo        - start-kkos-only.bat (KKOS only)
echo        - start-odysseus-only.bat (Odysseus only)

echo ================================================================
echo.
echo Next Steps:
echo.
if exist "%BIN_DIR%\%GAME_NAME%.exe" (
    echo 1. Run: start-all.bat
    echo 2. Wait for Odysseus to output "Application startup complete"
    echo 3. Open browser to http://127.0.0.1:7000
    echo 4. KKOS will open in separate window
) else (
    echo 1. Check logs\build.log for compilation errors
    echo 2. Fix source code issues
    echo 3. Re-run this script
)

echo.
echo Build logs: %SCRIPT_DIR%logs\build.log
echo Setup logs: %SCRIPT_DIR%logs\setup.log
echo.
echo [KKOS] Complete.
echo.

endlocal
exit /b 0
