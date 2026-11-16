@echo off
setlocal
set SCRIPT_DIR=%~dp0
set KKOS_EXE=%SCRIPT_DIR%bin\kkos_v520.exe
set ODY_PY=%SCRIPT_DIR%odysseus\venv\bin\python.exe
set ODY_PY_FALLBACK=%SCRIPT_DIR%odysseus\venv\Scripts\python.exe
set ODY_DIR=%SCRIPT_DIR%odysseus
set WEB_UI=%SCRIPT_DIR%web\index.html

if not exist "%KKOS_EXE%" (
    echo [ERROR] KKOS binary not found. Run BUILD.bat first.
    pause
    exit /b 1
)

if not exist "%ODY_PY%" (
    if exist "%ODY_PY_FALLBACK%" ( set ODY_PY=%ODY_PY_FALLBACK% ) else (
        echo [WARN] Odysseus venv not found; launching KKOS UI only.
    )
)

start "KKOS v5.2.0" "%KKOS_EXE%"
if exist "%WEB_UI%" (
    start "KKOS UI" "%WEB_UI%"
)

if exist "%ODY_PY%" (
    echo [INFO] Starting Odysseus UI backend on http://127.0.0.1:7000
    "%ODY_PY%" -m uvicorn app:app --host 127.0.0.1 --port 7000 --app-dir "%ODY_DIR%"
) else (
    echo [INFO] KKOS desktop launcher ready. Open the web UI manually if needed.
)

endlocal
