@echo off
setlocal EnableDelayedExpansion
:: =============================================================================
:: KKOS v5.2.0 + Odysseus — UNIFIED MASTER BUILD SCRIPT
:: Kurfew Kult Operating System
::
:: Integrates: build-windows.bat, build-all-steps.bat, build-kkos-complete.bat,
::             build_windows.bat, build_and_run.ps1 + diagnostic logs
::
:: Usage:
::   BUILD.bat              — Full build (KKOS C++ + Odysseus Python)
::   BUILD.bat kkos         — KKOS engine only
::   BUILD.bat odysseus     — Odysseus Python setup only
::   BUILD.bat run          — Build then launch everything
::   BUILD.bat diag         — Compiler diagnostics (no build)
::   BUILD.bat vscode       — Write .vscode/ config files for debugging
::   BUILD.bat clean        — Archive legacy files, clear obj\
:: =============================================================================

:: ROOT CAUSE FIX: Always execute from the script's own directory.
:: Diagnostic logs (build.log, build_bash.log, build_cmd.log, build_ps.log)
:: were ALL empty and every exit code was 1 because the scripts were invoked
:: from a directory other than the project root. All relative paths —
:: src/kkos_v520_unified.cpp, Single-Exe-1.0.0/..., logs/ — failed silently
:: since stderr was not being captured. This line fixes it unconditionally.
cd /d "%~dp0"

set VERSION=5.2.0
set GAME_NAME=kkos_v520
set SCRIPT_DIR=%~dp0
set BIN_DIR=%SCRIPT_DIR%bin
set OBJ_DIR=%SCRIPT_DIR%obj
set LOG_DIR=%SCRIPT_DIR%logs
set ODYSSEUS_DIR=%SCRIPT_DIR%odysseus
set SRC_DIR=%SCRIPT_DIR%src
set RAYLIB_DIR=%SCRIPT_DIR%Single-Exe-1.0.0\raylib-5.5\src

:: ── Compiler resolution ────────────────────────────────────────────────────
:: Confirmed working: C:\msys64\mysys64_new\ucrt64\bin\g++.exe  rev13 / 15.2.0
:: (verified via gppver.txt / gpp_stdout.txt diagnostics)
set MSYS_BASE=C:\msys64\mysys64_new\ucrt64
set CC=%MSYS_BASE%\bin\g++.exe
set CC_C=%MSYS_BASE%\bin\gcc.exe
set PY_MSYS=%MSYS_BASE%\bin\python.exe
set XXD=%MSYS_BASE%\bin\xxd.exe

:: Fallback: canonical MSYS2 UCRT64 path
if not exist "%CC%" (
    if exist "C:\msys64\ucrt64\bin\g++.exe" (
        set CC=C:\msys64\ucrt64\bin\g++.exe
        set CC_C=C:\msys64\ucrt64\bin\gcc.exe
        set PY_MSYS=C:\msys64\ucrt64\bin\python.exe
        set XXD=C:\msys64\ucrt64\bin\xxd.exe
        set MSYS_BASE=C:\msys64\ucrt64
    )
)

:: Add MSYS2 UCRT64 bin to PATH so runtime DLLs resolve at launch
:: (libstdc++-6.dll, libgcc_s_seh-1.dll, libwinpthread-1.dll)
set PATH=%MSYS_BASE%\bin;%PATH%

:: ── Mode ───────────────────────────────────────────────────────────────────
set MODE=all
if /i "%~1"=="kkos"     set MODE=kkos
if /i "%~1"=="odysseus" set MODE=odysseus
if /i "%~1"=="run"      set MODE=run
if /i "%~1"=="diag"     set MODE=diag
if /i "%~1"=="vscode"   set MODE=vscode
if /i "%~1"=="clean"    set MODE=clean

:: ── Ensure dirs ────────────────────────────────────────────────────────────
if not exist "%BIN_DIR%"  mkdir "%BIN_DIR%"
if not exist "%OBJ_DIR%"  mkdir "%OBJ_DIR%"
if not exist "%LOG_DIR%"  mkdir "%LOG_DIR%"

echo.
echo ================================================================
echo  KKOS v%VERSION% ^| Kurfew Kult Operating System
echo  Mode: %MODE%   Node: %COMPUTERNAME%
echo ================================================================
echo.

