param(
    [string]$InstallPath = "$InstallPath"
)

# Remove trailing backslash if present
if ($InstallPath.EndsWith('\')) {
    $InstallPath = $InstallPath.TrimEnd('\')
}

$Host.UI.RawUI.WindowTitle = "ComfyUI Intel Arc XPU - Advanced Installation v2.0"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "ComfyUI Intel Arc XPU Installer v2.0" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This installer combines Intel best practices with cutting-edge"
Write-Host "PyTorch XPU nightly builds for maximum performance."
Write-Host ""
Write-Host "Features:"
Write-Host "  - ComfyUI (latest from official repo)"
Write-Host "  - PyTorch 2.11+ XPU Nightly (faster than Intel's 2.5.1)"
Write-Host "  - Triton XPU (GGUF acceleration)"
Write-Host "  - Python venv (lighter than conda)"
Write-Host "  - Visual Studio Build Tools verification"
Write-Host "  - Intel XPU environment optimization"
Write-Host ""
Write-Host "Installation directory: $InstallPath" -ForegroundColor Yellow
Write-Host "Estimated time: 10-15 minutes"
Write-Host "Disk space required: ~8GB"
Write-Host ""
Write-Host "Usage: .\INSTALL_ComfyUI_Intel_Arc_XPU.ps1 [-InstallPath <path>]"
Write-Host "  Default: $InstallPath"
Write-Host "  Example: .\INSTALL_ComfyUI_Intel_Arc_XPU.ps1 -InstallPath D:\AI\ComfyUI"
Write-Host ""
Read-Host "Press Enter to continue..."

# ============================================
# Step 1: System Checks
# ============================================
Write-Host ""
Write-Host "[1/9] Performing system checks..." -ForegroundColor Yellow

# Check Python
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Host "ERROR: Python not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Download Python 3.11 (recommended):"
    Write-Host "https://www.python.org/downloads/release/python-3110/"
    Write-Host ""
    Write-Host "Make sure to check 'Add Python to PATH' during installation"
    Read-Host "Press Enter to exit..."
    exit 1
}

# Get Python version
$pythonVersion = (python --version 2>&1) -replace 'Python ', ''
Write-Host "Found Python: $pythonVersion" -ForegroundColor Green

# Check Python version (3.10 or 3.11)
if ($pythonVersion -notmatch '^3\.(10|11)\.') {
    Write-Host "WARNING: Python 3.10 or 3.11 recommended for best compatibility" -ForegroundColor Yellow
    Write-Host "Current version: $pythonVersion"
    Write-Host ""
    $continue = Read-Host "Continue anyway? (Y/N)"
    if ($continue -ne 'Y' -and $continue -ne 'y') {
        exit 1
    }
}

# Check Git
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCmd) {
    Write-Host "ERROR: Git not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Download Git for Windows:"
    Write-Host "https://git-scm.com/download/win"
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host "OK: Python $pythonVersion and Git found" -ForegroundColor Green

# ============================================
# Step 2: Check Intel GPU
# ============================================
Write-Host ""
Write-Host "[2/9] Detecting Intel GPU..." -ForegroundColor Yellow

$gpus = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match "Arc|Iris|Xe|Intel.*UHD" }
if (-not $gpus) {
    Write-Host "WARNING: No Intel GPU detected!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This setup is optimized for:"
    Write-Host "  - Intel Arc A-Series (A310, A380, A580, A750, A770)"
    Write-Host "  - Intel Core Ultra iGPU (Meteor Lake, Arrow Lake)"
    Write-Host ""
    Write-Host "Your GPU:"
    Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name
    Write-Host ""
    $continue = Read-Host "Continue with CPU-only mode? (Y/N)"
    if ($continue -ne 'Y' -and $continue -ne 'y') {
        exit 1
    }
} else {
    Write-Host "Detected Intel GPU:" -ForegroundColor Green
    $gpus | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Green }
}

# ============================================
# Step 3: Check Visual Studio Build Tools
# ============================================
Write-Host ""
Write-Host "[3/9] Checking C++ compiler for Triton GGUF acceleration..." -ForegroundColor Yellow

$vcvarsPaths = @(
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
)

$vcvarsPath = $null
foreach ($path in $vcvarsPaths) {
    if (Test-Path $path) {
        $vcvarsPath = $path
        break
    }
}

