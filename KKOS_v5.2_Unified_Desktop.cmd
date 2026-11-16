@echo off
setlocal
set SCRIPT_DIR=%~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%KKOS_v5.2_Unified_Desktop.ps1"
endlocal
