param(
    [string]$InstallPath = "$InstallPath"
)

# Remove trailing backslash if present
if ($InstallPath.EndsWith('\')) {
    $InstallPath = $InstallPath.TrimEnd('\')
}

$Host.UI.RawUI.WindowTitle = "Installing ComfyUI Custom Nodes"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "ComfyUI Custom Nodes Installer" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installation directory: $InstallPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "This will install essential custom nodes:"
Write-Host "  - ComfyUI-Manager (node management)"
Write-Host "  - ComfyUI-GGUF (quantized models)"
Write-Host "  - ComfyUI-VideoHelperSuite (video tools)"
Write-Host "  - ComfyUI-Impact-Pack (utilities)"
Write-Host "  - rgthree-comfy (workflow tools)"
Write-Host ""
Write-Host "Usage: .\INSTALL_Custom_Nodes.ps1 [-InstallPath <path>]"
Write-Host "  Default: $InstallPath"
Write-Host "  Example: .\INSTALL_Custom_Nodes.ps1 -InstallPath D:\AI\ComfyUI"
Write-Host ""
Read-Host "Press Enter to continue..."

Set-Location "$InstallPath\custom_nodes"
& "$InstallPath\comfyui_venv\Scripts\Activate.ps1"

Write-Host ""
Write-Host "[1/5] Installing ComfyUI-Manager..." -ForegroundColor Yellow
if (-not (Test-Path "ComfyUI-Manager")) {
    git clone https://github.com/ltdrdata/ComfyUI-Manager
    Set-Location "ComfyUI-Manager"
    if (Test-Path "requirements.txt") {
        pip install -r requirements.txt
    }
    Set-Location ".."
} else {
    Write-Host "Already installed, updating..."
    Set-Location "ComfyUI-Manager"
    git pull
    if (Test-Path "requirements.txt") {
        pip install -r requirements.txt
    }
    Set-Location ".."
}

Write-Host ""
Write-Host "[2/5] Installing ComfyUI-GGUF..." -ForegroundColor Yellow
if (-not (Test-Path "ComfyUI-GGUF")) {
    git clone https://github.com/city96/ComfyUI-GGUF
} else {
    Write-Host "Already installed, updating..."
    Set-Location "ComfyUI-GGUF"
    git pull
    Set-Location ".."
}

Write-Host ""
Write-Host "[3/5] Installing ComfyUI-VideoHelperSuite..." -ForegroundColor Yellow
if (-not (Test-Path "ComfyUI-VideoHelperSuite")) {
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
    Set-Location "ComfyUI-VideoHelperSuite"
    if (Test-Path "requirements.txt") {
        pip install -r requirements.txt
    }
    Set-Location ".."
} else {
    Write-Host "Already installed, updating..."
    Set-Location "ComfyUI-VideoHelperSuite"
    git pull
    if (Test-Path "requirements.txt") {
        pip install -r requirements.txt
    }
    Set-Location ".."
}

Write-Host ""
Write-Host "[4/5] Installing ComfyUI-Impact-Pack..." -ForegroundColor Yellow
if (-not (Test-Path "ComfyUI-Impact-Pack")) {
    git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack
    Set-Location "ComfyUI-Impact-Pack"
    if (Test-Path "requirements.txt") {
        pip install -r requirements.txt
    }
    Set-Location ".."
} else {
    Write-Host "Already installed, updating..."
    Set-Location "ComfyUI-Impact-Pack"
    git pull
    if (Test-Path "requirements.txt") {
        pip install -r requirements.txt
    }
    Set-Location ".."
}

Write-Host ""
Write-Host "[5/5] Installing rgthree-comfy..." -ForegroundColor Yellow
if (-not (Test-Path "rgthree-comfy")) {
    git clone https://github.com/rgthree/rgthree-comfy
} else {
    Write-Host "Already installed, updating..."
    Set-Location "rgthree-comfy"
    git pull
    Set-Location ".."
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "Custom Nodes Installation Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Run INSTALL_GGUF_Triton_Patch.ps1 for GGUF acceleration"
Write-Host "================================================================"
Read-Host "Press Enter to exit..."
