#!/bin/bash
pacman -S --noconfirm mingw-w64-ucrt-x86_64-gdb
ls -la /ucrt64/bin/gdb.exe 2>&1 || echo "GDB not found after install"
