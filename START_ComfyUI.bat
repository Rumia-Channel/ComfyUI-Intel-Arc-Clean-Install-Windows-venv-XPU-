@echo off
setlocal EnableDelayedExpansion EnableExtensions
title ComfyUI - Intel Arc XPU with Triton Optimization

REM ============================================
REM Initialize C++ Compiler for Triton
REM ============================================
echo ================================================================
echo Initializing ComfyUI with Intel Arc XPU
echo ================================================================

set "MSVC_FOUND=0"
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    set "MSVC_FOUND=1"
    set "VCVARS_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
)
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    set "MSVC_FOUND=1"
    set "VCVARS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
)

if "%MSVC_FOUND%"=="1" (
    echo [COMPILER] Loading C++ environment for Triton...
    call "%VCVARS_PATH%" >nul 2>&1
    echo OK: C++ compiler loaded
) else (
    echo [WARNING] C++ compiler not found - Triton may not work
    echo Install Visual Studio Build Tools for GGUF acceleration
)

REM ============================================
REM Intel XPU Environment Variables
REM ============================================
set SYCL_CACHE_PERSISTENT=1
set SYCL_CACHE_DIR=C:\ComfyUI\sycl_cache
set SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1
set ONEAPI_DEVICE_SELECTOR=level_zero:gpu
set SYCL_DEVICE_FILTER=level_zero:gpu

if not exist "C:\ComfyUI\sycl_cache" mkdir "C:\ComfyUI\sycl_cache"

echo [XPU] Intel Arc GPU acceleration enabled
echo.

REM ============================================
REM Launch ComfyUI
REM ============================================
if not exist "C:\ComfyUI" (
    echo ERROR: ComfyUI directory not found!
    echo Please run INSTALL_ComfyUI_Intel_Arc_XPU.bat first
    pause
    goto :error
)

cd /d C:\ComfyUI
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

echo [INFO] Starting ComfyUI...
echo [INFO] GGUF Triton optimization: Active
echo [INFO] First GGUF load will compile kernels (~10-30 sec)
echo [INFO] Access UI: http://127.0.0.1:8188
echo.

if not exist "main.py" (
    echo ERROR: main.py not found!
    echo ComfyUI may not be properly installed.
    pause
    goto :error
)

python main.py ^
--lowvram ^
--bf16-unet ^
--async-offload ^
--disable-smart-memory ^
--preview-method auto ^
--output-directory "%USERPROFILE%\Documents\AI-Playground\media" ^
--front-end-version "Comfy-Org/ComfyUI_frontend@latest"

if errorlevel 1 (
    echo.
    echo ComfyUI exited with an error
    pause
    goto :error
)

pause
endlocal
exit /b 0

:error
echo.
echo ================================================================
echo Failed to Start ComfyUI!
echo ================================================================
echo.
echo Please review the error messages above.
echo Make sure you have completed the installation steps.
echo.
pause
endlocal
exit /b 1
