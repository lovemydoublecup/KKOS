# ============================================================================
# KKOS v5.2.0 UNIFIED BUILD & LAUNCHER
# ============================================================================

$CompilerPath = "C:\msys64\mysys64_new\ucrt64\bin\g++.exe"
$SourceFile = "src/kkos_v520_unified.cpp"
$OutputFile = "bin/kkos_v520.exe"
$RaylibDir = "Single-Exe-1.0.0/raylib-5.5/src"

Write-Host "-> Validating Environment..." -ForegroundColor Cyan
if (-not (Test-Path $CompilerPath)) {
    Write-Host "Compiler not found at $CompilerPath. Checking system PATH..." -ForegroundColor Yellow
    $CompilerPath = Get-Command g++.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

if (-not $CompilerPath) {
    Write-Error "g++ compiler not found. Please ensure MSYS2 UCRT64 is installed and added to your PATH."
    exit 1
}

if (!(Test-Path "bin")) { New-Item -ItemType Directory -Path "bin" | Out-Null }
if (!(Test-Path "logs")) { New-Item -ItemType Directory -Path "logs" | Out-Null }

Write-Host "-> Compiling KKOS Unified Core..." -ForegroundColor Yellow
& $CompilerPath -std=c++17 -O3 -march=native -mtune=native `
    -DKKOS_VERSION_MAJOR=5 -DKKOS_VERSION_MINOR=2 -DKKOS_VERSION_PATCH=0 `
    -DUNICODE -D_UNICODE -DNOGDI -DNOUSER `
    $SourceFile -o $OutputFile `
    -I $RaylibDir -L $RaylibDir `
    -lraylib -lopengl32 -lgdi32 -lwinmm

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Compilation Successful." -ForegroundColor Green
    Write-Host "-> Launching LOVEMYDOUBLECUP Engine..." -ForegroundColor Cyan
    Start-Process $OutputFile
} else {
    Write-Error "Compilation failed. Check error logs."
    exit 1
}

Write-Host "-> Initializing Hermes Agent Sync..." -ForegroundColor Magenta
& ./hermes-agent-main/hermes-agent-main/scripts/install.ps1 -SkipSetup -NonInteractive
Write-Host "[OK] System Online." -ForegroundColor Green