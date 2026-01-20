$Host.UI.RawUI.WindowTitle = "ComfyUI - Intel Arc XPU with Triton Optimization"

# ============================================
# Function to import environment from batch file
# ============================================
function Import-BatchEnvironment {
    param([string]$BatchFile)

    $tempFile = [System.IO.Path]::GetTempFileName()
    cmd /c "`"$BatchFile`" && set > `"$tempFile`""

    Get-Content $tempFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $name = $matches[1]
            $value = $matches[2]
            Set-Item -Path "env:$name" -Value $value
        }
    }

    Remove-Item $tempFile
}

# ============================================
# Initialize C++ Compiler for Triton
# ============================================
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Initializing ComfyUI with Intel Arc XPU" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

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

if ($vcvarsPath) {
    Write-Host "[COMPILER] Loading C++ environment for Triton..." -ForegroundColor Yellow
    Import-BatchEnvironment $vcvarsPath
    Write-Host "OK: C++ compiler loaded" -ForegroundColor Green
} else {
    Write-Host "[WARNING] C++ compiler not found - Triton may not work" -ForegroundColor Yellow
    Write-Host "Install Visual Studio Build Tools for GGUF acceleration"
}

# ============================================
# Intel XPU Environment Variables
# ============================================
$env:SYCL_CACHE_PERSISTENT = "1"
$env:SYCL_CACHE_DIR = "C:\ComfyUI\sycl_cache"
$env:SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS = "1"
$env:ONEAPI_DEVICE_SELECTOR = "level_zero:gpu"
$env:SYCL_DEVICE_FILTER = "level_zero:gpu"

if (-not (Test-Path "C:\ComfyUI\sycl_cache")) {
    New-Item -ItemType Directory -Path "C:\ComfyUI\sycl_cache" -Force | Out-Null
}

Write-Host "[XPU] Intel Arc GPU acceleration enabled" -ForegroundColor Green
Write-Host ""

# ============================================
# Launch ComfyUI
# ============================================
Set-Location "C:\ComfyUI"
& ".\comfyui_venv\Scripts\Activate.ps1"

Write-Host "[INFO] Starting ComfyUI..." -ForegroundColor Cyan
Write-Host "[INFO] GGUF Triton optimization: Active" -ForegroundColor Cyan
Write-Host "[INFO] First GGUF load will compile kernels (~10-30 sec)" -ForegroundColor Yellow
Write-Host "[INFO] Access UI: http://127.0.0.1:8188" -ForegroundColor Green
Write-Host ""

python main.py `
--lowvram `
--bf16-unet `
--async-offload `
--disable-smart-memory `
--preview-method auto `
--output-directory "$env:USERPROFILE\Documents\AI-Playground\media" `
--front-end-version "Comfy-Org/ComfyUI_frontend@latest"

Read-Host "Press Enter to exit..."