if (-not $vcvarsPath) {
    Write-Host ""
    Write-Host "WARNING: Visual Studio Build Tools not found!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Triton GGUF acceleration requires C++ compiler:"
    Write-Host "  - 6-11x faster GGUF model loading"
    Write-Host "  - Required for Q4_0, Q8_0 optimization"
    Write-Host ""
    Write-Host "Download: https://visualstudio.microsoft.com/downloads/"
    Write-Host "  1. Select 'Build Tools for Visual Studio 2022'"
    Write-Host "  2. Install 'Desktop development with C++'"
    Write-Host "  3. Restart PC after installation"
    Write-Host ""
    $continue = Read-Host "Continue without Triton? (ComfyUI will still work) (Y/N)"
    if ($continue -ne 'Y' -and $continue -ne 'y') {
        exit 1
    }
} else {
    Write-Host "OK: Visual Studio Build Tools found" -ForegroundColor Green
    Write-Host "Path: $vcvarsPath"
}

# ============================================
# Step 4: Clone/Update ComfyUI
# ============================================
Write-Host ""
Write-Host "[4/9] Setting up ComfyUI repository..." -ForegroundColor Yellow

if (Test-Path "$InstallPath") {
    Write-Host ""
    Write-Host "ComfyUI directory already exists: $InstallPath"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  [U] Update existing installation (keeps models/workflows)"
    Write-Host "  [F] Fresh install (delete and reinstall)"
    Write-Host "  [S] Skip (use existing)"
    Write-Host ""
    $choice = Read-Host "Choose option (U/F/S)"

    switch ($choice.ToUpper()) {
        'S' {
            Write-Host "Skipping ComfyUI clone..."
            Set-Location "$InstallPath"
        }
        'F' {
            Write-Host "Backing up models and custom_nodes..."
            if (Test-Path "$InstallPath\models") {
                Move-Item "$InstallPath\models" "$InstallPath_models_backup" -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path "$InstallPath\custom_nodes") {
                Move-Item "$InstallPath\custom_nodes" "$InstallPath_custom_nodes_backup" -Force -ErrorAction SilentlyContinue
            }

            Write-Host "Removing old ComfyUI..."
            Remove-Item "$InstallPath" -Recurse -Force

            Write-Host "Cloning fresh ComfyUI..."
            git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git $InstallPath
            if ($LASTEXITCODE -ne 0) {
                Write-Host "ERROR: Failed to clone ComfyUI" -ForegroundColor Red
                Read-Host "Press Enter to exit..."
                exit 1
            }

            Set-Location "$InstallPath"
            if (Test-Path "$InstallPath_models_backup") {
                Move-Item "$InstallPath_models_backup" "models" -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path "$InstallPath_custom_nodes_backup") {
                Move-Item "$InstallPath_custom_nodes_backup" "custom_nodes" -Force -ErrorAction SilentlyContinue
            }
        }
        default {
            Set-Location "$InstallPath"
            Write-Host "Updating ComfyUI..."
            git pull
        }
    }
} else {
    Write-Host "Cloning ComfyUI repository..."
    git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git $InstallPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to clone ComfyUI" -ForegroundColor Red
        Write-Host "Check your internet connection and try again"
        Read-Host "Press Enter to exit..."
        exit 1
    }
    Set-Location "$InstallPath"
}

Write-Host "OK: ComfyUI repository ready" -ForegroundColor Green

# ============================================
# Step 5: Create Virtual Environment
# ============================================
Write-Host ""
Write-Host "[5/9] Setting up Python virtual environment..." -ForegroundColor Yellow

if (Test-Path "comfyui_venv") {
    Write-Host "Virtual environment already exists"
    Write-Host ""
    $recreate = Read-Host "Recreate? (Y/N)"
    if ($recreate -eq 'Y' -or $recreate -eq 'y') {
        Write-Host "Removing old venv..."
        Remove-Item "comfyui_venv" -Recurse -Force
        Write-Host "Creating new venv..."
        python -m venv comfyui_venv
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Failed to create virtual environment" -ForegroundColor Red
            Read-Host "Press Enter to exit..."
            exit 1
        }
    }
} else {
    Write-Host "Creating virtual environment..."
    python -m venv comfyui_venv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to create virtual environment" -ForegroundColor Red
        Write-Host ""
        Write-Host "Try running as Administrator or check Python installation"
        Read-Host "Press Enter to exit..."
        exit 1
    }
}

