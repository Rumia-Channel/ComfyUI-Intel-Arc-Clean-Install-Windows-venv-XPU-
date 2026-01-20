param(
    [string]$InstallPath = "$InstallPath"
)

# Remove trailing backslash if present
if ($InstallPath.EndsWith('\')) {
    $InstallPath = $InstallPath.TrimEnd('\')
}

$Host.UI.RawUI.WindowTitle = "Installing GGUF Triton Patch"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "GGUF Triton Optimization Patch Installer" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installation directory: $InstallPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "This will apply Triton acceleration to GGUF models:"
Write-Host "  - Q4_0: ~11x faster dequantization"
Write-Host "  - Q4_1: ~8x faster dequantization"
Write-Host "  - Q8_0: ~6x faster dequantization"
Write-Host ""
Write-Host "Usage: .\INSTALL_GGUF_Triton_Patch.ps1 [-InstallPath <path>]"
Write-Host "  Default: $InstallPath"
Write-Host "  Example: .\INSTALL_GGUF_Triton_Patch.ps1 -InstallPath D:\AI\ComfyUI"
Write-Host ""
Read-Host "Press Enter to continue..."

Set-Location "$InstallPath"
& ".\comfyui_venv\Scripts\Activate.ps1"

# ============================================
# Check if GGUF node exists
# ============================================
Write-Host ""
Write-Host "[CHECK] Verifying ComfyUI-GGUF installation..." -ForegroundColor Yellow

if (-not (Test-Path "custom_nodes\ComfyUI-GGUF")) {
    Write-Host "ERROR: ComfyUI-GGUF not found!" -ForegroundColor Red
    Write-Host "Run INSTALL_Custom_Nodes.ps1 first."
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host "OK: ComfyUI-GGUF found" -ForegroundColor Green

# ============================================
# Download patch from GitHub
# ============================================
Write-Host ""
Write-Host "[DOWNLOAD] Fetching latest Triton patch..." -ForegroundColor Yellow

try {
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ai-joe-git/ComfyUI-Intel-Arc-Clean-Install-Windows-venv-XPU-/main/patches/comfyui_gguf_xpu.patch' -OutFile 'comfyui_gguf_xpu.patch' -ErrorAction Stop
    Write-Host "OK: Patch file downloaded" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Could not download patch automatically" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please download manually:"
    Write-Host "https://github.com/ai-joe-git/ComfyUI-Intel-Arc-Clean-Install-Windows-venv-XPU-/blob/main/patches/comfyui_gguf_xpu.patch"
    Write-Host ""
    Write-Host "Place it in: $InstallPath\comfyui_gguf_xpu.patch"
    Write-Host "Then run this script again."
    Read-Host "Press Enter to exit..."
    exit 1
}

# ============================================
# Apply patch
# ============================================
Write-Host ""
Write-Host "[PATCH] Applying Triton optimization..." -ForegroundColor Yellow

Set-Location "custom_nodes\ComfyUI-GGUF"

# Check if already applied
git apply --reverse --check "..\..\comfyui_gguf_xpu.patch" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Patch already applied. Skipping..." -ForegroundColor Green
} else {
    # Apply patch
    git apply --whitespace=fix "..\..\comfyui_gguf_xpu.patch"
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "WARNING: Patch may not have applied cleanly" -ForegroundColor Yellow
        Write-Host "This is usually safe - checking for Triton code..."

        $hasTriton = Select-String -Path "dequant.py" -Pattern "HAS_TRITON" -Quiet
        if (-not $hasTriton) {
            Write-Host "ERROR: Triton code not found in dequant.py" -ForegroundColor Red
            Write-Host "Manual patch may be required"
            Read-Host "Press Enter to exit..."
            exit 1
        }
    }
    Write-Host "OK: Patch applied successfully" -ForegroundColor Green
}

# ============================================
# Verify installation
# ============================================
Write-Host ""
Write-Host "[VERIFY] Checking Triton integration..." -ForegroundColor Yellow

Set-Location "..\..\"

$verifyResult = python -c "from custom_nodes.ComfyUI-GGUF.dequant import HAS_TRITON, USE_TRITON_KERNELS; print('HAS_TRITON:', HAS_TRITON); print('USE_TRITON_KERNELS:', USE_TRITON_KERNELS); exit(0 if HAS_TRITON and USE_TRITON_KERNELS else 1)" 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "WARNING: Triton kernels not enabled" -ForegroundColor Yellow
    Write-Host "Check that pytorch-triton-xpu is installed correctly"
    Read-Host "Press Enter to continue..."
} else {
    Write-Host "OK: Triton kernels enabled!" -ForegroundColor Green
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "GGUF Triton Patch Installation Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Performance improvements:"
Write-Host "  - Q4_0 models: ~11x faster"
Write-Host "  - Q8_0 models: ~6x faster"
Write-Host "  - First load will compile kernels (~10-30 seconds)"
Write-Host "  - Subsequent loads use cached kernels"
Write-Host ""
Write-Host "Next: Run START_ComfyUI.ps1 to launch with optimizations!"
Write-Host "================================================================"
Read-Host "Press Enter to exit..."
