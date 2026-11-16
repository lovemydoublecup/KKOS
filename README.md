# KKOS v4.5 Unified Bundle — Project Organization

This document describes the final folder structure and build workflow for the cleaned KKOS v4.5 bundle.

## Folder Structure

```
KKOS_v4.5_Unified_Bundle/
├── src/                              # C++ source files
│   ├── kkos_v2_unified.cpp          # Main v2 runtime (canonical target)
│   ├── kkos_v43_sharded.cpp         # WebSocket-enabled v4.3/v4.5 variant
│   ├── kkos_v2_21_monolith.cpp      # Monolithic v2.1 reference implementation
│   ├── kkos_v39_production.cpp      # Production variant with enhanced logging
│   └── kkos_v2_unified_replacement.cpp # Historical variant
│
├── bin/                              # Unified binaries
│   ├── kkos_v45.exe                 # Main Kernel Binary
│   └── kkos_v45_sharded.exe         # WebSocket/Network Variant
│
├── docs/                             # Documentation and assets
│   ├── KKOS_Codex_Unified.md        # Narrative and symbolic documentation
│   ├── SOURCE_MAPPING.md            # File cross-reference and lineage
│   ├── README.md                    # This file
│   └── assets/
│       ├── pdf/                     # Codex PDFs and reference materials
│       ├── docx/                    # Word documents
│       ├── images/                  # Diagrams and visual assets
│       └── kkos_v4/                 # Version 4 specific resources
│
├── archive/                          # Historical backups
│   ├── kkos_v2_unified.original.bak # Pre-refactor source
│   └── kkos_v2_unified_replacement.cpp # Alternative implementation
│
├── tmp/                              # Temporary files
│   └── tmp_test.txt
│
├── web/                              # Browser interface (for v43/v45 WebSocket)
│   └── index.html
│
├── .vscode/                          # VS Code configuration
│   ├── launch.json                  # Debugger settings (GDB + MSYS2 mingw64)
│   └── tasks.json                   # Build tasks (all with MSYS2 PATH)
│
├── build_windows.bat                # Windows build script
├── build_linux.sh                   # Linux build script
├── Makefile                         # Universal build (Linux/Windows/macOS)
├── config.json                      # Runtime configuration
├── README.txt                       # User-facing guide
└── LICENSE / etc.
```

## Build Workflow

### Windows (Recommended)

The build scripts automatically detect and use the available C++ compiler:

```bash
# Build v2 (default canonical runtime)
build_windows.bat

# Build v4.3 (WebSocket-enabled sharded variant)
build_windows.bat v43

# Build v4.5 (alias for v4.3)
build_windows.bat v45
```

**Compiler Detection Order:**
1. MSVC (Visual Studio C++ Build Tools) if on PATH
2. MinGW g++ (MSYS2 mingw64) if on PATH
3. Clang if on PATH

**Recommended:** Use MSYS2 UCRT64 toolchain for best Windows/C++17 compatibility.

### Linux/macOS

```bash
# Build v2
./build_linux.sh

# Build v4.3
./build_linux.sh v43

# Build v4.5
./build_linux.sh v45
```

### Using Make (All Platforms)

```bash
# Build v2
make all

# Build v4.3
make v43

# Build v4.5
make v45

# Clean artifacts
make clean

# Run v2
make run

# Run v4.3
make run-v43

# Run v4.5
make run-v45
```

## VS Code Integration

### Build Tasks

All tasks are configured in `.vscode/tasks.json`:

- **Build KKOS v4.5** (default): `Ctrl+Shift+B` or `Cmd+Shift+B`
- **Build KKOS Unified Kernel (v2)**: Available in task selection
- **Build KKOS v4.3**: Available in task selection

All tasks are configured for `C:\msys64\ucrt64\bin`.

### Debugging

Press **F5** to launch the debugger:

- Launches `bin/kkos_v45.exe`
- Uses GDB from MSYS2 UCRT64
- Pre-launch build runs automatically
- Debugger attaches with pretty-printing enabled

