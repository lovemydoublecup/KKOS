@echo off
setlocal enabledelayedexpansion

REM Set up MSYS2 UCRT64 environment
set MSYSTEM=UCRT64
set MSYSCON=mintty.exe
cd C:\msys64\usr\bin

REM Run pacman to install GDB
bash.exe -l -c "pacman -Sy && pacman -S --noconfirm mingw-w64-ucrt-x86_64-gdb"

REM Check if GDB was installed
if exist C:\msys64\ucrt64\bin\gdb.exe (
    echo GDB installation successful
    C:\msys64\ucrt64\bin\gdb.exe --version
) else (
    echo GDB installation failed
)
