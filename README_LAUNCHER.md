# KKOS v5.2 Desktop Launcher

## Quick start

- Double-click run_kkos_unified.bat to open the KKOS runtime, web UI, and Odysseus backend.
- Use start-kkos-only.bat for the engine and UI only.
- Use start-odysseus-only.bat for the backend only.

## What it launches

- KKOS engine: bin/kkos_v520.exe
- KKOS UI: web/index.html
- Odysseus backend: odysseus/venv/bin/python.exe -m uvicorn app:app --host 127.0.0.1 --port 7000
