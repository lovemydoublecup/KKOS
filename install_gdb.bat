@echo off
REM Launch MSYS2 UCRT64 environment and install GDB
C:\msys64\msys2_shell.cmd -ucrt64 -no-start -c "pacman -S --noconfirm mingw-w64-ucrt-x86_64-gdb"
