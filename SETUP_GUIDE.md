# KKOS v5.2 + Odysseus Unified Bundle — Complete Setup & Maintenance Guide

> This file is a setup guide. The canonical repository documentation is `README.md`.
>
> Use `BUILD.bat` on Windows and `./build.sh` on Linux/macOS.

## Quick Start

### Windows (recommended)
```bat
cd /d "C:\Users\jaile\Downloads\KKOS_v5.2_Unified_Bundle"
BUILD.bat
```

This will:
- Compile the KKOS C++ engine
- Create or reuse `odysseus/venv`
- Install Odysseus Python dependencies
- Generate runtime launcher scripts

### Linux / macOS
```bash
cd /d "/Users/<you>/Downloads/KKOS_v5.2_Unified_Bundle"
./build.sh
```

## Prerequisites

- MSYS2 UCRT64 `g++` or equivalent C++ toolchain on Windows
- Python 3.11+ on Windows or Linux/macOS
- Docker Desktop only if you want containerized Odysseus
- `git` is optional but recommended for repo management

## Windows setup

1. Open PowerShell or cmd.exe.
2. Run from the repo root:
   ```bat
   BUILD.bat
   ```
3. Launch runtime:
   ```bat
   start-all.bat
   ```
4. Or use PowerShell launcher:
   ```powershell
   .\LAUNCH.ps1
   ```

## Linux / macOS setup

1. Open a shell in the repo root.
2. Run:
   ```bash
   ./build.sh
   ```
3. Start Odysseus and KKOS from the shell after build completes.

## Common commands

- `BUILD.bat kkos` — Windows C++ build only
- `BUILD.bat odysseus` — Windows Odysseus setup only
- `BUILD.bat run` — Windows build then launch
- `BUILD.bat diag` — Windows build environment diagnostics
- `BUILD.bat vscode` — write VS Code config files on Windows
- `BUILD.bat clean` — archive legacy files and clear `obj/`

- `./build.sh diag` — Linux/macOS diagnostics
- `./build.sh clean` — Linux/macOS clean mode

## Notes

- `build-all-steps.bat` and other obsolete script names are legacy; use `BUILD.bat` instead.
- `README (1).md`, `README.txt`, and `BUNDLE_README.md` are kept only for reference.
- For current workflow instructions, follow `README.md`.

## Reference docs

- `README.md` — canonical repo documentation
- `CONTRIBUTING.md` — contribution guidance
- `DIAGNOSTICS.md` — build and runtime troubleshooting
- `odysseus/README.md` — Odysseus-specific docs
- `odysseus/SECURITY.md` — Odysseus security guidance
