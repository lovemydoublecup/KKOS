@echo off
setlocal
cd /d "%~dp0.."
echo [cwd] %CD%
where g++.exe > tmp\where_gpp.txt 2>&1
C:\msys64\mysys64_new\ucrt64\bin\g++.exe --version > tmp\gpp_version.txt 2>&1
C:\msys64\mysys64_new\ucrt64\bin\g++.exe -std=c++17 tmp\compiler_probe.cpp -o tmp\compiler_probe.exe > tmp\compile_probe.log 2>&1
set EXITCODE=%ERRORLEVEL%
echo [exit] %EXITCODE%
if exist tmp\compile_probe.log type tmp\compile_probe.log
if exist tmp\gpp_version.txt echo. & echo [gpp_version] & type tmp\gpp_version.txt
if exist tmp\where_gpp.txt echo. & echo [where_gpp] & type tmp\where_gpp.txt
endlocal