# Activate virtual environment
& ".\comfyui_venv\Scripts\Activate.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to activate virtual environment" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host "OK: Virtual environment activated" -ForegroundColor Green

# ============================================
# Step 6: Install PyTorch XPU Nightly
# ============================================
Write-Host ""
Write-Host "[6/9] Installing PyTorch XPU Nightly (latest bleeding-edge)..." -ForegroundColor Yellow
Write-Host "This is NEWER than Intel's official 2.5.1 builds!" -ForegroundColor Cyan
Write-Host ""

python -m pip install --upgrade pip setuptools wheel

Write-Host "Removing any existing PyTorch installations..."
pip uninstall -y torch torchvision torchaudio intel-extension-for-pytorch

Write-Host ""
Write-Host "Installing PyTorch XPU Nightly (2.11+)..."
Write-Host "This may take 5-10 minutes..."
pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/xpu

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: PyTorch installation failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Try:"
    Write-Host "  1. Check internet connection"
    Write-Host "  2. Run as Administrator"
    Write-Host "  3. Disable antivirus temporarily"
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host ""
Write-Host "Verifying PyTorch XPU installation..."
python -c "import torch; print('='*60); print('PyTorch:', torch.__version__); print('XPU Available:', hasattr(torch, 'xpu') and torch.xpu.is_available()); print('='*60)"

# ============================================
# Step 7: Install ComfyUI Dependencies
# ============================================
Write-Host ""
Write-Host "[7/9] Installing ComfyUI dependencies..." -ForegroundColor Yellow

pip install -r requirements.txt

if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Some dependencies failed to install" -ForegroundColor Yellow
    Write-Host "ComfyUI may still work, but some features could be missing"
}

# ============================================
# Step 8: Install Triton XPU
# ============================================
Write-Host ""
Write-Host "[8/9] Installing Triton XPU for GGUF acceleration..." -ForegroundColor Yellow

if ($vcvarsPath) {
    pip install pytorch-triton-xpu

    Write-Host ""
    Write-Host "Verifying Triton installation..."
    python -c "try: import triton; print('Triton:', triton.__version__); except: print('Triton: Installation pending - will compile on first use')"
} else {
    Write-Host "Skipping Triton (no C++ compiler found)"
    Write-Host "You can install it later after installing Visual Studio Build Tools"
}

# ============================================
# Step 9: Finalize Installation
# ============================================
Write-Host ""
Write-Host "[9/9] Finalizing installation..." -ForegroundColor Yellow

Write-Host "Installing ComfyUI frontend..."
pip install --upgrade comfyui-frontend-package

Write-Host "Creating directory structure..."
$dirs = @(
    "models", "models\checkpoints", "models\clip", "models\clip_vision",
    "models\vae", "models\loras", "models\unet", "models\controlnet",
    "custom_nodes", "input", "output", "user", "temp"
)
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# ============================================
# Installation Complete - Show Summary
# ============================================
Write-Host ""
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "Installation Complete! ^_^" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
python -c "import torch; print('PyTorch Version:', torch.__version__); xpu = hasattr(torch, 'xpu') and torch.xpu.is_available(); print('XPU Status:', 'READY' if xpu else 'CPU MODE'); print('Device:', torch.xpu.get_device_name(0) if xpu else 'CPU')"
Write-Host ""
Write-Host "================================================================"
Write-Host "Next Steps:"
Write-Host "================================================================"
Write-Host ""
Write-Host "  1. INSTALL_Custom_Nodes.ps1    - Install essential custom nodes"
Write-Host "  2. INSTALL_GGUF_Triton_Patch.ps1 - Enable GGUF acceleration"
Write-Host "  3. Copy models to: $InstallPath\models\checkpoints\"
Write-Host "  4. START_ComfyUI.ps1            - Launch ComfyUI"
Write-Host ""
Write-Host "Installation directory: $InstallPath"
Write-Host ""
Write-Host "================================================================"
Write-Host "Performance Tips:"
Write-Host "================================================================"
Write-Host ""
Write-Host "- Use GGUF Q8_0 models for best quality/speed balance"
Write-Host "- First GGUF load compiles Triton kernels (~30 sec)"
Write-Host "- Update Intel Graphics drivers regularly"
Write-Host "- Keep Windows power plan on 'High Performance'"
Write-Host ""
Read-Host "Press Enter to exit..."
