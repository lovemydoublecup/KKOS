@echo off
setlocal
title KKOS v5.2.0 — Update Odysseus Docker Deployment

pushd "%~dp0" >nul

echo.
echo ============================================
echo  KKOS v5.2.0 — Odysseus Docker Update
echo ============================================
echo.

where git >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Git not found on PATH.
    echo         Install Git for Windows, then re-run.
    goto :fail
)
where docker >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Docker not found on PATH.
    echo         Start Docker Desktop, then re-run.
    goto :fail
)
docker compose version >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Docker Compose not available.
    echo         Update Docker Desktop, then re-run.
    goto :fail
)

echo [+] Locating application directory...
if exist "odysseus-dev\odysseus-dev" (
    cd odysseus-dev\odysseus-dev
) else if exist "odysseus" (
    cd odysseus
) else (
    echo [INFO] Running from project root.
)

if exist ".git" (
    echo [+] Pulling latest code...
    git pull --ff-only
    if errorlevel 1 goto :fail
) else (
    echo [INFO] Not a git repo — skipping pull.
)

if not exist "docker-compose.yml" if not exist "compose.yaml" (
    echo [ERROR] No docker-compose.yml found in %cd%
    goto :fail
)

echo.
echo [+] Rebuilding and restarting containers...
docker compose up -d --build
if errorlevel 1 goto :fail

echo.
echo [+] Pruning dangling images...
docker image prune -f

echo.
echo ============================================
echo  Update complete.
echo ============================================
goto :done

:fail
echo.
echo [FAIL] Update did not complete — check messages above.

:done
popd >nul
pause
