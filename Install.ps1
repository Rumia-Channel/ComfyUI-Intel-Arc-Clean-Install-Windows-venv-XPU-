param(
    [string]$InstallPath = "C:\ComfyUI"
)

# Remove trailing backslash if present
if ($InstallPath.EndsWith('\')) {
    $InstallPath = $InstallPath.TrimEnd('\')
}

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$Host.UI.RawUI.WindowTitle = "ComfyUI Complete Installation"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "ComfyUI Complete Installation Script" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will sequentially run:"
Write-Host "  1. INSTALL_ComfyUI_Intel_Arc_XPU.ps1"
Write-Host "  2. INSTALL_Custom_Nodes.ps1"
Write-Host "  3. INSTALL_GGUF_Triton_Patch.ps1"
Write-Host ""
Write-Host "Installation directory: $InstallPath" -ForegroundColor Yellow
Write-Host "Script directory: $ScriptDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "Usage: .\Install.ps1 [-InstallPath <path>]"
Write-Host "  Default: C:\ComfyUI"
Write-Host "  Example: .\Install.ps1 -InstallPath D:\AI\ComfyUI"
Write-Host ""
Write-Host "Press Ctrl+C to cancel, or" -ForegroundColor Yellow
Read-Host "Press Enter to continue..."

# ============================================
# Step 1: Install ComfyUI
# ============================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Step 1/3: Installing ComfyUI Intel Arc XPU" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $ScriptDir
if (-not $?) {
    Write-Host "ERROR: Failed to change to script directory" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
}

$script1 = Join-Path $ScriptDir "INSTALL_ComfyUI_Intel_Arc_XPU.ps1"
if (-not (Test-Path $script1)) {
    Write-Host "ERROR: Script not found: $script1" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
}

& $script1 -InstallPath $InstallPath
if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
    Write-Host ""
    Write-Host "ERROR: ComfyUI installation failed!" -ForegroundColor Red
    Write-Host "Please check the error messages above." -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    exit 1
}

# ============================================
# Step 2: Install Custom Nodes
# ============================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Step 2/3: Installing Custom Nodes" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $ScriptDir
if (-not $?) {
    Write-Host "ERROR: Failed to change to script directory" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
}

$script2 = Join-Path $ScriptDir "INSTALL_Custom_Nodes.ps1"
if (-not (Test-Path $script2)) {
    Write-Host "ERROR: Script not found: $script2" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
}

& $script2 -InstallPath $InstallPath
if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
    Write-Host ""
    Write-Host "WARNING: Custom nodes installation had errors" -ForegroundColor Yellow
    Write-Host "Continuing with GGUF Triton patch..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}

# ============================================
# Step 3: Install GGUF Triton Patch
# ============================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Step 3/3: Installing GGUF Triton Patch" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $ScriptDir
if (-not $?) {
    Write-Host "ERROR: Failed to change to script directory" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
}

$script3 = Join-Path $ScriptDir "INSTALL_GGUF_Triton_Patch.ps1"
if (-not (Test-Path $script3)) {
    Write-Host "ERROR: Script not found: $script3" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
}

& $script3 -InstallPath $InstallPath
if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
    Write-Host ""
    Write-Host "WARNING: GGUF Triton patch installation had errors" -ForegroundColor Yellow
    Write-Host "You may need to run it manually later" -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}

# ============================================
# Installation Complete
# ============================================
Write-Host ""
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installation directory: $InstallPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Copy your models to: $InstallPath\models\checkpoints\"
Write-Host "  2. Run START_ComfyUI.ps1 -InstallPath '$InstallPath' to launch ComfyUI"
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit..."
exit 0
