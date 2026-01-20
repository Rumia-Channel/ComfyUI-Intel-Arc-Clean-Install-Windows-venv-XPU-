@echo off
setlocal EnableDelayedExpansion EnableExtensions
title Repair/Update PyTorch XPU Nightly

REM ============================================
REM Parse command line arguments
REM ============================================
set "INSTALL_DIR=%~1"
if "%INSTALL_DIR%"=="" set "INSTALL_DIR=%INSTALL_DIR%"

REM Remove trailing backslash if present
if "%INSTALL_DIR:~-1%"=="\" set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

echo ================================================================
echo PyTorch XPU Nightly - Repair/Update Tool
echo ================================================================
echo.
echo Installation directory: %INSTALL_DIR%
echo.
echo This script will:
echo   1. Remove ALL existing PyTorch packages
echo   2. Clean pip cache
echo   3. Install latest PyTorch XPU Nightly build
echo   4. Verify XPU device detection
echo.
echo WARNING: This will uninstall all current PyTorch versions!
echo.
echo Usage: %~nx0 [install_path]
echo   Default: %INSTALL_DIR%
echo   Example: %~nx0 D:\AI\ComfyUI
echo.
pause

if not exist "%INSTALL_DIR%" (
    echo ERROR: ComfyUI directory not found!
    echo Run INSTALL_ComfyUI_Intel_Arc_XPU.bat first.
    pause
    goto :error
)

cd /d %INSTALL_DIR%
if errorlevel 1 (
    echo ERROR: Failed to change to ComfyUI directory
    pause
    goto :error
)

if not exist "comfyui_venv" (
    echo ERROR: Virtual environment not found!
    echo Run INSTALL_ComfyUI_Intel_Arc_XPU.bat first.
    pause
    goto :error
)

if not exist "comfyui_venv\Scripts\activate.bat" (
    echo ERROR: Virtual environment activation script not found!
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
REM Step 1: Remove ALL PyTorch packages
REM ============================================
echo.
echo [1/5] Removing all PyTorch packages...
echo This may take a moment...

pip uninstall -y torch torchvision torchaudio
pip uninstall -y intel-extension-for-pytorch
pip uninstall -y pytorch-triton
pip uninstall -y pytorch-triton-xpu
pip uninstall -y triton

echo.
echo [CHECK] Verifying PyTorch removal...
python -c "try: import torch; print('WARNING: PyTorch still found'); except ImportError: print('OK: PyTorch removed')"

REM ============================================
REM Step 2: Clean pip cache
REM ============================================
echo.
echo [2/5] Cleaning pip cache...

pip cache purge

REM ============================================
REM Step 3: Upgrade pip
REM ============================================
echo.
echo [3/5] Upgrading pip to latest version...

python -m pip install --upgrade pip

REM ============================================
REM Step 4: Install PyTorch XPU Nightly
REM ============================================
echo.
echo [4/5] Installing PyTorch XPU Nightly (latest)...
echo This may take 5-10 minutes depending on your connection...
echo.

set "PYTORCH_SUCCESS=0"
for /L %%i in (1,1,2) do (
    if "!PYTORCH_SUCCESS!"=="0" (
        echo Installation attempt %%i of 2...
        pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/xpu
        if not errorlevel 1 (
            python -c "import torch" 2>nul
            if not errorlevel 1 set "PYTORCH_SUCCESS=1"
        )
        if "!PYTORCH_SUCCESS!"=="0" (
            if %%i LSS 2 (
                echo Retrying in 10 seconds...
                timeout /t 10 /nobreak >nul 2>&1
            )
        )
    )
)

if "!PYTORCH_SUCCESS!"=="0" (
    echo.
    echo ERROR: PyTorch installation failed after 2 attempts!
    echo.
    echo Troubleshooting:
    echo   1. Check your internet connection
    echo   2. Try again later (nightly builds may be updating)
    echo   3. Visit: https://download.pytorch.org/whl/nightly/xpu/
    echo.
    pause
    goto :error
)

echo.
echo [4.5/5] Installing Triton XPU...

echo Attempting to install pytorch-triton-xpu...
pip install pytorch-triton-xpu 2>nul

if errorlevel 1 (
    echo NOTE: pytorch-triton-xpu not available in current PyTorch nightly
    echo Triton kernels will be compiled on first use if available
    echo This is normal and not an error
)

REM ============================================
REM Step 5: Verify Installation
REM ============================================
echo.
echo [5/5] Verifying PyTorch XPU installation...
echo.

python -c "import torch; print('='*60); print('PyTorch Version:', torch.__version__); print('='*60); print(''); import sys; sys.stdout.flush()" 2>nul

python -c "import torch; xpu_available = hasattr(torch, 'xpu') and torch.xpu.is_available(); print('XPU Available:', xpu_available); import sys; sys.stdout.flush()" 2>nul

python -c "import torch; print(''); if hasattr(torch, 'xpu') and torch.xpu.is_available(): print('GPU Device:', torch.xpu.get_device_name(0)); print('GPU Count:', torch.xpu.device_count()); else: print('WARNING: XPU not detected!'); import sys; sys.stdout.flush()" 2>nul

echo.
python -c "try: import triton; print('Triton Version:', triton.__version__); except: print('Triton: Not available')"

echo.
echo ================================================================

python -c "import torch; import sys; xpu_ok = hasattr(torch, 'xpu') and torch.xpu.is_available(); sys.exit(0 if xpu_ok else 1)" 2>nul

if errorlevel 1 (
    echo.
    echo ================================================================
    echo WARNING: XPU Not Detected!
    echo ================================================================
    echo.
    echo Possible causes:
    echo   1. Intel Arc drivers not installed or outdated
    echo   2. Incompatible GPU (not Intel Arc or Core Ultra)
    echo   3. PyTorch XPU build not compatible with your system
    echo.
    echo Solutions:
    echo   1. Update Intel Graphics drivers:
    echo      https://www.intel.com/content/www/us/en/download/785597/
    echo   2. Restart your PC
    echo   3. Try again after driver update
    echo.
    echo Your GPU:
    wmic path win32_VideoController get name
    echo.
    pause
) else (
    echo.
    echo ================================================================
    echo SUCCESS! PyTorch XPU is working correctly
    echo ================================================================
    echo.
    echo You can now run START_ComfyUI.bat to launch ComfyUI
    echo.
    echo If using GGUF models, run INSTALL_GGUF_Triton_Patch.bat
    echo for additional acceleration.
    echo.
    pause
)

REM Deactivate virtual environment before exit
if defined VIRTUAL_ENV (
    call deactivate 2>nul
)

endlocal
exit /b 0

:error
REM Deactivate virtual environment before exit
if defined VIRTUAL_ENV (
    call deactivate 2>nul
)

echo.
echo ================================================================
echo PyTorch XPU Repair Failed!
echo ================================================================
echo.
echo Please review the error messages above.
echo.
echo Common solutions:
echo   1. Check your internet connection
echo   2. Run as Administrator
echo   3. Ensure %INSTALL_DIR% exists and was set up correctly
echo.
pause
endlocal
exit /b 1
