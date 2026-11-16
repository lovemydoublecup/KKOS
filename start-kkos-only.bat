@echo off
setlocal
set MSYS_BASE=C:\msys64\mysys64_new\ucrt64
set PATH=%MSYS_BASE%\bin;%PATH%
set KKOS_EXE=%~dp0bin\kkos_v520.exe
if not exist "%KKOS_EXE%" ( echo [ERROR] Build first with BUILD.bat & pause & exit /b 1 )
"%KKOS_EXE%"
endlocal
