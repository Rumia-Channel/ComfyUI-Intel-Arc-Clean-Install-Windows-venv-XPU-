@echo off
setlocal EnableDelayedExpansion EnableExtensions
title Updating ComfyUI

REM ============================================
REM Parse command line arguments
REM ============================================
set "INSTALL_DIR=%~1"
if "%INSTALL_DIR%"=="" set "INSTALL_DIR=%INSTALL_DIR%"

REM Remove trailing backslash if present
if "%INSTALL_DIR:~-1%"=="\" set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

echo ================================================================
echo ComfyUI Update Script
echo ================================================================
echo.
echo Installation directory: %INSTALL_DIR%
echo.
echo This will update:
echo   - ComfyUI core
echo   - PyTorch XPU Nightly
echo   - Triton XPU
echo   - Custom nodes
echo   - Python dependencies
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

echo.
echo [1/5] Updating ComfyUI core...
git pull
if errorlevel 1 (
    echo WARNING: Git pull failed - may have local changes
)

echo.
echo [2/5] Updating PyTorch XPU Nightly...
pip install --upgrade --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/xpu

echo.
echo [3/5] Updating Triton XPU...
pip install --upgrade pytorch-triton-xpu

echo.
echo [4/5] Updating Python dependencies...
pip install --upgrade pip
pip install -r requirements.txt

echo.
echo [5/5] Updating custom nodes...
if exist "custom_nodes" (
    cd custom_nodes
    if errorlevel 1 (
        echo WARNING: Failed to enter custom_nodes directory
    ) else (
        for /d %%i in (*) do (
            if exist "%%i\.git" (
                echo Updating %%i...
                cd "%%i"
                if not errorlevel 1 (
                    git pull
                    if exist "requirements.txt" (
                        echo Installing requirements for %%i...
                        pip install -r requirements.txt
                    )
                    cd ..
                ) else (
                    echo WARNING: Failed to enter %%i directory
                )
            )
        )
        cd ..
    )
) else (
    echo No custom nodes directory found, skipping...
)

echo.
echo ================================================================
echo Update Complete!
echo ================================================================
echo.
echo Verifying PyTorch XPU...
python -c "import torch; print('PyTorch:', torch.__version__); print('XPU:', torch.xpu.is_available() if hasattr(torch, 'xpu') else False)"
echo.
echo Run START_ComfyUI.bat to launch
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
echo Update Failed!
echo ================================================================
echo.
echo Please review the error messages above.
echo Make sure ComfyUI is properly installed first.
echo.
pause
endlocal
exit /b 1
