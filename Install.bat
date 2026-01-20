@echo off
setlocal EnableDelayedExpansion EnableExtensions
title ComfyUI Complete Installation

REM ============================================
REM Parse command line arguments
REM ============================================
set "INSTALL_DIR=%~1"
if "%INSTALL_DIR%"=="" set "INSTALL_DIR=C:\ComfyUI"

REM Remove trailing backslash if present
if "%INSTALL_DIR:~-1%"=="\" set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
REM Remove trailing backslash
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

echo ================================================================
echo ComfyUI Complete Installation Script
echo ================================================================
echo.
echo This script will sequentially run:
echo   1. INSTALL_ComfyUI_Intel_Arc_XPU.bat
echo   2. INSTALL_Custom_Nodes.bat
echo   3. INSTALL_GGUF_Triton_Patch.bat
echo.
echo Installation directory: %INSTALL_DIR%
echo Script directory: %SCRIPT_DIR%
echo.
echo Usage: %~nx0 [install_path]
echo   Default: C:\ComfyUI
echo   Example: %~nx0 D:\AI\ComfyUI
echo.
echo Press Ctrl+C to cancel, or
pause

REM ============================================
REM Step 1: Install ComfyUI
REM ============================================
echo.
echo ================================================================
echo Step 1/3: Installing ComfyUI Intel Arc XPU
echo ================================================================
echo.

cd /d "%SCRIPT_DIR%"
if errorlevel 1 (
    echo ERROR: Failed to change to script directory
    pause
    goto :error
)

call "%SCRIPT_DIR%\INSTALL_ComfyUI_Intel_Arc_XPU.bat" "%INSTALL_DIR%"
if errorlevel 1 (
    echo.
    echo ERROR: ComfyUI installation failed!
    echo Please check the error messages above.
    pause
    goto :error
)

REM ============================================
REM Step 2: Install Custom Nodes
REM ============================================
echo.
echo ================================================================
echo Step 2/3: Installing Custom Nodes
echo ================================================================
echo.

cd /d "%SCRIPT_DIR%"
if errorlevel 1 (
    echo ERROR: Failed to change to script directory
    pause
    goto :error
)

call "%SCRIPT_DIR%\INSTALL_Custom_Nodes.bat" "%INSTALL_DIR%"
if errorlevel 1 (
    echo.
    echo WARNING: Custom nodes installation had errors
    echo Continuing with GGUF Triton patch...
    timeout /t 5 /nobreak >nul 2>&1
)

REM ============================================
REM Step 3: Install GGUF Triton Patch
REM ============================================
echo.
echo ================================================================
echo Step 3/3: Installing GGUF Triton Patch
echo ================================================================
echo.

cd /d "%SCRIPT_DIR%"
if errorlevel 1 (
    echo ERROR: Failed to change to script directory
    pause
    goto :error
)

call "%SCRIPT_DIR%\INSTALL_GGUF_Triton_Patch.bat" "%INSTALL_DIR%"
if errorlevel 1 (
    echo.
    echo WARNING: GGUF Triton patch installation had errors
    echo You may need to run it manually later
    timeout /t 5 /nobreak >nul 2>&1
)

REM ============================================
REM Installation Complete
REM ============================================
echo.
echo.
echo ================================================================
echo Installation Complete!
echo ================================================================
echo.
echo Installation directory: %INSTALL_DIR%
echo.
echo Next steps:
echo   1. Copy your models to: %INSTALL_DIR%\models\checkpoints\
echo   2. Run START_ComfyUI.bat "%INSTALL_DIR%" to launch ComfyUI
echo.
echo ================================================================
echo.
pause
endlocal
exit /b 0

:error
echo.
echo ================================================================
echo Installation Failed!
echo ================================================================
echo.
echo The installation process encountered an error.
echo Please review the error messages above and try again.
echo.
echo You can also run the scripts individually:
echo   1. INSTALL_ComfyUI_Intel_Arc_XPU.bat "%INSTALL_DIR%"
echo   2. INSTALL_Custom_Nodes.bat "%INSTALL_DIR%"
echo   3. INSTALL_GGUF_Triton_Patch.bat "%INSTALL_DIR%"
echo.
pause
endlocal
exit /b 1