if "%MODE%"=="clean"  goto :do_clean
if "%MODE%"=="diag"   goto :do_diag
if "%MODE%"=="vscode" goto :do_vscode

:: =============================================================================
:: PHASE 0 — ENVIRONMENT VALIDATION
:: =============================================================================
echo [PHASE 0] Environment Validation
echo.

:: ── Verify compiler ────────────────────────────────────────────────────────
set COMPILER_OK=0
set USE_MSVC=0

if exist "%CC%" (
    set COMPILER_OK=1
    echo [ok] Compiler : %CC%
    "%CC%" --version > "%LOG_DIR%\gppver.txt" 2>&1
    for /f "tokens=1,2,*" %%a in ('type "%LOG_DIR%\gppver.txt" ^| findstr /i "g++"') do (
        echo [ok] Version  : %%a %%b %%c
    )
) else (
    where g++ >nul 2>nul
    if not errorlevel 1 (
        set CC=g++
        set CC_C=gcc
        set COMPILER_OK=1
        echo [ok] System g++ on PATH
    ) else (
        where cl >nul 2>nul
        if not errorlevel 1 (
            set USE_MSVC=1
            set COMPILER_OK=1
            echo [ok] MSVC cl.exe found
        )
    )
)

if "%COMPILER_OK%"=="0" (
    echo [ERROR] No C++ compiler found.
    echo.
    echo   Install MSYS2 UCRT64:
    echo     1. Download from https://www.msys2.org/
    echo     2. Open MSYS2 UCRT64 terminal
    echo     3. Run: pacman -S mingw-w64-ucrt-x86_64-gcc
    echo     4. Add C:\msys64\ucrt64\bin to Windows PATH
    echo.
    echo   Or install Visual Studio Build Tools from:
    echo     https://visualstudio.microsoft.com/visual-cpp-build-tools/
    echo.
    if "%MODE%"=="kkos" ( pause & exit /b 1 )
    echo [WARN] Skipping KKOS C++ build — continuing to Odysseus...
    set SKIP_KKOS=1
)

:: ── Legacy source rename ───────────────────────────────────────────────────
if exist "%SRC_DIR%\kkos_v2_unified.cpp" (
    if not exist "%SRC_DIR%\kkos_v520_unified.cpp" (
        echo [RELABEL] kkos_v2_unified.cpp -> kkos_v520_unified.cpp
        ren "%SRC_DIR%\kkos_v2_unified.cpp" "kkos_v520_unified.cpp"
    )
)

:: ── RAM check — LTO needs headroom ────────────────────────────────────────
set FREE_RAM=0
for /f "tokens=2 delims==" %%a in ('wmic os get freephysicalmemory /value 2^>nul') do (
    set /a FREE_RAM=%%a / 1024 2>nul
)
if %FREE_RAM% GTR 0 (
    echo [SYSTEM] Free RAM: %FREE_RAM%MB
    if %FREE_RAM% LSS 800 (
        echo [WARN]   Low RAM — disabling LTO ^(-flto^), using -O2
        set FLAGS=-std=c++17 -O2 -ffast-math -march=native -Wall
    ) else (
        set FLAGS=-std=c++17 -O3 -flto -ffast-math -march=native -mtune=native -fno-plt -Wall -Wno-missing-braces
    )
) else (
    set FLAGS=-std=c++17 -O3 -ffast-math -march=native -Wall
)

echo.
if "%MODE%"=="odysseus" goto :do_odysseus
if defined SKIP_KKOS    goto :do_odysseus

:: =============================================================================
:: PHASE 1 — KKOS C++ BUILD
:: =============================================================================
:do_kkos
echo [PHASE 1] KKOS C++ Build
echo.

if not exist "%SRC_DIR%\kkos_v520_unified.cpp" (
    echo [ERROR] Source not found: %SRC_DIR%\kkos_v520_unified.cpp
    echo         Check that src\ contains kkos_v520_unified.cpp
    pause & exit /b 1
)

:: ── Include / define / lib flags ──────────────────────────────────────────
set INCLUDES=-I"%SCRIPT_DIR%." -I"%BIN_DIR%"
if exist "%RAYLIB_DIR%" (
    set INCLUDES=%INCLUDES% -I"%RAYLIB_DIR%" -I"%RAYLIB_DIR%\external\glfw\include"
) else (
    echo [WARN]   raylib not found at %RAYLIB_DIR%
    echo          Single-TU build without raylib headers
)

