# KKOS v5.2 Unified Bundle

> KKOS DAW/game engine + Odysseus AI workspace, integrated as a single deployable package.

```
KKOS_v5.2_Unified_Bundle/
├── src/                   ← KKOS C++ source
├── bin/                   ← compiled KKOS executable + codex
├── odysseus/              ← Odysseus AI workspace (Python/FastAPI)
│   ├── app.py
│   ├── requirements.txt
│   ├── setup.py
│   └── ...
├── build-windows.bat      ← builds KKOS C++ AND sets up Odysseus (Windows)
├── build-all.sh           ← builds KKOS C++ AND sets up Odysseus (Linux/macOS)
├── start-all.sh           ← starts both KKOS and Odysseus (Linux/macOS)
├── start-all.bat          ← starts both KKOS and Odysseus (Windows)
├── BUNDLE_README.md       ← this file
└── KURFEW_KULT_CODEX.md  ← auto-generated: all docs consolidated
```

## What is this bundle?

**KKOS** (Raptor Lake–optimized C++ DAW/game engine) and **Odysseus** (self-hosted
AI workspace: chat, agent, deep research, memory, email, calendar) ship together
so KKOS can use Odysseus as its local AI backend — for in-game/in-DAW AI assistance,
agent automation, and deep research — without requiring any external cloud service.

Odysseus runs as a background service on `http://127.0.0.1:7000` while KKOS runs
on the desktop. KKOS connects to Odysseus via its local API.

## Quick start

### Windows
```bat
:: 1. Build KKOS + set up Odysseus (one time)
build-windows.bat

:: 2. Start everything
start-all.bat
```

### Linux / macOS
```bash
# 1. Build KKOS + set up Odysseus (one time)
./build-all.sh

# 2. Start everything
./start-all.sh
```

## Ports

| Service | Port | Notes |
|---|---|---|
| Odysseus web UI | 7000 | `http://localhost:7000` |
| SearXNG | 8080 | internal only |
| ChromaDB | 8100 | internal only |
| ntfy | 8091 | internal only |
| Ollama (if used) | 11434 | optional, external |

## Security

Odysseus is an admin console with shell, file, and model-serving access.
- Keep `AUTH_ENABLED=true` (default).
- Keep both services on loopback (`127.0.0.1`) unless you intentionally expose them via a trusted reverse proxy.
- See `odysseus/SECURITY.md` for the full policy.

## Components

- **KKOS** — see `src/` and `bin/` for the C++ DAW/game engine.
- **Odysseus** — see `odysseus/` for the AI workspace. Full docs in `odysseus/README.md`.
- **Codex** — `KURFEW_KULT_CODEX.md` is auto-rebuilt by `build-windows.bat` / `build-all.sh` and consolidates all Markdown docs from both projects.
