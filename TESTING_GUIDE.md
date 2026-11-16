# KKOS v5.2 + Odysseus — Validation & Testing Guide

## Automated Validation Script

Create file: `validate-build.bat`

```batch
@echo off
setlocal EnableDelayedExpansion

echo.
echo ================================================================
echo KKOS v5.2 + Odysseus Build Validation
echo ================================================================
echo.

set BUNDLE_DIR=%~dp0

REM ─────────────────────────────────────────────────────────────────
REM PART 1: BASIC FILE EXISTENCE CHECKS
REM ─────────────────────────────────────────────────────────────────

echo [PART 1] File Existence Checks
echo.

set "CHECKS_PASSED=0"
set "CHECKS_FAILED=0"

for %%f in (
    "bin\kkos_v520.exe"
    "odysseus\venv\Scripts\python.exe"
    "odysseus\data\app.db"
    "config.json"
    "build-all-steps.bat"
    "start-all.bat"
) do (
    if exist "%BUNDLE_DIR%%%f" (
        echo   [OK] %%f
        set /a CHECKS_PASSED+=1
    ) else (
        echo   [FAIL] %%f
        set /a CHECKS_FAILED+=1
    )
)

echo.
echo   Results: %CHECKS_PASSED% OK, %CHECKS_FAILED% FAILED
echo.

REM ─────────────────────────────────────────────────────────────────
REM PART 2: VERSION CHECKS
REM ─────────────────────────────────────────────────────────────────

echo [PART 2] Version Verification
echo.

REM KKOS version
if exist "%BUNDLE_DIR%bin\kkos_v520.exe" (
    echo   KKOS: Checking version...
    "%BUNDLE_DIR%bin\kkos_v520.exe" --version 2>nul
    if %ERRORLEVEL% equ 0 (
        echo   [OK] KKOS executable is functional
    ) else (
        echo   [WARN] KKOS may have startup issues
    )
) else (
    echo   [SKIP] KKOS not built yet
)

echo.

REM Python version
if exist "%BUNDLE_DIR%odysseus\venv\Scripts\python.exe" (
    echo   Python/Odysseus: Checking version...
    "%BUNDLE_DIR%odysseus\venv\Scripts\python.exe" --version
    if %ERRORLEVEL% equ 0 (
        echo   [OK] Python environment is functional
    ) else (
        echo   [FAIL] Python environment has issues
    )
) else (
    echo   [SKIP] Odysseus not set up yet
)

echo.

REM ─────────────────────────────────────────────────────────────────
REM PART 3: DEPENDENCY CHECKS
REM ─────────────────────────────────────────────────────────────────

echo [PART 3] Python Dependency Checks
echo.

if exist "%BUNDLE_DIR%odysseus\venv\Scripts\python.exe" (
    echo   Checking core dependencies...
    for %%pkg in (fastapi chromadb sqlalchemy pydantic) do (
        "%BUNDLE_DIR%odysseus\venv\Scripts\python.exe" -c "import %%pkg" 2>nul
        if !ERRORLEVEL! equ 0 (
            echo   [OK] %%pkg
        ) else (
            echo   [FAIL] %%pkg
        )
    )
) else (
    echo   [SKIP] Odysseus venv not available
)

echo.

REM ─────────────────────────────────────────────────────────────────
REM PART 4: PORT AVAILABILITY CHECK
REM ─────────────────────────────────────────────────────────────────

echo [PART 4] Network & Port Checks
echo.

REM Check port 7000 (Odysseus)
netstat -ano 2>nul | findstr ":7000 " >nul
if %ERRORLEVEL% equ 0 (
    echo   [WARN] Port 7000 is in use (Odysseus may be running)
) else (
    echo   [OK] Port 7000 is available
)

echo.

REM ─────────────────────────────────────────────────────────────────
REM PART 5: SUMMARY & RECOMMENDATIONS
REM ─────────────────────────────────────────────────────────────────

echo [PART 5] Summary & Recommendations
echo.

if %CHECKS_FAILED% equ 0 (
    echo   [SUCCESS] Build validation passed!
    echo.
    echo   Next steps:
    echo   1. Run: start-all.bat
    echo   2. Wait for Odysseus to start (port 7000)
    echo   3. Open: http://127.0.0.1:7000
    echo   4. KKOS window will open separately
) else (
    echo   [ISSUES DETECTED] Build validation found problems
    echo.
    echo   Steps to fix:
    echo   1. Re-run: build-all-steps.bat
    echo   2. Wait for full completion
    echo   3. Run this validation script again
)

echo.
echo ================================================================
echo.
pause
```

---

## Manual Testing Procedures

### Test 1: KKOS Executable Validation

**Objective**: Verify KKOS compiled successfully

**Time**: 1-2 minutes

```batch
REM 1. Check executable exists
dir bin\kkos_v520.exe

REM 2. Check file size (should be 50-200 MB)
for /f "tokens=5" %a in ('dir bin\kkos_v520.exe ^| findstr kkos') do echo Size: %a bytes

REM 3. Attempt to get version
bin\kkos_v520.exe --version

REM 4. Test with --help flag
bin\kkos_v520.exe --help

REM 5. Check for error logs
if exist logs\kkos_unified.log (
    echo Checking logs...
    findstr /I "error crash fail" logs\kkos_unified.log
) else (
    echo No logs yet (normal for new build)
)
```

**Expected Results**:

- ✅ File exists and is 50-200 MB
- ✅ Version command works
- ✅ Help shows DAW/game engine options
- ✅ No critical errors in logs

---

### Test 2: Python & Odysseus Environment Validation

**Objective**: Verify Python and dependencies

**Time**: 2-3 minutes

