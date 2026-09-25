@echo off
setlocal
set "INSTALL_DIR=%~1"
if not defined INSTALL_DIR set "INSTALL_DIR=C:\ComfyUI"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0ComfyUI-XPU.ps1" -Mode Update -InstallPath "%INSTALL_DIR%"
set "RESULT=%ERRORLEVEL%"
if not "%RESULT%"=="0" pause
endlocal & exit /b %RESULT%
