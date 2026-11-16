@echo off
setlocal
title Update Odysseus Docker Deployment

pushd "%~dp0" >nul

echo =========================================
echo Updating Odysseus Docker deployment
echo =========================================
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo [!] Git was not found on PATH.
  echo     Install Git for Windows, then run this script again.
  goto :fail
)

where docker >nul 2>nul
if errorlevel 1 (
  echo [!] Docker was not found on PATH.
  echo     Start Docker Desktop, then run this script again.
  goto :fail
)

docker compose version >nul 2>nul
if errorlevel 1 (
  echo [!] Docker Compose is not available.
  echo     Update Docker Desktop, then run this script again.
  goto :fail
)

echo [+] Navigating to application directory...
if exist "odysseus-dev\odysseus-dev" (
    cd odysseus-dev\odysseus-dev
) else (
    echo [!] Application directory not found.
)

if not exist ".git" (
    echo [!] Not a git repository. Skipping git pull.
) else (
    echo [+] Pulling latest code...
    git pull --ff-only
    if errorlevel 1 goto :fail
)

if not exist "docker-compose.yml" if not exist "compose.yaml" (
    echo [!] Docker compose file not found in %cd%
    goto :fail
)

echo.
echo [+] Rebuilding and restarting containers...
docker compose up -d --build
if errorlevel 1 goto :fail

echo.
echo [+] Removing dangling Docker images...
docker image prune -f
if errorlevel 1 goto :fail

echo.
echo =========================================
echo Update completed successfully.
echo =========================================
goto :done

:fail
echo.
echo Update failed. Check the message above and try again.

:done
popd >nul
pause
