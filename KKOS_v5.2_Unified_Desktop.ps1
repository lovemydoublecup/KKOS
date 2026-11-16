$ErrorActionPreference = 'SilentlyContinue'
$repo = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $repo 'bin/kkos_v520.exe'
$web = Join-Path $repo 'web/index.html'
$batch = Join-Path $repo 'run_kkos_unified.bat'

if (Test-Path $exe) {
    Start-Process -FilePath $exe -WindowStyle Normal | Out-Null
}

if (Test-Path $web) {
    Start-Process -FilePath $web | Out-Null
}

if (Test-Path $batch) {
    Start-Process -FilePath $batch -WindowStyle Minimized | Out-Null
}
