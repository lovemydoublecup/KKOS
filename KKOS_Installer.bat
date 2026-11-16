@echo off
REM KKOS_Installer.bat - Installation program for KKOS v4.5 Unified Kernel
REM This script installs KKOS to the system

setlocal enabledelayedexpansion

echo.
echo =====================================================
echo    KKOS v4.5 Unified Kernel Installation Program
echo =====================================================
echo.

REM Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Administrator privileges required!
    echo.
    echo Please run this installer as Administrator:
    echo   Right-click on KKOS_Installer.bat and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

REM Define installation paths
set INSTALL_DIR=C:\Program Files\KKOS
set SCRIPT_DIR=%~dp0
set BIN_DIR=%SCRIPT_DIR%bin
set KKOS_EXE=%BIN_DIR%\kkos_v45.exe

REM Check if KKOS executable exists
if not exist "%KKOS_EXE%" (
    echo Error: KKOS executable not found!
    echo.
    echo Please build the project first:
    echo   build_windows.bat v45
    echo.
    pause
    exit /b 1
)

REM Create installation directory
echo Creating installation directory: %INSTALL_DIR%
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
)

REM Copy executable
echo Copying KKOS executable...
copy "%KKOS_EXE%" "%INSTALL_DIR%\KKOS.exe" >nul
if %errorlevel% neq 0 (
    echo Error: Failed to copy KKOS executable
    pause
    exit /b 1
)

REM Copy documentation
if exist "%SCRIPT_DIR%docs" (
    echo Copying documentation...
    xcopy "%SCRIPT_DIR%docs" "%INSTALL_DIR%\docs" /E /I /Y >nul 2>&1
)

REM Copy README
if exist "%SCRIPT_DIR%README.txt" (
    copy "%SCRIPT_DIR%README.txt" "%INSTALL_DIR%\README.txt" >nul
)

REM Create shortcuts directory
set SHORTCUTS_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\KKOS
if not exist "%SHORTCUTS_DIR%" (
    mkdir "%SHORTCUTS_DIR%"
)

REM Create Start Menu shortcut using VBScript
set VBSCRIPT_FILE=%TEMP%\CreateShortcut.vbs
echo Creating Start Menu shortcut...
(
    echo Set oWS = WScript.CreateObject("WScript.Shell"^)
    echo sLinkFile = "%SHORTCUTS_DIR%\KKOS.lnk"
    echo Set oLink = oWS.CreateShortcut(sLinkFile^)
    echo oLink.TargetPath = "%INSTALL_DIR%\KKOS.exe"
    echo oLink.WorkingDirectory = "%INSTALL_DIR%"
    echo oLink.Description = "KKOS v4.5 Unified Kernel"
    echo oLink.Save
) > "%VBSCRIPT_FILE%"

cscript.exe "%VBSCRIPT_FILE%" >nul 2>&1
del "%VBSCRIPT_FILE%"

REM Create Desktop shortcut using VBScript
set VBSCRIPT_FILE=%TEMP%\CreateShortcut.vbs
echo Creating Desktop shortcut...
(
    echo Set oWS = WScript.CreateObject("WScript.Shell"^)
    echo sLinkFile = "%USERPROFILE%\Desktop\KKOS.lnk"
    echo Set oLink = oWS.CreateShortcut(sLinkFile^)
    echo oLink.TargetPath = "%INSTALL_DIR%\KKOS.exe"
    echo oLink.WorkingDirectory = "%INSTALL_DIR%"
    echo oLink.Description = "KKOS v4.5 Unified Kernel"
    echo oLink.Save
) > "%VBSCRIPT_FILE%"

cscript.exe "%VBSCRIPT_FILE%" >nul 2>&1
del "%VBSCRIPT_FILE%"

REM Create uninstaller
echo Creating uninstaller...
set UNINSTALLER=%INSTALL_DIR%\Uninstall.bat
(
    echo @echo off
    echo setlocal enabledelayedexpansion
    echo.
    echo echo.
    echo echo =====================================================
    echo echo    KKOS v4.5 Uninstaller
    echo echo =====================================================
    echo echo.
    echo.
    echo net session ^>nul 2^>^&1
    echo if %%errorlevel%% neq 0 ^(
    echo     echo Error: Administrator privileges required!
    echo     pause
    echo     exit /b 1
    echo ^)
    echo.
    echo echo Uninstalling KKOS...
    echo.
    echo REM Remove shortcuts
    echo if exist "%USERPROFILE%\Desktop\KKOS.lnk" del "%USERPROFILE%\Desktop\KKOS.lnk"
    echo if exist "%SHORTCUTS_DIR%\KKOS.lnk" del "%SHORTCUTS_DIR%\KKOS.lnk"
    echo.
    echo REM Remove installation directory
    echo if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
    echo.
    echo echo KKOS has been successfully uninstalled.
    echo pause
) > "%UNINSTALLER%"

REM Add to PATH (optional, with registry)
echo Adding to system PATH...
for /f "tokens=2*" %%A in ('reg query HKLM\SYSTEM\CurrentControlSet\Control\Session' 2^>nul') do (
    @setlocal
)

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d "!Path!;%INSTALL_DIR%" /f >nul 2>&1

REM Create installation log
set INSTALL_LOG=%INSTALL_DIR%\Installation.log
(
    echo KKOS v4.5 Installation Log
    echo ==========================
    echo.
    echo Installation Date: %date% %time%
    echo Installation Directory: %INSTALL_DIR%
    echo.
    echo Files Installed:
    echo  - KKOS.exe ^(Main Executable^)
    echo  - Documentation
    echo  - Uninstall.bat
    echo.
    echo Shortcuts Created:
    echo  - Desktop\KKOS.lnk
    echo  - Start Menu\Programs\KKOS\KKOS.lnk
    echo.
    echo System PATH updated to include: %INSTALL_DIR%
) > "%INSTALL_LOG%"

REM Completion message
echo.
echo =====================================================
echo    Installation Complete!
echo =====================================================
echo.
echo Installation Directory: %INSTALL_DIR%
echo.
echo Quick Start:
echo   - KKOS.exe has been installed and is available from:
echo     * Start Menu (KKOS folder^)
echo     * Desktop (KKOS shortcut^)
echo     * Command Line: KKOS.exe or %INSTALL_DIR%\KKOS.exe
echo.
echo To Uninstall:
echo   - Run: %INSTALL_DIR%\Uninstall.bat as Administrator
echo     OR Right-click Start Menu ^> Programs ^> KKOS ^> Uninstall
echo.
echo Documentation: %INSTALL_DIR%\docs\README.md
echo.
pause
exit /b 0