```batch
REM 1. Check venv exists
if exist odysseus\venv\Scripts\python.exe echo venv found

REM 2. Check Python version
odysseus\venv\Scripts\python --version

REM 3. List installed packages
odysseus\venv\Scripts\pip list | findstr /I "fastapi chromadb sqlalchemy"

REM 4. Test core imports
odysseus\venv\Scripts\python -c ^
    "import fastapi, chromadb, sqlalchemy, pydantic; print('All core imports OK')"

REM 5. Check database
if exist odysseus\data\app.db echo Database file found

REM 6. Test database connectivity
odysseus\venv\Scripts\python -c ^
    "from core.database import SessionLocal; s = SessionLocal(); print('Database OK')"
```

**Expected Results**:

- ✅ venv exists at `odysseus\venv\`
- ✅ Python 3.11+ or 3.14+
- ✅ Key packages installed: fastapi, chromadb, sqlalchemy
- ✅ All core imports successful
- ✅ Database file exists and is accessible

---

### Test 3: Startup Test (Services)

**Objective**: Verify both services start

**Time**: 5-10 minutes

**Start Services**:

```batch
REM Open two Command Prompts:

REM Terminal 1: Start KKOS
cd C:\Users\jaile\Downloads\KKOS_v5.2_Unified_Bundle
bin\kkos_v520.exe

REM Terminal 2: Start Odysseus
cd C:\Users\jaile\Downloads\KKOS_v5.2_Unified_Bundle\odysseus
..\odysseus\venv\Scripts\python -m uvicorn app:app --host 127.0.0.1 --port 7000
```

**Verification**:

Terminal 1 (KKOS) should show:

```text
[KKOS] Starting engine...
[KKOS] Initializing graphics...
[KKOS] Window created: 1920x1080
[KKOS] Connecting to Odysseus at http://127.0.0.1:7000
[KKOS] Ready
```

Terminal 2 (Odysseus) should show:

```text
INFO:     Started server process [PID]
INFO:     Waiting for application startup.
INFO:     Application startup complete
INFO:     Uvicorn running on http://127.0.0.1:7000
```

**Manual Browser Test**:

```text
1. Open http://127.0.0.1:7000
2. Should see Odysseus login page
3. Enter credentials (admin / password from setup)
4. Should load AI workspace
5. Try: Chat, Documents, Settings
```

---

### Test 4: Integration Test

**Objective**: Verify KKOS and Odysseus communicate

**Time**: 5 minutes

```batch
REM 1. Both services running (from Test 3)

REM 2. In Odysseus browser console:
REM    - Open Developer Tools (F12)
REM    - Network tab
REM    - Try an AI chat request
REM    - Should see API calls to /api/chat and responses

REM 3. In KKOS console window:
REM    - Should see: "[ODYSSEUS] API request received"
REM    - Latency should be < 100ms

REM 4. Test full workflow:
REM    a) Write text in Odysseus
REM    b) Click "Get AI Summary"
REM    c) Should process in < 1 second
REM    d) Result should appear
```

**Expected Results**:

- ✅ Both services stay running (no crashes)
- ✅ Web UI loads and responds
- ✅ Network requests complete successfully
- ✅ Low latency (< 500ms for typical requests)

---

## Performance Testing

### Stress Test: Odysseus

```batch
REM Run on test machine:
cd odysseus
venv\Scripts\python -m pytest tests/ -v
```

**Expected**: All tests pass

### Benchmark: KKOS Startup Time

```powershell
REM Run PowerShell:
powershell -Command "
$timer = Measure-Command {
    & 'bin\kkos_v520.exe'
}
Write-Host 'Startup time:' $timer.TotalSeconds 'seconds'
"
```

**Expected**: < 3 seconds

### Benchmark: Odysseus API Latency

```powershell
REM With Odysseus running:
powershell -Command "
$times = @()
for ($i=0; $i -lt 10; $i++) {
    $timer = Measure-Command {
        Invoke-WebRequest http://127.0.0.1:7000/api/version
    }
    $times += $timer.TotalMilliseconds
}
$avg = ($times | Measure-Object -Average).Average
Write-Host 'Average latency:' $avg 'ms'
"
```

**Expected**: 50-150 ms

---

## Regression Testing

After updates, verify nothing broke:

- [ ] KKOS starts without crashing
- [ ] KKOS connects to Odysseus
- [ ] Odysseus API responds on port 7000
- [ ] Database queries work
- [ ] File uploads work
- [ ] AI chat works
- [ ] No new error messages in logs

---

## Debugging Failed Tests

### If KKOS won't start

1. Check `logs/kkos_unified.log` for errors
2. Verify raylib paths in config
3. Recompile: `build-all-steps.bat`

### If Odysseus won't start

1. Check port 7000 is free: `netstat -ano | findstr :7000`
2. Verify venv: `odysseus\\venv\\Scripts\\python --version`
3. Check database: `ls odysseus/data/app.db`
4. Reinstall deps: `pip install -r odysseus/requirements.txt`

### If tests timeout

1. Check system resources: `tasklist /v | findstr cpu`
2. Close unnecessary applications
3. Increase timeouts in test configuration
4. Run tests individually

---

## Reporting Issues

When reporting issues, include:

1. **System Info**:

```batch
systeminfo | findstr /C:"OS Configuration" /C:"Processor" /C:"Total Physical Memory"
```

1. **Error Logs**:

```batch
logs\kkos_unified.log
odysseus\logs\app.log
```

1. **Validation Report**:

```batch
validate-build.bat > validation-report.txt
```

1. **Version Info**:

```batch
bin\kkos_v520.exe --version
odysseus\venv\Scripts\python -c "from core.constants import APP_VERSION; print(APP_VERSION)"
```

---

**Last Updated**: 2026-06-23
**Test Coverage**: Comprehensive
**Automation**: Available via `validate-build.bat`
