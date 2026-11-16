# KKOS v5.2 Unified Bundle Map

## Overview

- Mixed C++ + Python workspace for the KKOS engine and Odysseus app.
- Main runtime entrypoint: src/kkos_v520_unified.cpp
- Primary build entrypoint: BUILD.bat
- Primary launcher entrypoint: run_kkos_unified.bat

## Key directories

- src/: C++ engine source and runtime logic
- bin/: built executable outputs
- odysseus/: Python web app and backend
- web/: browser-based UI surface
- desktop/: Windows launcher wrapper assets
- Single-Exe-1.0.0/: vendored raylib and supporting sources
- docs/: documentation and design notes
- tests/: validation and test assets

## Build/runtime notes

- C++ build targets a Windows executable with MSYS2 UCRT64 g++.
- Python backend uses Odysseus and a virtual environment under odysseus/venv.
- Desktop launcher entrypoints are implemented via .bat and .cmd wrappers.
