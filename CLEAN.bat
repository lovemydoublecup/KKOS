@echo off
:: KKOS v5.2.0 — Environment Cleanup / Canonicalization
:: Consolidates: cleanup.bat
:: Archives legacy source files and binaries, clears obj\ intermediates.

setlocal
set SCRIPT_DIR=%~dp0

echo.
echo ============================================
echo  KKOS v5.2.0 — Environment Cleanup
echo ============================================
echo.
echo This will:
echo   - Archive legacy source files to archive\legacy\src\
echo   - Archive legacy executables to archive\legacy\bin\
echo   - Delete all obj\ intermediate files
echo.
set /p CONFIRM=Proceed? [Y/N]: 
if /i not "%CONFIRM%"=="Y" ( echo Cancelled. & pause & exit /b 0 )

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

echo [ARCHIVE] Legacy source files...
for %%F in (
    kkos_v2_unified.cpp
    kkos_v43_sharded.cpp
    kkos_v2_21_monolith.cpp
    kkos_v2_unified_replacement.cpp
    kkos_v39_production.cpp
) do (
    if exist "%SCRIPT_DIR%src\%%F" (
        move /y "%SCRIPT_DIR%src\%%F" "%LEGACY_SRC%\" >nul
        echo   Archived: src\%%F
    )
)

echo [ARCHIVE] Legacy executables...
for %%F in (kkos_v2.exe kkos_v39.exe kkos_v43.exe kkos_v45.exe) do (
    if exist "%SCRIPT_DIR%bin\%%F" (
        move /y "%SCRIPT_DIR%bin\%%F" "%LEGACY_BIN%\" >nul
        echo   Archived: bin\%%F
    )
)

echo [ARCHIVE] Legacy scripts...
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
        echo   Archived script: %%F
    )
)

echo [ARCHIVE] Stray VS Code configurations...
for %%F in (
    c_cpp_properties.json
    launch.json
    settings.json
    tasks.json
) do (
    if exist "%SCRIPT_DIR%%%F" (
        move /y "%SCRIPT_DIR%%%F" "%LEGACY_VSCODE%\" >nul
        echo   Archived stray file: %%F
    )
)

echo [CLEAN]   Removing obj\ intermediates...
if exist "%SCRIPT_DIR%obj" (
    rd /s /q "%SCRIPT_DIR%obj"
    echo   Removed: obj\
) else (
    echo   obj\ already clean
)

echo.
echo [ok] Environment canonicalized for KKOS v5.2.0.
echo      Legacy files -> archive\legacy\
echo.
pause
endlocal
