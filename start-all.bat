@echo off
setlocal
set MSYS_BASE=C:\msys64\mysys64_new\ucrt64
set PATH=%MSYS_BASE%\bin;%PATH%
set PROJECT_DIR=%~dp0
set KKOS_EXE=%PROJECT_DIR%bin\kkos_v520.exe
set ODY_PY=%PROJECT_DIR%odysseus\venv\Scripts\python.exe
set ODY_PY_FALLBACK=%PROJECT_DIR%odysseus\venv\bin\python.exe
set ODY_DIR=%PROJECT_DIR%odysseus

if not exist "%KKOS_EXE%" (
    echo [ERROR] KKOS executable not found. Run BUILD.bat first.
    pause & exit /b 1
)
if not exist "%ODY_PY%" (
    if exist "%ODY_PY_FALLBACK%" ( set ODY_PY=%ODY_PY_FALLBACK% ) else (
        echo [ERROR] Odysseus not set up. Run BUILD.bat first.
        pause & exit /b 1
    )
)
echo.
echo ================================================
echo  KKOS v5.2.0 + Odysseus
echo  Odysseus: http://127.0.0.1:7000
echo ================================================
echo.
start "KKOS v5.2.0" "%KKOS_EXE%"
"%ODY_PY%" -m uvicorn app:app --host 127.0.0.1 --port 7000 --app-dir "%ODY_DIR%"
endlocal
