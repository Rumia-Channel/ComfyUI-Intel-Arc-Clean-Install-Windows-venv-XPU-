@echo off
setlocal EnableDelayedExpansion EnableExtensions
title Installing GGUF Triton Patch

REM ============================================
REM Parse command line arguments
REM ============================================
set "INSTALL_DIR=%~1"
if "%INSTALL_DIR%"=="" set "INSTALL_DIR=%INSTALL_DIR%"

REM Remove trailing backslash if present
if "%INSTALL_DIR:~-1%"=="\" set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

echo ================================================================
echo GGUF Triton Optimization Patch Installer
echo ================================================================
echo.
echo Installation directory: %INSTALL_DIR%
echo.
echo This will apply Triton acceleration to GGUF models:
echo   - Q4_0: ~11x faster dequantization
echo   - Q4_1: ~8x faster dequantization
echo   - Q8_0: ~6x faster dequantization
echo.
echo Usage: %~nx0 [install_path]
echo   Default: %INSTALL_DIR%
echo   Example: %~nx0 D:\AI\ComfyUI
echo.
pause

if not exist "%INSTALL_DIR%" (
    echo ERROR: ComfyUI directory not found!
    echo Please run INSTALL_ComfyUI_Intel_Arc_XPU.bat first
    pause
    goto :error
)

cd /d %INSTALL_DIR%
if errorlevel 1 (
    echo ERROR: Failed to change to ComfyUI directory
    pause
    goto :error
)

if not exist "comfyui_venv\Scripts\activate.bat" (
    echo ERROR: Virtual environment not found!
    echo Please run INSTALL_ComfyUI_Intel_Arc_XPU.bat first
    pause
    goto :error
)

call "comfyui_venv\Scripts\activate.bat"
if errorlevel 1 (
    echo ERROR: Failed to activate virtual environment
    pause
    goto :error
)

REM ============================================
REM Check if GGUF node exists
REM ============================================
echo.
echo [CHECK] Verifying ComfyUI-GGUF installation...

if not exist "custom_nodes\ComfyUI-GGUF" (
    echo ERROR: ComfyUI-GGUF not found!
    echo Run INSTALL_Custom_Nodes.bat first.
    pause
    goto :error
)

echo OK: ComfyUI-GGUF found

REM ============================================
REM Download patch from GitHub
REM ============================================
echo.
echo [DOWNLOAD] Fetching latest Triton patch...

powershell -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ai-joe-git/ComfyUI-Intel-Arc-Clean-Install-Windows-venv-XPU-/main/patches/comfyui_gguf_xpu.patch' -OutFile 'comfyui_gguf_xpu.patch'}" 2>nul

if not exist "comfyui_gguf_xpu.patch" (
    echo WARNING: Could not download patch automatically
    echo Retrying with alternative method...

    REM Retry with curl if available
    curl -L -o comfyui_gguf_xpu.patch "https://raw.githubusercontent.com/ai-joe-git/ComfyUI-Intel-Arc-Clean-Install-Windows-venv-XPU-/main/patches/comfyui_gguf_xpu.patch" 2>nul

    if not exist "comfyui_gguf_xpu.patch" (
        echo.
        echo ERROR: Could not download patch automatically
        echo.
        echo Please download manually:
        echo https://github.com/ai-joe-git/ComfyUI-Intel-Arc-Clean-Install-Windows-venv-XPU-/blob/main/patches/comfyui_gguf_xpu.patch
        echo.
        echo Place it in: %INSTALL_DIR%\comfyui_gguf_xpu.patch
        echo Then run this script again.
        pause
        goto :error
    )
)

echo OK: Patch file downloaded

REM ============================================
REM Apply patch
REM ============================================
echo.
echo [PATCH] Applying Triton optimization...

cd custom_nodes\ComfyUI-GGUF

REM Check if already applied
git apply --reverse --check ..\..\comfyui_gguf_xpu.patch >nul 2>&1
if not errorlevel 1 (
    echo Patch already applied. Skipping...
    goto :verify
)

REM Apply patch
git apply --whitespace=fix ..\..\comfyui_gguf_xpu.patch
if errorlevel 1 (
    echo.
    echo WARNING: Patch may not have applied cleanly
    echo This is usually safe - checking for Triton code...
    
    findstr /C:"HAS_TRITON" dequant.py >nul 2>&1
    if errorlevel 1 (
        echo ERROR: Triton code not found in dequant.py
        echo Manual patch may be required
        pause
        goto :error
    )
)

echo OK: Patch applied successfully

:verify
REM ============================================
REM Verify installation
REM ============================================
echo.
echo [VERIFY] Checking Triton integration...

cd ..\..
python -c "from custom_nodes.ComfyUI-GGUF.dequant import HAS_TRITON, USE_TRITON_KERNELS; print('HAS_TRITON:', HAS_TRITON); print('USE_TRITON_KERNELS:', USE_TRITON_KERNELS); exit(0 if HAS_TRITON and USE_TRITON_KERNELS else 1)"

if errorlevel 1 (
    echo.
    echo WARNING: Triton kernels not enabled
    echo Check that pytorch-triton-xpu is installed correctly
    pause
) else (
    echo OK: Triton kernels enabled!
)

echo.
echo ================================================================
echo GGUF Triton Patch Installation Complete!
echo ================================================================
echo.
echo Performance improvements:
echo   - Q4_0 models: ~11x faster
echo   - Q8_0 models: ~6x faster
echo   - First load will compile kernels (~10-30 seconds)
echo   - Subsequent loads use cached kernels
echo.
echo Next: Run START_ComfyUI.bat to launch with optimizations!
echo ================================================================

REM Deactivate virtual environment before exit
if defined VIRTUAL_ENV (
    call deactivate 2>nul
)

pause
endlocal
exit /b 0

:error
REM Deactivate virtual environment before exit
if defined VIRTUAL_ENV (
    call deactivate 2>nul
)

echo.
echo ================================================================
echo GGUF Triton Patch Installation Failed!
echo ================================================================
echo.
echo Please review the error messages above.
echo Make sure you have run the previous installation scripts.
echo.
pause
endlocal
exit /b 1
