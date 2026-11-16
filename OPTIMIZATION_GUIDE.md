# KKOS v5.2 + Odysseus — Optimization & Maintenance Guide

## Performance Tuning

### KKOS C++ Engine Optimization

#### Compilation Optimization Levels

**Maximum Performance** (Slower build, fastest runtime):

```batch
-std=c++17 -O3 -flto -march=native -mtune=native -ffast-math -fno-plt
```

- `-O3`: Maximum optimization
- `-flto`: Link-time optimization (requires ~2GB RAM)
- `-march=native -mtune=native`: CPU-specific tuning
- `-ffast-math`: Floating point optimizations
- **Build Time**: 60-90 minutes
- **Best for**: Audio processing, game loops

**Balanced** (Recommended):

```batch
-std=c++17 -O2 -march=native -mtune=native
```

- `-O2`: Good optimization level
- Still 30-50% faster runtime than O1
- **Build Time**: 20-40 minutes

**Debug/Development** (Fast compile):

```batch
-std=c++17 -O1 -g -Wall
```

- `-O1`: Minimal optimization
- `-g`: Debug symbols
- **Build Time**: 5-10 minutes

#### Recompile with New Flags

```batch
REM Edit compilation command in build-all-steps.bat
REM Find the line with g++.exe... change optimization flags
REM Example:
C:\msys64\mysys64_new\ucrt64\bin\g++.exe -std=c++17 -O3 -flto -march=native ...

REM Then run:
build-all-steps.bat
```

### Odysseus Python Optimization

#### Dependency Optimization

**Reduce Memory Usage**:

```batch
cd odysseus
venv\Scripts\pip install --no-cache-dir -r requirements.txt
REM Removes pip cache, saves ~500MB
```

**Enable Performance Extensions**:

```batch
venv\Scripts\pip install uvloop aioredis
REM Optional: async accelerators (advanced users)
```

#### Database Optimization

**Reindex ChromaDB**:

```python
from src.chroma_client import get_chroma_client
client = get_chroma_client()
client.reset()  # Clears and reindexes vector store
```

**Vacuum SQLite**:

```python
from core.database import SessionLocal
from sqlalchemy import text
session = SessionLocal()
session.execute(text("VACUUM"))
session.commit()
```

### System-Level Optimization

**Disable Background Services During Build**:

```batch
taskkill /F /IM OneDrive.exe
taskkill /F /IM DropBox.exe
taskkill /F /IM Antimalware Service Executable
REM Temporarily reduce system load
```

**Monitor During Compilation**:

```batch
REM Open Task Manager (Ctrl+Shift+Esc)
REM Watch: CPU (should be 80-100%), RAM (monitor for swapping)
REM If RAM hits 90%+ and system slows, kill build and use -O2 instead
```

---

## Version Management & Updates

### Checking Current Versions

```batch
REM KKOS version
bin\kkos_v520.exe --version

REM Odysseus version
odysseus\venv\Scripts\python -c "from core.constants import APP_VERSION; print(APP_VERSION)"

REM Python version
odysseus\venv\Scripts\python --version

REM Key package versions
odysseus\venv\Scripts\pip show fastapi chromadb sqlalchemy
```

### Upgrading Components

#### KKOS Minor Version Update (e.g., v5.2.0 → v5.2.1)

1. Check `src/kkos_v520_unified.cpp` for version string
2. Update version constant if needed
3. Recompile: `build-all-steps.bat`
4. Test: `bin/kkos_v520.exe`
5. Verify: `--version` flag shows new version

#### KKOS Major Version (e.g., v5.2 → v6.0)

1. Review `ROADMAP.md` for breaking changes
2. Update `config.json` if structure changed
3. Backup `odysseus/data/app.db`
4. Update compile targets in build scripts
5. Full recompilation and testing required

#### Odysseus Dependency Updates

**Patch Updates** (Safe):

