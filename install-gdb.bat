@echo off
setlocal enabledelayedexpansion
:: =============================================================================
:: KKOS v5.2.0 — Install GDB Debugger via MSYS2 UCRT64
:: Consolidates: install_gdb.bat, install_gdb_proper.bat
:: =============================================================================

echo.
echo ============================================
echo  KKOS — GDB Debugger Installer (MSYS2)
echo ============================================
echo.

:: Prefer the canonical mysys64_new path first, fall back to ucrt64
set MSYS_BASE=C:\msys64\mysys64_new\ucrt64
set MSYS2_SHELL=C:\msys64\msys2_shell.cmd
set BASH=C:\msys64\usr\bin\bash.exe

if not exist "%MSYS2_SHELL%" (
    echo [ERROR] MSYS2 not found at C:\msys64
    echo         Install from https://www.msys2.org/
    pause
    exit /b 1
)

echo [INFO] Installing GDB via pacman (mingw-w64-ucrt-x86_64-gdb)...
echo [INFO] This may take a moment on first run.
echo.

:: Method 1 — msys2_shell.cmd (most reliable, handles PATH internally)
"%MSYS2_SHELL%" -ucrt64 -no-start -c "pacman -Sy --noconfirm && pacman -S --noconfirm mingw-w64-ucrt-x86_64-gdb"
if %errorlevel% neq 0 goto :method2

:: Verify
if exist "%MSYS_BASE%\bin\gdb.exe" goto :success
if exist "C:\msys64\ucrt64\bin\gdb.exe" goto :success_alt

:method2
echo [WARN]  Shell method failed — trying bash directly...
if not exist "%BASH%" (
    echo [ERROR] bash.exe not found. Is MSYS2 installed correctly?
    goto :fail
)
set MSYSTEM=UCRT64
pushd C:\msys64\usr\bin
"%BASH%" -l -c "pacman -Sy && pacman -S --noconfirm mingw-w64-ucrt-x86_64-gdb"
popd

if exist "%MSYS_BASE%\bin\gdb.exe" goto :success
if exist "C:\msys64\ucrt64\bin\gdb.exe" goto :success_alt
goto :fail

:success
echo.
echo [ok] GDB installed: %MSYS_BASE%\bin\gdb.exe
"%MSYS_BASE%\bin\gdb.exe" --version
goto :done

:success_alt
echo.
echo [ok] GDB installed: C:\msys64\ucrt64\bin\gdb.exe
"C:\msys64\ucrt64\bin\gdb.exe" --version
goto :done

:fail
echo.
echo [ERROR] GDB installation failed.
echo         Try manually inside MSYS2 UCRT64:
echo           pacman -S mingw-w64-ucrt-x86_64-gdb

:done
echo.
pause
endlocal
