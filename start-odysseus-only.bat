@echo off
setlocal
set ODY_PY=%~dp0odysseus\venv\Scripts\python.exe
set ODY_PY_FALLBACK=%~dp0odysseus\venv\bin\python.exe
set ODY_DIR=%~dp0odysseus
if not exist "%ODY_PY%" (
    if exist "%ODY_PY_FALLBACK%" ( set ODY_PY=%ODY_PY_FALLBACK% ) else (
        echo [ERROR] Run BUILD.bat first. & pause & exit /b 1
    )
)
"%ODY_PY%" -m uvicorn app:app --host 127.0.0.1 --port 7000 --app-dir "%ODY_DIR%"
endlocal