```batch
cd odysseus
venv\Scripts\pip install --upgrade fastapi sqlalchemy
REM Update safe, non-breaking updates
```

**Major Updates** (Careful):

```batch
REM Check what changed:
venv\Scripts\pip index versions fastapi

REM Update specific version:
venv\Scripts\pip install fastapi==0.x.0

REM Test: venv\Scripts\python -c "import fastapi; print(fastapi.__version__)"
```

**Full Dependency Refresh** (Once per quarter):

```batch
cd odysseus
REM Save old versions
venv\Scripts\pip freeze > requirements-frozen-old.txt

REM Update all
venv\Scripts\pip install --upgrade -r requirements.txt

REM If breaks occur, revert:
venv\Scripts\pip install -r requirements-frozen-old.txt
```

---

## Monitoring & Diagnostics

### Performance Profiling

**KKOS CPU/Memory Profile**:

```batch
REM Use Windows built-in profiler:
wpr -start GeneralProfile
bin\kkos_v520.exe
REM Use DAW, then:
wpr -stop kkos_profile.etl
REM Open in Windows Performance Analyzer
```

**Odysseus Request Profiling**:

```bash
REM Add to odysseus/.env:
DEBUG=1
LOG_LEVEL=debug

REM Run with profiling:
odysseus\venv\Scripts\python -m cProfile -o odysseus_profile.stats odysseus\app.py
REM Analyze: odysseus\venv\Scripts\python -m pstats odysseus_profile.stats
```

### Log Analysis

**KKOS Logs**:

```batch
REM Real-time monitoring:
type logs\kkos_unified.log

REM Find errors:
findstr /I "ERROR CRASH FAIL" logs\kkos_unified.log

REM Last 50 lines:
powershell -Command "Get-Content logs\kkos_unified.log -Tail 50"
```

**Odysseus Logs**:

```batch
REM Check for startup issues:
type odysseus\logs\*

REM Monitor in real-time (Windows):
powershell -Command "Get-Content odysseus\logs\app.log -Wait"
```

### Health Check Script

```batch
REM health-check.bat
@echo off
echo Checking KKOS + Odysseus health...
echo.

REM Check files exist
if exist bin\kkos_v520.exe (
    echo [OK] KKOS executable exists
) else (
    echo [FAIL] KKOS executable missing
)

if exist odysseus\venv\Scripts\python.exe (
    echo [OK] Odysseus venv exists
) else (
    echo [FAIL] Odysseus venv missing
)

if exist odysseus\data\app.db (
    echo [OK] Odysseus database exists
) else (
    echo [FAIL] Odysseus database missing
)

REM Test port availability
netstat -ano | findstr :7000 > nul
if %ERRORLEVEL% equ 0 (
    echo [WARN] Port 7000 in use (service may be running)
) else (
    echo [OK] Port 7000 available
)

echo.
echo Health check complete.
```

---

## Maintenance Schedule

### Weekly

- [ ] Monitor `logs/` for errors
- [ ] Verify both services start cleanly
- [ ] Check disk space (minimum 500MB free)

### Monthly

- [ ] Update non-breaking dependencies
- [ ] Run `health-check.bat`
- [ ] Backup `odysseus/data/app.db`
- [ ] Review performance logs

### Quarterly

- [ ] Full dependency upgrade check
- [ ] KKOS performance profiling
- [ ] Database maintenance (VACUUM)
- [ ] Security updates for system packages

### Annually

- [ ] Plan major version upgrades
- [ ] Review architecture for modernization
- [ ] Evaluate sub-project integration
- [ ] Update documentation

---

## Troubleshooting Common Issues

### Issue: Slow Compilation

**Causes**: Insufficient RAM, background tasks, SSD fragmentation

**Solutions**:

```batch
REM Check RAM
systeminfo | findstr Memory

REM Free RAM
taskkill /F /IM *.exe  (dangerous - be selective!)

REM Use lower optimization:
REM Edit build-all-steps.bat: change -O3 to -O2
```

