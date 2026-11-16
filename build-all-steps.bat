@echo off
REM =============================================================================
REM KKOS v5.2 + Odysseus Unified Bundle — MASTER BUILD SCRIPT
REM Compiles KKOS C++ engine and sets up Odysseus Python AI workspace
REM =============================================================================

setlocal EnableDelayedExpansion

set VERSION=5.2.0
set GAME_NAME=kkos_v520
set MSYS_BASE=C:\msys64\mysys64_new\ucrt64
set CC=%MSYS_BASE%\bin\g++.exe
set PYTHON=%MSYS_BASE%\bin\python.exe
set PATH=%MSYS_BASE%\bin;%PATH%

set SCRIPT_DIR=%~dp0
set ODYSSEUS_DIR=%SCRIPT_DIR%odysseus
set BIN_DIR=%SCRIPT_DIR%bin
set LOG_DIR=%SCRIPT_DIR%logs

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo.
echo ================================================================
echo  KKOS v%VERSION% + Odysseus Unified Bundle — Setup Script
echo ================================================================
echo.

REM Validate environment
echo [VALIDATION] Checking prerequisites...
if not exist "%CC%" (
    echo [ERROR] g++ not found at: %CC%
    echo [ERROR] Install MSYS2 or adjust path in this script
    pause
    exit /b 1
)
if not exist "%PYTHON%" (
    echo [ERROR] Python not found at: %PYTHON%
    echo [ERROR] Install Python or adjust path in this script
    pause
    exit /b 1
)
echo [OK] g++ and Python found
echo.

REM Phase 1: C++ Build
echo [PHASE 1/3] KKOS C++ Compilation
echo [INFO] This may take 30-60 minutes...
echo.

set CC_C=%MSYS_BASE%\bin\gcc.exe
set OBJ_DIR=%SCRIPT_DIR%obj
if not exist "%OBJ_DIR%" mkdir "%OBJ_DIR%"

set INCLUDES=-I"%SCRIPT_DIR%." -I"%BIN_DIR%" -I"%SCRIPT_DIR%Single-Exe-1.0.0\raylib-5.5\src" -I"%SCRIPT_DIR%Single-Exe-1.0.0\raylib-5.5\src\external\glfw\include"
set DEFINES=-DUNICODE -D_UNICODE -DNOGDI -DNOUSER -DKKOS_VERSION_STR=\"%VERSION%\"
set LIBS=-lopengl32 -lgdi32 -lwinmm -lpthread
set OBJ_FILES=

echo [BUILD] Compiling raylib C sources with gcc...
for %%F in (%SCRIPT_DIR%Single-Exe-1.0.0\raylib-5.5\src\*.c) do (
    echo [BUILD]   %%~nxF
    "%CC_C%" -std=c11 -O3 -march=native -mtune=native -Wall %INCLUDES% -c "%%~fF" -o "%OBJ_DIR%\%%~nF.o" >>"%LOG_DIR%\build.log" 2>&1
    if errorlevel 1 (
        echo [ERROR] Failed to compile C source: %%~nxF
        echo [ERROR] See %LOG_DIR%\build.log
        exit /b 1
    )
    set OBJ_FILES=!OBJ_FILES! "%OBJ_DIR%\%%~nF.o"
)

echo [BUILD] Compiling KKOS C++ source with g++...
"%CC%" -std=c++17 -O3 -march=native -mtune=native -Wall %INCLUDES% %DEFINES% -c "%SCRIPT_DIR%src\kkos_v520_unified.cpp" -o "%OBJ_DIR%\kkos_v520_unified.o" >>"%LOG_DIR%\build.log" 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to compile C++ source: kkos_v520_unified.cpp
    echo [ERROR] See %LOG_DIR%\build.log
    exit /b 1
)
set OBJ_FILES=!OBJ_FILES! "%OBJ_DIR%\kkos_v520_unified.o"

echo [BUILD] Linking executable...
"%CC%" %INCLUDES% %DEFINES% %OBJ_FILES% -o "%BIN_DIR%\%GAME_NAME%.exe" %LIBS% >>"%LOG_DIR%\build.log" 2>&1
if errorlevel 1 (
    echo [ERROR] Linking failed
    echo [ERROR] See %LOG_DIR%\build.log
    exit /b 1
)

echo [OK] KKOS executable built: %BIN_DIR%\%GAME_NAME%.exe
echo.

REM Phase 2: Odysseus Setup
echo [PHASE 2/3] Odysseus Python Setup
echo.

set VENV_DIR=%ODYSSEUS_DIR%\venv
set VENV_PY=%VENV_DIR%\Scripts\python.exe
if not exist "%VENV_PY%" set VENV_PY=%VENV_DIR%\bin\python.exe

if not exist "%VENV_PY%" (
    echo [1/4] Creating virtual environment...
    "%PYTHON%" -m venv "%VENV_DIR%"
    if exist "%VENV_DIR%\Scripts\python.exe" (
        set VENV_PY=%VENV_DIR%\Scripts\python.exe
    ) else (
        set VENV_PY=%VENV_DIR%\bin\python.exe
    )
    echo [OK] venv created
) else (
    echo [OK] venv already exists
)

echo [2/4] Installing dependencies...
"%VENV_PY%" -m pip install --upgrade pip --quiet
"%VENV_PY%" -m pip install -r "%ODYSSEUS_DIR%\requirements.txt" >>"%LOG_DIR%\setup.log" 2>&1
echo [OK] Dependencies installed

echo [3/4] Running first-time setup...
set ODYSSEUS_SKIP_RUN_HINT=1
"%VENV_PY%" "%ODYSSEUS_DIR%\setup.py" >>"%LOG_DIR%\setup.log" 2>&1
echo [OK] Odysseus database initialized

echo [4/4] Creating launcher scripts...

echo @echo off > "%SCRIPT_DIR%start-all.bat"
echo echo Starting KKOS v%VERSION% + Odysseus... >> "%SCRIPT_DIR%start-all.bat"
echo echo Odysseus: http://127.0.0.1:7000 >> "%SCRIPT_DIR%start-all.bat"
echo start "KKOS v%VERSION%" "%BIN_DIR%\%GAME_NAME%.exe" >> "%SCRIPT_DIR%start-all.bat"
echo "%VENV_PY%" -m uvicorn app:app --host 127.0.0.1 --port 7000 --app-dir "%ODYSSEUS_DIR%" >> "%SCRIPT_DIR%start-all.bat"

echo @echo off > "%SCRIPT_DIR%start-kkos-only.bat"
echo "%BIN_DIR%\%GAME_NAME%.exe" >> "%SCRIPT_DIR%start-kkos-only.bat"

echo @echo off > "%SCRIPT_DIR%start-odysseus-only.bat"
echo "%VENV_PY%" -m uvicorn app:app --host 127.0.0.1 --port 7000 --app-dir "%ODYSSEUS_DIR%" >> "%SCRIPT_DIR%start-odysseus-only.bat"

echo [OK] Launcher scripts created
echo.

REM Phase 3: Summary
echo [PHASE 3/3] Summary
echo.
echo ================================================================
if exist "%BIN_DIR%\%GAME_NAME%.exe" (
    echo [OK] KKOS Engine: %BIN_DIR%\%GAME_NAME%.exe
) else (
    echo [WARN] KKOS build incomplete - check logs
)
if exist "%VENV_PY%" (
    echo [OK] Odysseus: Ready at http://127.0.0.1:7000
) else (
    echo [WARN] Odysseus setup incomplete
)
echo ================================================================
echo.
echo Next: Run start-all.bat to launch both applications
echo.
pause
