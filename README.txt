
# KKOS v4.5 Unified Bundle - Windows Usage

This bundle contains a runnable C++ simulation framework for KKOS v4.5.
It is a terminal-based prototype, not a real operating system or kernel.

Key files in this bundle:
- src/kkos_v2_unified.cpp
- src/kkos_v43_sharded.cpp
- build_windows.bat
- build_linux.sh
- README.txt
- docs/KKOS_Codex_Unified.md
- docs/SOURCE_MAPPING.md
- docs/assets/
  - docs/assets/pdf/
  - docs/assets/docx/
  - docs/assets/images/
  - docs/assets/kkos_v4/
- config.json
- web/index.html
- src/kkos_v2_21_monolith.cpp
- archive/kkos_v39_production.cpp (moved to archive)
- archive/kkos_v2_unified.original.bak
- archive/kkos_v2_unified_replacement.cpp

## Bundle Source Mapping
This bundle includes the following source variants and mappings:
- `src/kkos_v2_unified.cpp` — The primary, unified kernel for KKOS v4.5 (`kkos_v45.exe`).
- `src/kkos_v43_sharded.cpp` — sharded WebSocket-enabled runtime variant.
- `src/kkos_v2_21_monolith.cpp` — canonical KKOS v2.1 monolithic implementation used to replace the root entry.
- `archive/kkos_v39_production.cpp` — *Archived Variant*: production variant with WebSocket and richer runtime scaffolding (moved from `src/`).
- `archive/kkos_v2_unified_replacement.cpp` — preserved replacement variant created during earlier bundle reconstruction.
- `archive/kkos_v2_unified.original.bak` — backup of the prior root source before canonical replacement.

## 1. Download and Extract

Download the bundle ZIP and extract it to a folder.
After extraction you should see:
- `src/kkos_v2_unified.cpp`
- `src/kkos_v43_sharded.cpp`
- `build_windows.bat`
- `build_linux.sh`
- `README.txt`
- `KKOS_Codex_Unified.md`
- `config.json`
- `web/index.html`

## 2. Install a C++ Compiler

You need one of these compilers:

### Option A — Easiest: MinGW-w64 (Recommended)

Install MSYS2 from https://www.msys2.org/
Then open the MSYS2 terminal and run:

```bash
pacman -S mingw-w64-ucrt-x86_64-gcc
```

That installs `g++`.

### Option B — Visual Studio Build Tools

Install Visual Studio Build Tools:
https://visualstudio.microsoft.com/visual-cpp-build-tools/
During install, check **Desktop development with C++**.

## 3. Build the Executable

### Easy Method

Double-click `build_windows.bat`.
If the compiler is installed and on your PATH, it will create:

- `bin\kkos_v45.exe` (from `src/kkos_v2_unified.cpp`)

To build the WebSocket-enabled sharded runtime instead, run:

```cmd
build_windows.bat sharded
```

That produces `bin\kkos_v43.exe`.

To build the v4.5 alias, run:

```cmd
build_windows.bat v45
```

That produces `bin\kkos_v45.exe`.

### Manual Build

With MinGW:

```bash
g++ -std=c++17 "src/kkos_v2_unified.cpp" -o bin/kkos_v2.exe
```

Or for the sharded WebSocket variant:

```bash
g++ -std=c++17 "src/kkos_v43_sharded.cpp" -o bin/kkos_v43.exe
```

Or for the v4.5 build variant:

```bash
g++ -std=c++17 "src/kkos_v43_sharded.cpp" -o bin/kkos_v45.exe
```

With Visual Studio `cl`:

```cmd
cl /std:c++17 /EHsc "src\kkos_v2_unified.cpp" /Fe:bin\kkos_v2.exe
```

Or for the sharded runtime:

```cmd
cl /std:c++17 /EHsc "src\kkos_v43_sharded.cpp" /Fe:bin\kkos_v43.exe
```

Or for the v4.5 build variant:

```cmd
cl /std:c++17 /EHsc "src\kkos_v43_sharded.cpp" /Fe:bin\kkos_v45.exe
```

On Linux, run:

```bash
./build_linux.sh
./build_linux.sh v43
./build_linux.sh v45
```

## 4. Run the Program

Double-click `bin\kkos_v2.exe`, `bin\kkos_v43.exe`, or `bin\kkos_v45.exe`, or run from Command Prompt:

```cmd
bin\kkos_v2.exe
```

or

```cmd
bin\kkos_v43.exe
```

or

```cmd
bin\kkos_v45.exe
```

The current build target (`src/kkos_v2_unified.cpp`) is the canonical runtime.
The sharded WebSocket-enabled runtime is available via `src/kkos_v43_sharded.cpp`.
Run `build_windows.bat v45` to generate `bin\kkos_v45.exe`.
Open `web/index.html` in a browser after running the `kkos_v43` or `kkos_v45` variant to view live updates.

## 5. Available Commands

Inside the app, type `help`.
Supported commands:

- `help`
- `inoculate`
- `collapse`
- `status`
- `status --json`
- `coherence`
- `sustain`
- `reset`
- `codex <term>`
- `export telemetry`
- `export graph`
- `exit`

## 6. Example Session

```text
kkos> inoculate

[ INOCULATE ] Unified pipeline online
[ GATE ] Access validated
[ THRESHOLD ] Input sanitized
[ KILN ] Runtime active
[ CRYPT ] Persistence synchronized
[ COHERENCE ] Stable at 94/100

kkos> collapse
kkos> status
```

## 7. If You Get “g++ Not Found”

That means the compiler isn't installed or not on PATH.
For MSYS2, install with:

```bash
pacman -S mingw-w64-ucrt-x86_64-gcc
```

Then close and reopen the terminal.

## 9. Configuration and Logs

The app loads optional settings from `config.json`.
By default it writes a session log to `logs/kkos_v2.log` and telemetry reports to `reports/`.

See `SOURCE_MAPPING.md` for a complete file cross-reference and source lineage.

## 8. What This Actually Is

This project is:
- a C++17 terminal simulation
- a coherence dashboard
- a codex runtime shell
- a systems narrative framework
- an architecture prototype

It is not:
- a replacement Windows kernel
- a literal AI OS
- a real bio-synthetic runtime

The bundle preserves symbolic language, speculative concepts, and fictional inspiration while grounding them in a runnable software framework.