### Issue: High Memory Usage During Runtime

**Causes**: ChromaDB vector store growing, memory leak

**Solutions**:

```batch
REM Reduce vector store:
odysseus\venv\Scripts\python -c "from src.chroma_client import get_chroma_client; get_chroma_client().reset()"

REM Clear temporary files:
rmdir /s /q odysseus\data\generated_images odysseus\data\tts_cache

REM Restart services
```

### Issue: Port 7000 Already in Use

**Causes**: Previous Odysseus instance still running, other service using port

**Solutions**:

```batch
REM Find process using port 7000
netstat -ano | findstr :7000
REM Note the PID, then:
taskkill /PID <PID> /F

REM Or use different port:
REM Edit start-all.bat: change --port 7000 to --port 8000
```

### Issue: Python Dependency Conflict

**Causes**: Version mismatch, broken package

**Solutions**:

```batch
REM Reinstall from scratch:
rmdir /s /q odysseus\venv
C:\msys64\mysys64_new\ucrt64\bin\python.exe -m venv odysseus\venv
odysseus\venv\Scripts\pip install -r odysseus\requirements.txt

REM Or pin specific versions:
REM Edit odysseus/requirements.txt: change "fastapi" to "fastapi==0.x.0"
```

---

## Performance Benchmarks

### Target Performance (i5-13420H Raptor Lake)

- **KKOS Startup**: < 2 seconds
- **DAW Playback**: 0 dropouts at 48kHz/24-bit
- **Odysseus Startup**: < 5 seconds
- **API Response**: < 100ms for typical requests
- **Vector Search**: < 500ms for full corpus

### Measuring Performance

```batch
REM KKOS startup time:
powershell -Command "Measure-Command { & bin\kkos_v520.exe --version }"

REM Odysseus API latency:
REM (Requires curl or PowerShell)
powershell -Command "Measure-Command { Invoke-WebRequest http://127.0.0.1:7000/api/version }"

REM Build time:
REM Add to start of build-all-steps.bat:
REM set START_TIME=%time%
REM Add to end:
REM echo Build time: %time% - %START_TIME%
```

---

## Advanced Configuration

### Custom KKOS Config

Edit `config.json`:

```json
{
  "baseSynchronization": 0.95,
  "baseStability": 0.90,
  "shardCount": 16,
  "telemetryHz": 60,
  "maxSnapshotCache": 200
}
```

### Custom Odysseus Config

Edit or create `odysseus/.env`:

```bash
DEBUG=0
LOG_LEVEL=info
DATABASE_URL=sqlite:///data/app.db
AUTH_ENABLED=true
SESSION_TIMEOUT=3600
MAX_UPLOAD_SIZE=104857600
```

### Custom Build Flags

Edit `build-all-steps.bat`, find the g++ line, modify:

```batch
REM Example: Enable more aggressive optimization
set "FLAGS=-std=c++17 -O3 -flto -march=native -mtune=native -funroll-loops -fvectorize-loops"
```

---

## Deployment Considerations

### Packaging for Distribution

1. Build with `-O3 -flto` for optimal size/speed
2. Test on clean system
3. Create installer wrapper (optional)
4. Document system requirements

### Containerization (Docker)

```dockerfile
FROM microsoft/windows:ltsc2022
COPY KKOS_v5.2_Unified_Bundle/ /app/
RUN cd /app && build-all-steps.bat
EXPOSE 7000
CMD ["start-all.bat"]
```

### CI/CD Integration

```yaml
build:
  script: |
    build-all-steps.bat
    bin\kkos_v520.exe --version
    odysseus\venv\Scripts\python -m pytest
  artifacts:
    - bin/kkos_v520.exe
    - odysseus/venv/
```

---

**Last Updated**: 2026-06-23
**Maintenance Mode**: Active
**Support Level**: Community-driven