set DEFINES=-DUNICODE -D_UNICODE -DNOGDI -DNOUSER ^
    -DPLATFORM_DESKTOP ^
    -DKKOS_VERSION_STR=\"%VERSION%\" ^
    -DKKOS_VERSION_MAJOR=5 -DKKOS_VERSION_MINOR=2 ^
    -DKKOS_ODYSSEUS_URL=\"http://127.0.0.1:7000\"

set LIBS=-lopengl32 -lgdi32 -lwinmm -lpthread

set OBJ_FILES=

:: ── Probe: can the compiler reach the source? ─────────────────────────────
echo [PROBE]  Testing compiler on source (stderr -> build.log)...
"%CC%" -fsyntax-only %INCLUDES% %DEFINES% "%SRC_DIR%\kkos_v520_unified.cpp" ^
    >> "%LOG_DIR%\build.log" 2>&1
if errorlevel 1 (
    echo [WARN]   Syntax probe failed — see %LOG_DIR%\build.log for errors.
    echo          Attempting full compile anyway...
) else (
    echo [ok]     Syntax probe passed.
)
echo.

:: ── Compile raylib C sources ───────────────────────────────────────────────
if exist "%RAYLIB_DIR%" (
    echo [BUILD]  Compiling raylib C sources...
    for %%F in ("%RAYLIB_DIR%\*.c") do (
        echo [BUILD]    %%~nxF
        "%CC_C%" -std=c11 -O3 -march=native -mtune=native -DPLATFORM_DESKTOP %INCLUDES% ^
            -c "%%~fF" -o "%OBJ_DIR%\%%~nF.o" >> "%LOG_DIR%\build.log" 2>&1
        if errorlevel 1 (
            echo [ERROR]  Raylib compile failed: %%~nxF
            echo          Full error in %LOG_DIR%\build.log
            exit /b 1
        )
        set OBJ_FILES=!OBJ_FILES! "%OBJ_DIR%\%%~nF.o"
    )
    echo [ok]     raylib sources compiled.
    echo.
)

:: ── Compile KKOS C++ source ────────────────────────────────────────────────
echo [BUILD]  Compiling kkos_v520_unified.cpp...
"%CC%" %FLAGS% %INCLUDES% %DEFINES% ^
    -c "%SRC_DIR%\kkos_v520_unified.cpp" ^
    -o "%OBJ_DIR%\kkos_v520_unified.o" >> "%LOG_DIR%\build.log" 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR]  Compilation failed.
    echo.
    echo   ── Last errors from build.log ──────────────────────────────────
    powershell -NoProfile -Command "Get-Content '%LOG_DIR%\build.log' | Select-Object -Last 30"
    echo   ────────────────────────────────────────────────────────────────
    echo.
    echo   Full log: %LOG_DIR%\build.log
    echo   Run:  BUILD.bat diag   for compiler environment details.
    pause & exit /b 1
)
echo [ok]     kkos_v520_unified.o compiled.
set OBJ_FILES=!OBJ_FILES! "%OBJ_DIR%\kkos_v520_unified.o"

:: ── Link ───────────────────────────────────────────────────────────────────
echo [BUILD]  Linking %GAME_NAME%.exe...
"%CC%" %FLAGS% %INCLUDES% %DEFINES% !OBJ_FILES! ^
    -o "%BIN_DIR%\%GAME_NAME%.exe" %LIBS% >> "%LOG_DIR%\build.log" 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR]  Link failed.
    powershell -NoProfile -Command "Get-Content '%LOG_DIR%\build.log' | Select-Object -Last 20"
    echo   Full log: %LOG_DIR%\build.log
    pause & exit /b 1
)

echo [ok]     %BIN_DIR%\%GAME_NAME%.exe
echo.