### Configuration

- **Compiler:** MinGW g++ (via MSYS2 UCRT64)
- **Standard:** C++17
- **Windows Linking:** ws2_32 (Winsock2) for network support
- **Debug Symbols:** Enabled by default

## Source Variants

| Variant | Purpose | Features |
|---------|---------|----------|
| `kkos_v2_unified.cpp` | Main runtime | Core coherence engine, terminal shell |
| `kkos_v43_sharded.cpp` | WebSocket runtime | Network API, sharded state, binary protocol |
| `kkos_v2_21_monolith.cpp` | Reference | Monolithic implementation for comparison |
| `kkos_v39_production.cpp` | Production | Enhanced logging, richer command layer |

## Build Artifacts

| Executable | Built From | Features |
|------------|-----------|----------|
| `kkos_v2.exe` | `src/kkos_v2_unified.cpp` | Canonical terminal runtime |
| `kkos_v43.exe` | `src/kkos_v43_sharded.cpp` | WebSocket server on port 8080 |
| `kkos_v45.exe` | `src/kkos_v43_sharded.cpp` | Alias for v4.3 (identical binary) |

## Configuration

Runtime settings are loaded from `config.json` (optional):

```json
{
  "baseSynchronization": 0.85,
  "baseStability": 0.80,
  "baseSustainability": 0.95,
  "baseRuntimeIntegrity": 0.90,
  "collapseThreshold": 35,
  "recoveryThreshold": 55,
  "kidMode": false,
  "expertMode": true,
  "sustainBoostFactor": 1.75
}
```

If not found, hardcoded defaults are used.

## Available Commands (Runtime)

Inside any running executable, type `help` to see available commands:

- `help` — Show this help text
- `inoculate` — Initialize the runtime
- `collapse` — Trigger a controlled collapse
- `status` — Print current system state
- `status --json` — Output state as JSON
- `coherence` — Show coherence metrics
- `sustain` — Begin recovery/sustainability mode
- `reset` — Reset to initial state
- `codex <term>` — Query the internal codex database
- `export telemetry` — Save telemetry report
- `export graph` — Save state graph
- `exit` — Quit the program

## WebSocket Interface (v4.3 / v4.5)

When running `kkos_v43.exe` or `kkos_v45.exe`:

- Server listens on `ws://localhost:8080`
- Binary protocol with 32-byte headers
- Real-time coherence snapshots and rollback events
- Open `web/index.html` in a browser to view live updates

## Documentation

- **SOURCE_MAPPING.md** — Complete file cross-reference and build dependencies
- **KKOS_Codex_Unified.md** — Narrative, symbolic, and architectural documentation
- **assets/pdf/** — Reference PDFs and codex materials
- **assets/kkos_v4/** — Version 4 specific resources

## Troubleshooting

### "No supported compiler found"

**Windows:** Install MSYS2 from https://www.msys2.org/ and add `C:\msys64\ucrt64\bin` to PATH.

**Linux/macOS:** Ensure `g++` is installed (`apt-get install g++` or `brew install gcc`).

### F5 Debugger Won't Launch

- Verify `gdb.exe` is at `C:\msys64\ucrt64\bin\gdb.exe`
- Check that the build task completed successfully (no compilation errors)
- Restart VS Code

### WebSocket Server Fails to Start

- Ensure port 8080 is not in use
- Check that `src/kkos_v43_sharded.cpp` is being compiled (use `build_windows.bat v43`)
- On Windows, Winsock2 (`ws2_32`) must be linked

## Repository Integrity

All source files are located in `src/` and are version-controlled. Historical variants and backups are in `archive/` for reference only. The bundle is self-contained and requires no external dependencies beyond a C++17 compiler and standard library.

---

**Last updated:** May 18, 2026  
**Bundle version:** KKOS v4.5 Unified  
**Status:** ✓ Clean, buildable, documented
