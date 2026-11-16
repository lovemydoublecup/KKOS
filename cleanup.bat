@echo off
:: KKOS Environment Canonicalization v5.2.0
set SCRIPT_DIR=%~dp0

echo [CLEANUP] Finalizing v5.2.0 Environment...

:: 1. Archive Legacy Source Files
echo [FILES] Archiving legacy source modules...
set LEGACY_ARCHIVE=%SCRIPT_DIR%archive\legacy
set LEGACY_SRC=%LEGACY_ARCHIVE%\src
set LEGACY_BIN=%LEGACY_ARCHIVE%\bin
if not exist "%LEGACY_SRC%" mkdir "%LEGACY_SRC%"
if not exist "%LEGACY_BIN%" mkdir "%LEGACY_BIN%"
if exist "%SCRIPT_DIR%src\kkos_v2_unified.cpp" move /y "%SCRIPT_DIR%src\kkos_v2_unified.cpp" "%LEGACY_SRC%\" >nul
if exist "%SCRIPT_DIR%src\kkos_v43_sharded.cpp" move /y "%SCRIPT_DIR%src\kkos_v43_sharded.cpp" "%LEGACY_SRC%\" >nul
if exist "%SCRIPT_DIR%src\kkos_v2_21_monolith.cpp" move /y "%SCRIPT_DIR%src\kkos_v2_21_monolith.cpp" "%LEGACY_SRC%\" >nul
if exist "%SCRIPT_DIR%src\kkos_v2_unified_replacement.cpp" move /y "%SCRIPT_DIR%src\kkos_v2_unified_replacement.cpp" "%LEGACY_SRC%\" >nul
if exist "%SCRIPT_DIR%src\kkos_v39_production.cpp" move /y "%SCRIPT_DIR%src\kkos_v39_production.cpp" "%LEGACY_SRC%\" >nul

echo [FILES] Archiving legacy executables...
if exist "%SCRIPT_DIR%bin\kkos_v2.exe" move /y "%SCRIPT_DIR%bin\kkos_v2.exe" "%LEGACY_BIN%\" >nul
if exist "%SCRIPT_DIR%bin\kkos_v39.exe" move /y "%SCRIPT_DIR%bin\kkos_v39.exe" "%LEGACY_BIN%\" >nul
if exist "%SCRIPT_DIR%bin\kkos_v43.exe" move /y "%SCRIPT_DIR%bin\kkos_v43.exe" "%LEGACY_BIN%\" >nul
if exist "%SCRIPT_DIR%bin\kkos_v45.exe" move /y "%SCRIPT_DIR%bin\kkos_v45.exe" "%LEGACY_BIN%\" >nul

:: 3. Remove Temporary Build Artifacts
echo [FILES] Clearing temporary object files...
if exist "%SCRIPT_DIR%bin\*.o" del /q "%SCRIPT_DIR%bin\*.o"

echo [SUCCESS] Cleanup finished. Environment canonicalized for v5.2.0.
pause