:: ── Optional: embed codex resource header ─────────────────────────────────
if exist "%XXD%" (
    echo [CODEX]  Building KURFEW_KULT_CODEX.md...
    (
        echo # KURFEW KULT CODEX — KKOS v%VERSION%
        echo Compiled: %date% %time%
        echo.
    ) > "%BIN_DIR%\KURFEW_KULT_CODEX.md"
    for %%f in ("%SCRIPT_DIR%*.md") do (
        if not "%%~nxf"=="KURFEW_KULT_CODEX.md" (
            type "%%f" >> "%BIN_DIR%\KURFEW_KULT_CODEX.md"
            echo. >> "%BIN_DIR%\KURFEW_KULT_CODEX.md"
            echo --- >> "%BIN_DIR%\KURFEW_KULT_CODEX.md"
            echo. >> "%BIN_DIR%\KURFEW_KULT_CODEX.md"
        )
    )
    if exist "%SCRIPT_DIR%docs" (
        for %%f in ("%SCRIPT_DIR%docs\*.md") do (
            type "%%f" >> "%BIN_DIR%\KURFEW_KULT_CODEX.md"
            echo. >> "%BIN_DIR%\KURFEW_KULT_CODEX.md"
            echo --- >> "%BIN_DIR%\KURFEW_KULT_CODEX.md"
            echo. >> "%BIN_DIR%\KURFEW_KULT_CODEX.md"
        )
    )
    pushd "%BIN_DIR%"
    "%XXD%" -i KURFEW_KULT_CODEX.md > codex_resource.h 2>nul
    popd
    echo [ok]     codex_resource.h embedded
    echo.
)

if "%MODE%"=="kkos" goto :write_launchers
if "%MODE%"=="run"  goto :do_odysseus

:: =============================================================================
:: PHASE 2 — ODYSSEUS PYTHON SETUP
:: =============================================================================
:do_odysseus
echo [PHASE 2] Odysseus AI Workspace Setup
echo.

if not exist "%ODYSSEUS_DIR%" (
    echo [WARN]   odysseus\ not found — skipping Python setup
    goto :write_launchers
)

:: ── Find Python 3.11+ ─────────────────────────────────────────────────────
set VENV_PY=
set PYEXE=
for %%v in (3.13 3.12 3.11) do (
    if not defined PYEXE (
        py -%%v -c "import sys" >nul 2>&1
        if not errorlevel 1 ( set PYEXE=py & set PYVER=-%%v )
    )
)
if not defined PYEXE (
    python -c "import sys; exit(0 if sys.version_info[:2]>=(3,11) else 1)" >nul 2>&1
    if not errorlevel 1 ( set PYEXE=python & set PYVER= )
)
if not defined PYEXE (
    if exist "%PY_MSYS%" ( set PYEXE="%PY_MSYS%" & set PYVER= )
)
if not defined PYEXE (
    echo [ERROR]  Python 3.11+ not found.
    echo          Install from https://www.python.org/downloads/
    goto :write_launchers
)
echo [ok]     Python: %PYEXE% %PYVER%

:: ── Virtual environment ───────────────────────────────────────────────────
set VENV_DIR=%ODYSSEUS_DIR%\venv
set VENV_PY=%VENV_DIR%\Scripts\python.exe
if not exist "%VENV_PY%" set VENV_PY_ALT=%VENV_DIR%\bin\python.exe

if not exist "%VENV_DIR%\Scripts\python.exe" (
    if not exist "%VENV_DIR%\bin\python.exe" (
        echo [1/4]    Creating virtual environment...
        %PYEXE% %PYVER% -m venv "%VENV_DIR%"
        if errorlevel 1 ( echo [ERROR] venv creation failed & goto :write_launchers )
    )
)
if exist "%VENV_DIR%\Scripts\python.exe" ( set VENV_PY=%VENV_DIR%\Scripts\python.exe )
if exist "%VENV_DIR%\bin\python.exe"     ( set VENV_PY=%VENV_DIR%\bin\python.exe )
echo [ok]     venv: %VENV_PY%

echo [2/4]    Installing core dependencies (requirements.txt)...
"%VENV_PY%" -m pip install --upgrade pip --quiet
"%VENV_PY%" -m pip install -r "%ODYSSEUS_DIR%\requirements.txt" >> "%LOG_DIR%\setup.log" 2>&1
if errorlevel 1 ( echo [WARN]   Some packages failed — check %LOG_DIR%\setup.log )

:: Remove conflicting chromadb-client if present
"%VENV_PY%" -m pip show chromadb-client >nul 2>&1
if not errorlevel 1 (
    echo [2/4]    Removing conflicting chromadb-client...
    "%VENV_PY%" -m pip uninstall -y chromadb-client >> "%LOG_DIR%\setup.log" 2>&1
    "%VENV_PY%" -m pip install --force-reinstall chromadb >> "%LOG_DIR%\setup.log" 2>&1
)

