@echo off
REM KKOS.bat - Launcher for KKOS v4.5 Unified Kernel
REM This script launches the latest stable version of KKOS

setlocal enabledelayedexpansion

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0
set BIN_DIR=%SCRIPT_DIR%bin
set KKOS_EXE=%BIN_DIR%\kkos_v45.exe

REM Check if the executable exists
if not exist "%KKOS_EXE%" (
    echo Error: KKOS executable not found at %KKOS_EXE%
    echo Please ensure the project has been built using:
    echo   build_windows.bat v45
    exit /b 1
)

REM Launch KKOS with any arguments passed to this script
"%KKOS_EXE%" %*
exit /b %errorlevel%
