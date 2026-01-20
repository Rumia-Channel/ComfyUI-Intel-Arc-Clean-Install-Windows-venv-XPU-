param(
    [string]$InstallPath = "$InstallPath"
)

# Remove trailing backslash if present
if ($InstallPath.EndsWith('\')) {
    $InstallPath = $InstallPath.TrimEnd('\')
}

$Host.UI.RawUI.WindowTitle = "Updating ComfyUI"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "ComfyUI Update Script" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installation directory: $InstallPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "This will update:"
Write-Host "  - ComfyUI core"
Write-Host "  - PyTorch XPU Nightly"
Write-Host "  - Triton XPU"
Write-Host "  - Custom nodes"
Write-Host "  - Python dependencies"
Write-Host ""
Write-Host "Usage: .\UPDATE_ComfyUI.ps1 [-InstallPath <path>]"
Write-Host "  Default: $InstallPath"
Write-Host "  Example: .\UPDATE_ComfyUI.ps1 -InstallPath D:\AI\ComfyUI"
Write-Host ""
Read-Host "Press Enter to continue..."

Set-Location "$InstallPath"
& ".\comfyui_venv\Scripts\Activate.ps1"

Write-Host ""
Write-Host "[1/5] Updating ComfyUI core..." -ForegroundColor Yellow
git pull
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Git pull failed - may have local changes" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[2/5] Updating PyTorch XPU Nightly..." -ForegroundColor Yellow
pip install --upgrade --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/xpu

Write-Host ""
Write-Host "[3/5] Updating Triton XPU..." -ForegroundColor Yellow
pip install --upgrade pytorch-triton-xpu

Write-Host ""
Write-Host "[4/5] Updating Python dependencies..." -ForegroundColor Yellow
pip install --upgrade pip
pip install -r requirements.txt

Write-Host ""
Write-Host "[5/5] Updating custom nodes..." -ForegroundColor Yellow
Set-Location "custom_nodes"
Get-ChildItem -Directory | ForEach-Object {
    if (Test-Path "$($_.FullName)\.git") {
        Write-Host "Updating $($_.Name)..." -ForegroundColor Cyan
        Set-Location $_.FullName
        git pull
        if (Test-Path "requirements.txt") {
            pip install -r requirements.txt
        }
        Set-Location ".."
    }
}

Set-Location ".."

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "Update Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Verifying PyTorch XPU..."
python -c "import torch; print('PyTorch:', torch.__version__); print('XPU:', torch.xpu.is_available() if hasattr(torch, 'xpu') else False)"
Write-Host ""
Write-Host "Run START_ComfyUI.ps1 to launch"
Write-Host "================================================================"
Read-Host "Press Enter to exit..."
