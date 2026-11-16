#Requires -Version 5.1
<#
  KKOS v5.2.0 + Odysseus — Unified Windows PowerShell Launcher
  Kurfew Kult Operating System

  Consolidates: launch-windows.ps1, build_and_run.ps1

  Modes:
    .\LAUNCH.ps1                   — Start Odysseus only (fast, no recompile)
    .\LAUNCH.ps1 -Build            — Build KKOS C++ then launch both
    .\LAUNCH.ps1 -KKOSOnly         — Launch KKOS engine only
    .\LAUNCH.ps1 -OdysseuOnly      — Launch Odysseus server only (default)
    .\LAUNCH.ps1 -Port 8080        — Custom Odysseus port
    .\LAUNCH.ps1 -BindHost 0.0.0.0 — Expose Odysseus to LAN (caution)

  Tip: Default bind is 127.0.0.1 (local only). Use 0.0.0.0 only when you
  intentionally want LAN access.
#>
param(
    [switch]$Build,
    [switch]$KKOSOnly,
    [switch]$OdysseusOnly,
    [int]$Port = 7000,
    [string]$BindHost = "127.0.0.1"
)

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

$VERSION    = "5.2.0"
$GAME_NAME  = "kkos_v520"
$BinDir     = Join-Path $PSScriptRoot "bin"
$ObjDir     = Join-Path $PSScriptRoot "obj"
$LogDir     = Join-Path $PSScriptRoot "logs"
$OdyDir     = Join-Path $PSScriptRoot "odysseus"
$SrcDir     = Join-Path $PSScriptRoot "src"
$RaylibDir  = Join-Path $PSScriptRoot "Single-Exe-1.0.0\raylib-5.5\src"
$KKOSExe    = Join-Path $BinDir "$GAME_NAME.exe"

# MSYS2 UCRT64 paths (primary, then canonical fallback)
$MSYS_PATH_PRIMARY   = "C:\msys64\mysys64_new\ucrt64"
$MSYS_PATH_CANONICAL = "C:\msys64\ucrt64"
$MsysBase = if (Test-Path "$MSYS_PATH_PRIMARY\bin\g++.exe") { $MSYS_PATH_PRIMARY } else { $MSYS_PATH_CANONICAL }
$GppExe   = Join-Path $MsysBase "bin\g++.exe"
$GccExe   = Join-Path $MsysBase "bin\gcc.exe"

function Write-Step($msg) {
    Write-Host ""
    Write-Host ("==> " + $msg) -ForegroundColor Cyan
}
function Fail($msg) {
    Write-Host ""
    Write-Host ("ERROR: " + $msg) -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}
function Write-OK($msg) { Write-Host ("[ok] " + $msg) -ForegroundColor Green }
function Write-Warn($msg) { Write-Host ("[!!] " + $msg) -ForegroundColor Yellow }

foreach ($dir in @($BinDir, $ObjDir, $LogDir)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}

# ─────────────────────────────────────────────────────────────────
# OPTIONAL: BUILD KKOS C++ ENGINE
# ─────────────────────────────────────────────────────────────────
if ($Build -and -not $OdysseusOnly) {
    Write-Step "Building KKOS v$VERSION C++ Engine"

    # Resolve compiler
    $Compiler = $null
    if (Test-Path $GppExe) {
        $Compiler = $GppExe
        $env:PATH = "$MsysBase\bin;" + $env:PATH
        Write-OK "MSYS2 UCRT64 g++ : $Compiler"
    } else {
        $sysGpp = Get-Command g++ -ErrorAction SilentlyContinue
        if ($sysGpp) {
            $Compiler = $sysGpp.Source
            Write-OK "System g++ : $Compiler"
        }
    }
    if (-not $Compiler) { Fail "g++ compiler not found. Install MSYS2 or add g++ to PATH." }

    # Legacy source rename
    $legacySrc = Join-Path $SrcDir "kkos_v2_unified.cpp"
    $newSrc    = Join-Path $SrcDir "kkos_v520_unified.cpp"
    if ((Test-Path $legacySrc) -and -not (Test-Path $newSrc)) {
        Rename-Item $legacySrc "kkos_v520_unified.cpp"
        Write-Warn "Renamed kkos_v2_unified.cpp -> kkos_v520_unified.cpp"
    }

    $includes = @(
        "-I`"$PSScriptRoot`"",
        "-I`"$BinDir`"",
        "-I`"$RaylibDir`"",
        "-I`"$($RaylibDir)\external\glfw\include`""
    )
    $defines = @(
        "-DUNICODE", "-D_UNICODE", "-DNOGDI", "-DNOUSER",
        "-DKKOS_VERSION_STR=`"$VERSION`"",
        "-DKKOS_VERSION_MAJOR=5", "-DKKOS_VERSION_MINOR=2",
        "-DKKOS_ODYSSEUS_URL=`"http://127.0.0.1:$Port`""
    )
    $libs  = @("-lopengl32", "-lgdi32", "-lwinmm", "-lpthread")
    $flags = @("-std=c++17", "-O3", "-ffast-math", "-march=native", "-mtune=native", "-Wall")

    $objFiles = @()

    # Compile raylib C sources if present
    if (Test-Path $RaylibDir) {
        Write-Host "Compiling raylib C sources..."
        $gccPath = if (Test-Path $GccExe) { $GccExe } else { "gcc" }
        Get-ChildItem "$RaylibDir\*.c" | ForEach-Object {
            $out = Join-Path $ObjDir ($_.BaseName + ".o")
            & $gccPath -std=c11 -O3 -march=native @includes -c $_.FullName -o $out 2>> (Join-Path $LogDir "build.log")
            if ($LASTEXITCODE -ne 0) { Fail "Raylib compile failed: $($_.Name)" }
            $objFiles += $out
        }
    }

    # Compile KKOS source
    $kkosObj = Join-Path $ObjDir "kkos_v520_unified.o"
    $kkosSrc = Join-Path $SrcDir "kkos_v520_unified.cpp"
    if (-not (Test-Path $kkosSrc)) { Fail "Source not found: $kkosSrc" }

    Write-Host "Compiling kkos_v520_unified.cpp..."
    & $Compiler @flags @includes @defines -c $kkosSrc -o $kkosObj 2>> (Join-Path $LogDir "build.log")
    if ($LASTEXITCODE -ne 0) { Fail "KKOS compile failed. See $LogDir\build.log" }
    $objFiles += $kkosObj

    Write-Host "Linking $GAME_NAME.exe..."
    & $Compiler @flags @includes @defines @objFiles -o $KKOSExe @libs 2>> (Join-Path $LogDir "build.log")
    if ($LASTEXITCODE -ne 0) { Fail "Link failed. See $LogDir\build.log" }

    Write-OK "KKOS engine built: $KKOSExe"
}