echo [3/4]    Running first-time setup...
set ODYSSEUS_SKIP_RUN_HINT=1
"%VENV_PY%" "%ODYSSEUS_DIR%\setup.py" >> "%LOG_DIR%\setup.log" 2>&1
if errorlevel 1 ( echo [WARN]   setup.py returned error — check above )

echo [4/4]    Verifying core imports...
"%VENV_PY%" -c "import fastapi, chromadb; print('[ok]     fastapi + chromadb loaded')" 2>nul ^
    || echo [WARN]   Import check failed — check %LOG_DIR%\setup.log

echo.

:: =============================================================================
:: PHASE 3 — WRITE LAUNCHER SCRIPTS
:: =============================================================================
:write_launchers
echo [PHASE 3] Writing Launcher Scripts
echo.

:: ── start-all.bat ─────────────────────────────────────────────────────────
(
    echo @echo off
    echo setlocal
    echo set MSYS_BASE=%MSYS_BASE%
    echo set PATH=%%MSYS_BASE%%\bin;%%PATH%%
    echo set PROJECT_DIR=%%~dp0
    echo set KKOS_EXE=%%PROJECT_DIR%%bin\%GAME_NAME%.exe
    echo set ODY_PY=%%PROJECT_DIR%%odysseus\venv\Scripts\python.exe
    echo set ODY_PY_FALLBACK=%%PROJECT_DIR%%odysseus\venv\bin\python.exe
    echo set ODY_DIR=%%PROJECT_DIR%%odysseus
    echo.
    echo if not exist "%%KKOS_EXE%%" ^(
    echo     echo [ERROR] KKOS executable not found. Run BUILD.bat first.
    echo     pause ^& exit /b 1
    echo ^)
    echo if not exist "%%ODY_PY%%" ^(
    echo     if exist "%%ODY_PY_FALLBACK%%" ^( set ODY_PY=%%ODY_PY_FALLBACK%% ^) else ^(
    echo         echo [ERROR] Odysseus not set up. Run BUILD.bat first.
    echo         pause ^& exit /b 1
    echo     ^)
    echo ^)
    echo echo.
    echo echo ================================================
    echo echo  KKOS v%VERSION% + Odysseus
    echo echo  Odysseus: http://127.0.0.1:7000
    echo echo ================================================
    echo echo.
    echo start "KKOS v%VERSION%" "%%KKOS_EXE%%"
    echo "%%ODY_PY%%" -m uvicorn app:app --host 127.0.0.1 --port 7000 --app-dir "%%ODY_DIR%%"
    echo endlocal
) > "%SCRIPT_DIR%start-all.bat"
echo [ok]     start-all.bat

:: ── start-kkos-only.bat ───────────────────────────────────────────────────
(
    echo @echo off
    echo setlocal
    echo set MSYS_BASE=%MSYS_BASE%
    echo set PATH=%%MSYS_BASE%%\bin;%%PATH%%
    echo set KKOS_EXE=%%~dp0bin\%GAME_NAME%.exe
    echo if not exist "%%KKOS_EXE%%" ^( echo [ERROR] Build first with BUILD.bat ^& pause ^& exit /b 1 ^)
    echo "%%KKOS_EXE%%"
    echo endlocal
) > "%SCRIPT_DIR%start-kkos-only.bat"
echo [ok]     start-kkos-only.bat

:: ── start-odysseus-only.bat ───────────────────────────────────────────────
(
    echo @echo off
    echo setlocal
    echo set ODY_PY=%%~dp0odysseus\venv\Scripts\python.exe
    echo set ODY_PY_FALLBACK=%%~dp0odysseus\venv\bin\python.exe
    echo set ODY_DIR=%%~dp0odysseus
    echo if not exist "%%ODY_PY%%" ^(
    echo     if exist "%%ODY_PY_FALLBACK%%" ^( set ODY_PY=%%ODY_PY_FALLBACK%% ^) else ^(
    echo         echo [ERROR] Run BUILD.bat first. ^& pause ^& exit /b 1
    echo     ^)
    echo ^)
    echo "%%ODY_PY%%" -m uvicorn app:app --host 127.0.0.1 --port 7000 --app-dir "%%ODY_DIR%%"
    echo endlocal
) > "%SCRIPT_DIR%start-odysseus-only.bat"
echo [ok]     start-odysseus-only.bat

