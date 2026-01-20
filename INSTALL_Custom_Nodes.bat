@echo off
setlocal EnableDelayedExpansion EnableExtensions
title Installing ComfyUI Custom Nodes

REM ============================================
REM Parse command line arguments
REM ============================================
set "INSTALL_DIR=%~1"
if "%INSTALL_DIR%"=="" set "INSTALL_DIR=%INSTALL_DIR%"

REM Remove trailing backslash if present
if "%INSTALL_DIR:~-1%"=="\" set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

echo ================================================================
echo ComfyUI Custom Nodes Installer
echo ================================================================
echo.
echo Installation directory: %INSTALL_DIR%
echo.
echo This will install essential custom nodes:
echo   - ComfyUI-Manager (node management)
echo   - ComfyUI-GGUF (quantized models)
echo   - ComfyUI-VideoHelperSuite (video tools)
echo   - ComfyUI-Impact-Pack (utilities)
echo   - rgthree-comfy (workflow tools)
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

if not exist "%INSTALL_DIR%\custom_nodes" (
    echo Creating custom_nodes directory...
    mkdir "%INSTALL_DIR%\custom_nodes"
)

cd /d %INSTALL_DIR%\custom_nodes
if errorlevel 1 (
    echo ERROR: Failed to change to custom_nodes directory
    pause
    goto :error
)

if not exist "..\comfyui_venv\Scripts\activate.bat" (
    echo ERROR: Virtual environment not found!
    echo Please run INSTALL_ComfyUI_Intel_Arc_XPU.bat first
    pause
    goto :error
)

call "..\comfyui_venv\Scripts\activate.bat"
if errorlevel 1 (
    echo ERROR: Failed to activate virtual environment
    pause
    goto :error
)

echo.
echo [1/5] Installing ComfyUI-Manager...
if not exist "ComfyUI-Manager" (
    echo Cloning ComfyUI-Manager...
    git clone https://github.com/ltdrdata/ComfyUI-Manager
    if errorlevel 1 (
        echo WARNING: Failed to clone ComfyUI-Manager
        echo Continuing with other nodes...
    ) else (
        cd ComfyUI-Manager
        if exist requirements.txt (
            echo Installing requirements...
            pip install -r requirements.txt
        )
        cd ..
    )
) else (
    echo Already installed, updating...
    cd ComfyUI-Manager
    git pull
    if exist requirements.txt (
        echo Installing requirements...
        pip install -r requirements.txt
    )
    cd ..
)

echo.
echo [2/5] Installing ComfyUI-GGUF...
if not exist "ComfyUI-GGUF" (
    echo Cloning ComfyUI-GGUF...
    git clone https://github.com/city96/ComfyUI-GGUF
    if errorlevel 1 (
        echo WARNING: Failed to clone ComfyUI-GGUF
        echo Continuing with other nodes...
    )
) else (
    echo Already installed, updating...
    cd ComfyUI-GGUF
    git pull
    cd ..
)

echo.
echo [3/5] Installing ComfyUI-VideoHelperSuite...
if not exist "ComfyUI-VideoHelperSuite" (
    echo Cloning ComfyUI-VideoHelperSuite...
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
    if errorlevel 1 (
        echo WARNING: Failed to clone ComfyUI-VideoHelperSuite
        echo Continuing with other nodes...
    ) else (
        cd ComfyUI-VideoHelperSuite
        if exist requirements.txt (
            echo Installing requirements...
            pip install -r requirements.txt
        )
        cd ..
    )
) else (
    echo Already installed, updating...
    cd ComfyUI-VideoHelperSuite
    git pull
    if exist requirements.txt (
        echo Installing requirements...
        pip install -r requirements.txt
    )
    cd ..
)

echo.
echo [4/5] Installing ComfyUI-Impact-Pack...
if not exist "ComfyUI-Impact-Pack" (
    echo Cloning ComfyUI-Impact-Pack...
    git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack
    if errorlevel 1 (
        echo WARNING: Failed to clone ComfyUI-Impact-Pack
        echo Continuing with other nodes...
    ) else (
        cd ComfyUI-Impact-Pack
        if exist requirements.txt (
            echo Installing requirements...
            pip install -r requirements.txt
        )
        cd ..
    )
) else (
    echo Already installed, updating...
    cd ComfyUI-Impact-Pack
    git pull
    if exist requirements.txt (
        echo Installing requirements...
        pip install -r requirements.txt
    )
    cd ..
)

echo.
echo [5/5] Installing rgthree-comfy...
if not exist "rgthree-comfy" (
    echo Cloning rgthree-comfy...
    git clone https://github.com/rgthree/rgthree-comfy
    if errorlevel 1 (
        echo WARNING: Failed to clone rgthree-comfy
        echo Continuing...
    )
) else (
    echo Already installed, updating...
    cd rgthree-comfy
    git pull
    cd ..
)

echo.
echo ================================================================
echo Custom Nodes Installation Complete!
echo ================================================================
echo.
echo Next: Run INSTALL_GGUF_Triton_Patch.bat for GGUF acceleration
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
echo Custom Nodes Installation Failed!
echo ================================================================
echo.
echo Please review the error messages above.
echo Make sure you have run INSTALL_ComfyUI_Intel_Arc_XPU.bat first.
echo.
pause
endlocal
exit /b 1
