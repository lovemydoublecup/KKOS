@echo off
setlocal enabledelayedexpansion

if not exist bin (
    mkdir bin
)

set "TARGET=src\kkos_v520_unified.cpp"
set "OUTPUT=bin\kkos_v520.exe"
set "LINK_LIBS="

if /I "%1"=="sharded" (
    set "TARGET=src\kkos_v43_sharded.cpp"
    set "OUTPUT=bin\kkos_v520_sharded.exe"
    set "LINK_LIBS=ws2_32.lib"
)

if not exist "%TARGET%" (
    if "%TARGET%"=="src\kkos_v520_unified.cpp" if exist "src\kkos_v2_unified.cpp" (
        echo [RELABEL] Legacy source detected. Renaming src\kkos_v2_unified.cpp to src\kkos_v520_unified.cpp...
        ren "src\kkos_v2_unified.cpp" "kkos_v520_unified.cpp"
        set "TARGET=src\kkos_v520_unified.cpp"
    )
)

echo Building %TARGET% -> %OUTPUT%

set "COMPILER_FOUND=0"

REM Try MSYS2 UCRT64 g++ first (recommended)
if exist "C:\msys64\mysys64_new\ucrt64\bin\g++.exe" (
    echo Using MSYS2 UCRT64 g++ compiler...
    set "PATH=C:\msys64\mysys64_new\ucrt64\bin;%PATH%"
    g++ -std=c++17 "%TARGET%" -o "%OUTPUT%" -lws2_32
    exit /b %errorlevel%
)

REM Try MSVC
where cl >nul 2>nul
if %errorlevel%==0 (
    set "COMPILER_FOUND=1"
) else (
    if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (
        set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
    ) else if exist "%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe" (
        set "VSWHERE=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"
    )
    if defined VSWHERE (
        "%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath > "%temp%\vswhere_out.txt" 2>nul
        if exist "%temp%\vswhere_out.txt" (
            set /p "VS_INSTALL_PATH="<"%temp%\vswhere_out.txt"
            if defined VS_INSTALL_PATH (
                echo Found Visual Studio install at %VS_INSTALL_PATH%
                if exist "%VS_INSTALL_PATH%\VC\Auxiliary\Build\vcvarsall.bat" (
                    call "%VS_INSTALL_PATH%\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul 2>&1
                    where cl >nul 2>nul
                    if %errorlevel%==0 set "COMPILER_FOUND=1"
                )
            )
        )
    )
)

if %COMPILER_FOUND%==1 (
    echo Using MSVC compiler...
    cl /std:c++17 /EHsc "%TARGET%" /Fe:"%OUTPUT%" %LINK_LIBS%
    exit /b %errorlevel%
)

REM Try generic g++ (MinGW, Cygwin, etc.)
where g++ >nul 2>nul
if %errorlevel%==0 (
    echo Using MinGW g++ compiler...
    g++ -std=c++17 "%TARGET%" -o "%OUTPUT%" -lws2_32 %LINK_LIBS%
    exit /b %errorlevel%
)

where clang++ >nul 2>nul
if %errorlevel%==0 (
    echo Using Clang compiler...
    clang++ -std=c++17 "%TARGET%" -o "%OUTPUT%"
    exit /b %errorlevel%
)

echo No supported compiler found.
echo Install Visual Studio Build Tools, MinGW-w64, or Clang.
exit /b 1