echo.
goto :summary

:: =============================================================================
:: DIAG MODE — compiler + environment report
:: =============================================================================
:do_diag
echo [DIAG] Compiler Environment Report
echo        (reproduces: gppver.txt, gppv_stderr.txt, gppv_compile_stderr.txt)
echo.

if exist "%CC%" (
    echo [ok] g++ found: %CC%
    echo.
    echo ── g++ --version ───────────────────────────────────────────────────
    "%CC%" --version
    echo.
    echo ── g++ -v ^(full config^) ─────────────────────────────────────────
    "%CC%" -v 2>&1
    echo.
) else (
    echo [FAIL] g++ NOT found at: %CC%
    echo        Install MSYS2 UCRT64 and run: pacman -S mingw-w64-ucrt-x86_64-gcc
)

if exist "%CC_C%" (
    echo [ok] gcc found: %CC_C%
) else (
    echo [FAIL] gcc NOT found at: %CC_C%
)

echo.
echo ── PATH (MSYS2 fragment) ────────────────────────────────────────────
echo %PATH% | tr ; \n 2>nul || echo %PATH%

echo.
echo ── Header include probe (gpp_h test) ───────────────────────────────
echo    Testing that compiler can resolve a C++ standard header...
echo    (reproduces: gpp_h_exit.txt / gpp_h_stderr.txt diagnostics)
echo    #include ^<iostream^> > "%TEMP%\kkos_header_test.cpp"
"%CC%" -std=c++17 -fsyntax-only "%TEMP%\kkos_header_test.cpp" 2>&1
if errorlevel 1 (
    echo [FAIL] Basic header test failed — compiler installation may be broken.
    echo        Try reinstalling: pacman -S mingw-w64-ucrt-x86_64-gcc
) else (
    echo [ok]   Standard headers accessible.
)
del "%TEMP%\kkos_header_test.cpp" 2>nul

echo.
echo ── Source probe ─────────────────────────────────────────────────────
if exist "%SRC_DIR%\kkos_v520_unified.cpp" (
    echo [ok] src\kkos_v520_unified.cpp exists
    echo      Running -fsyntax-only compile probe...
    "%CC%" -fsyntax-only -std=c++17 %INCLUDES% %DEFINES% ^
        "%SRC_DIR%\kkos_v520_unified.cpp" 2>&1
    echo Exit code: %ERRORLEVEL%
) else (
    echo [FAIL] src\kkos_v520_unified.cpp NOT found
)

echo.
echo ── raylib headers ───────────────────────────────────────────────────
if exist "%RAYLIB_DIR%\raylib.h" (
    echo [ok] raylib.h found at %RAYLIB_DIR%
) else (
    echo [FAIL] raylib.h NOT found at %RAYLIB_DIR%
    echo        Expected: Single-Exe-1.0.0\raylib-5.5\src\raylib.h
)

echo.
echo ── Runtime DLLs in MSYS_BASE ───────────────────────────────────────
for %%D in (libstdc++-6.dll libgcc_s_seh-1.dll libwinpthread-1.dll) do (
    if exist "%MSYS_BASE%\bin\%%D" (
        echo [ok] %%D
    ) else (
        echo [!!] %%D NOT found — add %MSYS_BASE%\bin to PATH or copy to bin\
    )
)

echo.
echo [DIAG] Complete. If errors above exist, fix them before running BUILD.bat
pause
exit /b 0

:: =============================================================================
:: VSCODE MODE — write .vscode/ configuration files
:: =============================================================================
:do_vscode
echo [VSCODE] Writing VS Code configuration for KKOS UCRT64 debugging
echo          ^(integrates KOS v4.5 MSYS2 UCRT64 VS Code Setup Guide^)
echo.

if not exist "%SCRIPT_DIR%.vscode" mkdir "%SCRIPT_DIR%.vscode"

:: Resolve GDB path
set GDB_PATH=%MSYS_BASE%\bin\gdb.exe
if not exist "%GDB_PATH%" set GDB_PATH=C:\msys64\ucrt64\bin\gdb.exe

