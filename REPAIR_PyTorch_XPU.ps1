param(
    [string]$InstallPath = "$InstallPath"
)

# Remove trailing backslash if present
if ($InstallPath.EndsWith('\')) {
    $InstallPath = $InstallPath.TrimEnd('\')
}

$Host.UI.RawUI.WindowTitle = "Repair/Update PyTorch XPU Nightly"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "PyTorch XPU Nightly - Repair/Update Tool" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installation directory: $InstallPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "This script will:"
Write-Host "  1. Remove ALL existing PyTorch packages"
Write-Host "  2. Clean pip cache"
Write-Host "  3. Install latest PyTorch XPU Nightly build"
Write-Host "  4. Verify XPU device detection"
Write-Host ""
Write-Host "WARNING: This will uninstall all current PyTorch versions!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Usage: .\REPAIR_PyTorch_XPU.ps1 [-InstallPath <path>]"
Write-Host "  Default: $InstallPath"
Write-Host "  Example: .\REPAIR_PyTorch_XPU.ps1 -InstallPath D:\AI\ComfyUI"
Write-Host ""
Read-Host "Press Enter to continue..."

Set-Location "$InstallPath"
if (-not (Test-Path "comfyui_venv")) {
    Write-Host "ERROR: Virtual environment not found!" -ForegroundColor Red
    Write-Host "Run INSTALL_ComfyUI_Intel_Arc_XPU.ps1 first."
    Read-Host "Press Enter to exit..."
    exit 1
}

& ".\comfyui_venv\Scripts\Activate.ps1"

# ============================================
# Step 1: Remove ALL PyTorch packages
# ============================================
Write-Host ""
Write-Host "[1/5] Removing all PyTorch packages..." -ForegroundColor Yellow
Write-Host "This may take a moment..."

pip uninstall -y torch torchvision torchaudio
pip uninstall -y intel-extension-for-pytorch
pip uninstall -y pytorch-triton
pip uninstall -y pytorch-triton-xpu
pip uninstall -y triton

Write-Host ""
Write-Host "[CHECK] Verifying PyTorch removal..."
python -c "try: import torch; print('WARNING: PyTorch still found'); except ImportError: print('OK: PyTorch removed')"

# ============================================
# Step 2: Clean pip cache
# ============================================
Write-Host ""
Write-Host "[2/5] Cleaning pip cache..." -ForegroundColor Yellow

pip cache purge

# ============================================
# Step 3: Upgrade pip
# ============================================
Write-Host ""
Write-Host "[3/5] Upgrading pip to latest version..." -ForegroundColor Yellow

python -m pip install --upgrade pip

# ============================================
# Step 4: Install PyTorch XPU Nightly
# ============================================
Write-Host ""
Write-Host "[4/5] Installing PyTorch XPU Nightly (latest)..." -ForegroundColor Yellow
Write-Host "This may take 5-10 minutes depending on your connection..."
Write-Host ""

pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/xpu

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: PyTorch installation failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "  1. Check your internet connection"
    Write-Host "  2. Try again later (nightly builds may be updating)"
    Write-Host "  3. Visit: https://download.pytorch.org/whl/nightly/xpu/"
    Write-Host ""
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host ""
Write-Host "[4.5/5] Installing Triton XPU..." -ForegroundColor Yellow

pip install pytorch-triton-xpu

if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Triton XPU installation failed" -ForegroundColor Yellow
    Write-Host "GGUF acceleration may not work"
}

# ============================================
# Step 5: Verify Installation
# ============================================
Write-Host ""
Write-Host "[5/5] Verifying PyTorch XPU installation..." -ForegroundColor Yellow
Write-Host ""

python -c "import torch; print('='*60); print('PyTorch Version:', torch.__version__); print('='*60); print('')"

python -c "import torch; xpu_available = hasattr(torch, 'xpu') and torch.xpu.is_available(); print('XPU Available:', xpu_available)"

python -c "import torch; print(''); if hasattr(torch, 'xpu') and torch.xpu.is_available(): print('GPU Device:', torch.xpu.get_device_name(0)); print('GPU Count:', torch.xpu.device_count()); else: print('WARNING: XPU not detected!')"

Write-Host ""
python -c "try: import triton; print('Triton Version:', triton.__version__); except: print('Triton: Not available')"

Write-Host ""
Write-Host "================================================================"

python -c "import torch; import sys; xpu_ok = hasattr(torch, 'xpu') and torch.xpu.is_available(); sys.exit(0 if xpu_ok else 1)"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host "WARNING: XPU Not Detected!" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Possible causes:"
    Write-Host "  1. Intel Arc drivers not installed or outdated"
    Write-Host "  2. Incompatible GPU (not Intel Arc or Core Ultra)"
    Write-Host "  3. PyTorch XPU build not compatible with your system"
    Write-Host ""
    Write-Host "Solutions:"
    Write-Host "  1. Update Intel Graphics drivers:"
    Write-Host "     https://www.intel.com/content/www/us/en/download/785597/"
    Write-Host "  2. Restart your PC"
    Write-Host "  3. Try again after driver update"
    Write-Host ""
    Write-Host "Your GPU:"
    Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name
    Write-Host ""
    Read-Host "Press Enter to exit..."
} else {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "SUCCESS! PyTorch XPU is working correctly" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run START_ComfyUI.ps1 to launch ComfyUI"
    Write-Host ""
    Write-Host "If using GGUF models, run INSTALL_GGUF_Triton_Patch.ps1"
    Write-Host "for additional acceleration."
    Write-Host ""
    Read-Host "Press Enter to exit..."
}
