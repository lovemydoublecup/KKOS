# KKOS v2 Unified Bundle Source Mapping

This document maps the files in the bundle to the canonical runtime implementation and original variants.

## Canonical Runtime Entries
- `src/kkos_v2_unified.cpp`
  - The primary, unified kernel for KKOS v4.5.
  - This is the canonical build target for `kkos_v45.exe`.
- `src/kkos_v43_sharded.cpp`
  - The WebSocket-enabled sharded runtime variant for KKOS v4.5.
  - This is the canonical build target for `bin\kkos_v45_sharded.exe`.

## Canonical Source Variants
- `src/kkos_v2_21_monolith.cpp`
  - The canonical KKOS v2.1 monolithic implementation.
  - Contains the full coherent runtime shell, configuration loader, Four-Mother pipeline, telemetry export, and command registry.
- `src/kkos_v39_production.cpp`
  - *Archived Variant*: A production-style variant with WebSocket server support, richer logging, and a more complete command layer. Moved to `archive/` to consolidate active source files.

## Backup and Historical Files
- `archive/kkos_v2_unified.original.bak`
  - Backup of the pre-replacement root source file from before the canonical copy was installed.
- `archive/kkos_v2_unified_replacement.cpp`
  - A preserved replacement candidate that was created during the bundle repair process.
- `archive/kkos_v39_production.cpp`
  - Historical variant of the production kernel.

## Build and Runtime Assets
- `build_windows.bat`
  - Builds `src/kkos_v2_unified.cpp` to `bin\kkos_v2.exe` using either MSVC or MinGW when available.
- `build_linux.sh`
  - Builds `src/kkos_v2_unified.cpp` to `bin/kkos_v2` using `g++`.
- `config.json`
  - Contains canonical runtime baseline thresholds and UX mode flags.
- `web/index.html`
  - Browser interface for live status and plots when WebSocket support is enabled.

## Original Documentation
- `README.txt` (Updated)
  - User-facing instructions and bundle overview, updated for v4.5.
- `KKOS_Codex_Unified.md`
  - Preserved narrative and codex documentation.