:: ── .vscode\launch.json ───────────────────────────────────────────────────
(
    echo {
    echo     "version": "0.2.0",
    echo     "configurations": [
    echo         {
    echo             "name": "KKOS v%VERSION% ^(UCRT64 GDB^)",
    echo             "type": "cppdbg",
    echo             "request": "launch",
    echo             "program": "${workspaceFolder}/bin/%GAME_NAME%.exe",
    echo             "args": [],
    echo             "cwd": "${workspaceFolder}",
    echo             "stopAtEntry": false,
    echo             "externalConsole": true,
    echo             "MIMode": "gdb",
    echo             "miDebuggerPath": "%GDB_PATH:\=/%",
    echo             "preLaunchTask": "Build KKOS ^(UCRT64^)"
    echo         }
    echo     ]
    echo }
) > "%SCRIPT_DIR%.vscode\launch.json"
echo [ok]     .vscode\launch.json

:: ── .vscode\tasks.json ────────────────────────────────────────────────────
set CC_FORWARD=%CC:\=/%
(
    echo {
    echo     "version": "2.0.0",
    echo     "tasks": [
    echo         {
    echo             "label": "Build KKOS ^(UCRT64^)",
    echo             "type": "shell",
    echo             "command": "%CC_FORWARD%",
    echo             "args": [
    echo                 "-std=c++17",
    echo                 "-g",
    echo                 "-O0",
    echo                 "-DKKOS_VERSION_STR=\\\"5.2.0\\\"",
    echo                 "-DKKOS_VERSION_MAJOR=5",
    echo                 "-DKKOS_VERSION_MINOR=2",
    echo                 "-DKKOS_ODYSSEUS_URL=\\\"http://127.0.0.1:7000\\\"",
    echo                 "${workspaceFolder}/src/kkos_v520_unified.cpp",
    echo                 "-o",
    echo                 "${workspaceFolder}/bin/%GAME_NAME%.exe",
    echo                 "-lopengl32",
    echo                 "-lgdi32",
    echo                 "-lwinmm",
    echo                 "-lpthread"
    echo             ],
    echo             "options": {
    echo                 "cwd": "${workspaceFolder}"
    echo             },
    echo             "group": {
    echo                 "kind": "build",
    echo                 "isDefault": true
    echo             },
    echo             "problemMatcher": ["$gcc"]
    echo         }
    echo     ]
    echo }
) > "%SCRIPT_DIR%.vscode\tasks.json"
echo [ok]     .vscode\tasks.json

:: ── .vscode\c_cpp_properties.json ────────────────────────────────────────
set CC_FORWARD_PROP=%CC:\=/%
(
    echo {
    echo     "version": 4,
    echo     "configurations": [
    echo         {
    echo             "name": "UCRT64",
    echo             "includePath": [
    echo                 "${workspaceFolder}/**",
    echo                 "${workspaceFolder}/Single-Exe-1.0.0/raylib-5.5/src"
    echo             ],
    echo             "defines": [
    echo                 "UNICODE",
    echo                 "_UNICODE",
    echo                 "KKOS_VERSION_MAJOR=5",
    echo                 "KKOS_VERSION_MINOR=2"
    echo             ],
    echo             "compilerPath": "%CC_FORWARD_PROP%",
    echo             "cStandard": "c11",
    echo             "cppStandard": "c++17",
    echo             "intelliSenseMode": "windows-gcc-x64"
    echo         }
    echo     ]
    echo }
) > "%SCRIPT_DIR%.vscode\c_cpp_properties.json"
echo [ok]     .vscode\c_cpp_properties.json

echo.
echo [VSCODE] Configuration written. Open folder in VS Code:
echo          - Ctrl+Shift+B   to build
echo          - F5             to debug with GDB
echo          - Ctrl+Shift+D   to open Run and Debug panel
echo.
echo          If GDB not installed: run install-gdb.bat
echo          GDB expected at: %GDB_PATH%
echo.
pause
exit /b 0

:: =============================================================================
:: CLEAN MODE
:: =============================================================================
:do_clean
echo [CLEAN]  Archiving legacy files and clearing build artifacts...
echo.

set LEGACY_DIR=%SCRIPT_DIR%archive\legacy
set LEGACY_SRC=%LEGACY_DIR%\src
set LEGACY_BIN=%LEGACY_DIR%\bin
set LEGACY_SCRIPTS=%LEGACY_DIR%\scripts
set LEGACY_VSCODE=%LEGACY_DIR%\vscode_stray

