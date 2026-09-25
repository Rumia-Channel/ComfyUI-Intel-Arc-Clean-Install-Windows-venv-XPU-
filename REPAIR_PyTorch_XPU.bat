@echo off
setlocal
rem If omitted, Install asks; other commands load .comfyui-install-path via ComfyUI-XPU.ps1.
set "INSTALL_DIR=%~1"
if defined INSTALL_DIR (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0ComfyUI-XPU.ps1" -Mode Repair -InstallPath "%INSTALL_DIR%"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0ComfyUI-XPU.ps1" -Mode Repair
)
set "RESULT=%ERRORLEVEL%"
if not "%RESULT%"=="0" pause
endlocal & exit /b %RESULT%