# ─────────────────────────────────────────────────────────────────
# LAUNCH KKOS ENGINE
# ─────────────────────────────────────────────────────────────────
if (-not $OdysseusOnly) {
    if (Test-Path $KKOSExe) {
        $env:PATH = "$MsysBase\bin;" + $env:PATH
        Write-Step "Launching KKOS v$VERSION"
        Start-Process $KKOSExe
        Write-OK "KKOS launched in separate window"
    } else {
        Write-Warn "KKOS exe not found at $KKOSExe — run with -Build first, or use BUILD.bat"
        if ($KKOSOnly) { Fail "Cannot launch KKOS — exe missing." }
    }
}

if ($KKOSOnly) {
    Write-Host ""
    Write-Host "KKOS running. This window can be closed." -ForegroundColor Green
    exit 0
}

# ─────────────────────────────────────────────────────────────────
# ODYSSEUS PYTHON SETUP + LAUNCH
# ─────────────────────────────────────────────────────────────────
Write-Step "Checking Python for Odysseus"

if (-not (Test-Path $OdyDir)) { Fail "odysseus\ directory not found at $OdyDir" }

function Get-PyVersion($exe, $args) {
    try { return (& $exe @args -c "import sys; print('.'.join(map(str, sys.version_info[:3])))" 2>$null).Trim() }
    catch { return $null }
}

$pyExe = $null; $pyArgs = @(); $pyVersion = $null
$pyLauncher = Get-Command py -ErrorAction SilentlyContinue
if ($pyLauncher) {
    foreach ($v in @("-3.13", "-3.12", "-3.11")) {
        $ver = Get-PyVersion $pyLauncher.Source @($v)
        if ($ver) { $pyExe = $pyLauncher.Source; $pyArgs = @($v); $pyVersion = $ver; break }
    }
}
if (-not $pyExe) {
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd) {
        $ver = Get-PyVersion $pythonCmd.Source @()
        if ($ver) {
            $parts = $ver.Split('.')
            if ([int]$parts[0] -gt 3 -or ([int]$parts[0] -eq 3 -and [int]$parts[1] -ge 11)) {
                $pyExe = $pythonCmd.Source; $pyVersion = $ver
            }
        }
    }
}
if (-not $pyExe) {
    Fail "Python 3.11+ not found. Install from https://www.python.org/downloads/"
}
Write-OK "Python $pyVersion : $pyExe $($pyArgs -join ' ')"

# Virtual environment
$venvPy  = Join-Path $OdyDir "venv\Scripts\python.exe"
$venvAlt = Join-Path $OdyDir "venv\bin\python.exe"
if (-not (Test-Path $venvPy) -and -not (Test-Path $venvAlt)) {
    Write-Step "Creating Odysseus virtual environment"
    & $pyExe @pyArgs -m venv (Join-Path $OdyDir "venv")
    if ($LASTEXITCODE -ne 0 -or (-not (Test-Path $venvPy) -and -not (Test-Path $venvAlt))) {
        Fail "venv creation failed."
    }
} else {
    Write-Host "venv exists — skipping creation."
}
if (Test-Path $venvAlt) { $venvPy = $venvAlt }

Write-Step "Installing Odysseus dependencies"
& $venvPy -m pip install --upgrade pip --quiet
& $venvPy -m pip install -r (Join-Path $OdyDir "requirements.txt")
if ($LASTEXITCODE -ne 0) { Fail "Dependency install failed." }

Write-Step "Running first-time setup"
$env:ODYSSEUS_SKIP_RUN_HINT = "1"
& $venvPy (Join-Path $OdyDir "setup.py")
if ($LASTEXITCODE -ne 0) { Write-Warn "setup.py returned an error — check output above." }

# Git Bash note
$bash = Get-Command bash -ErrorAction SilentlyContinue
if (-not $bash) {
    Write-Host ""
    Write-Warn "Git Bash not found — full Cookbook/agent-shell features need it."
    Write-Warn "Install Git for Windows: https://git-scm.com/download/win"
}

Write-Step "Starting Odysseus at http://${BindHost}:${Port}"
Write-Host "Press Ctrl+C to stop." -ForegroundColor Gray
Write-Host ""
& $venvPy -m uvicorn app:app --host $BindHost --port $Port --app-dir $OdyDir