if not exist "%LEGACY_SRC%" mkdir "%LEGACY_SRC%"
if not exist "%LEGACY_BIN%" mkdir "%LEGACY_BIN%"
if not exist "%LEGACY_SCRIPTS%" mkdir "%LEGACY_SCRIPTS%"
if not exist "%LEGACY_VSCODE%" mkdir "%LEGACY_VSCODE%"

for %%F in (
    kkos_v2_unified.cpp kkos_v43_sharded.cpp
    kkos_v2_21_monolith.cpp kkos_v2_unified_replacement.cpp
    kkos_v39_production.cpp
) do (
    if exist "%SRC_DIR%\%%F" (
        move /y "%SRC_DIR%\%%F" "%LEGACY_SRC%\" >nul
        echo [ARCHIVE] src\%%F
    )
)
for %%F in (kkos_v2.exe kkos_v39.exe kkos_v43.exe kkos_v45.exe) do (
    if exist "%BIN_DIR%\%%F" (
        move /y "%BIN_DIR%\%%F" "%LEGACY_BIN%\" >nul
        echo [ARCHIVE] bin\%%F
    )
)
for %%F in (
    build-windows.bat
    build-all-steps.bat
    build-kkos-complete.bat
    build_windows.bat
    launch-windows.ps1
    build_and_run.ps1
    update_windows.bat
    install_gdb.bat
    install_gdb_proper.bat
    cleanup.bat
    KKOS.bat
    KKOS_Installer.bat
    build-all.sh
    build_linux.sh
    build-macos-app.sh
    start-macos.sh
    start-all.sh
    deploy.sh
    install-gdb.sh
    install_gdb.sh
    install_aosp_deps.sh
    build_aosp.sh
) do (
    if exist "%SCRIPT_DIR%%%F" (
        move /y "%SCRIPT_DIR%%%F" "%LEGACY_SCRIPTS%\" >nul
        echo [ARCHIVE] %%F
    )
)
for %%F in (
    c_cpp_properties.json
    launch.json
    settings.json
    tasks.json
) do (
    if exist "%SCRIPT_DIR%%%F" (
        move /y "%SCRIPT_DIR%%%F" "%LEGACY_VSCODE%\" >nul
        echo [ARCHIVE] stray file %%F
    )
)
if exist "%OBJ_DIR%" (
    rd /s /q "%OBJ_DIR%" 2>nul
    echo [CLEAN]   obj\ cleared
)
echo.
echo [ok]     Clean complete. Legacy files -> archive\legacy\
pause
exit /b 0

:: =============================================================================
:: SUMMARY
:: =============================================================================
:summary
echo.
echo ================================================================
echo  BUILD SUMMARY — KKOS v%VERSION%
echo ================================================================

if exist "%BIN_DIR%\%GAME_NAME%.exe" (
    echo [ok] KKOS Engine  : %BIN_DIR%\%GAME_NAME%.exe
) else (
    echo [--] KKOS Engine  : not built
    echo      See: %LOG_DIR%\build.log
    echo      Run: BUILD.bat diag   for environment details
)

if exist "%ODYSSEUS_DIR%\venv\Scripts\python.exe" (
    echo [ok] Odysseus     : http://127.0.0.1:7000
) else if exist "%ODYSSEUS_DIR%\venv\bin\python.exe" (
    echo [ok] Odysseus     : http://127.0.0.1:7000
) else (
    echo [--] Odysseus     : not set up
)

echo.
echo  Launchers:
echo    start-all.bat              KKOS + Odysseus
echo    start-kkos-only.bat        KKOS engine only
echo    start-odysseus-only.bat    Odysseus server only
echo.
echo  Tools:
echo    BUILD.bat diag             Compiler + environment report
echo    BUILD.bat vscode           Write .vscode\ debug config
echo    install-gdb.bat            Install GDB debugger
echo    CLEAN.bat                  Archive legacy, clear obj\
echo.
echo  Logs: %LOG_DIR%\build.log  /  setup.log
echo ================================================================
echo.

if "%MODE%"=="run" (
    if exist "%BIN_DIR%\%GAME_NAME%.exe" (
        echo [LAUNCH] Starting KKOS + Odysseus...
        call "%SCRIPT_DIR%start-all.bat"
    ) else (
        echo [ERROR]  Cannot launch — KKOS build failed. Fix errors then retry.
        pause
    )
)

endlocal
