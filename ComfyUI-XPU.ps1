# Windows ComfyUI installer for Intel PyTorch XPU.
# Stable XPU wheels are the default. Nightly and CPU fallback are opt-in.
[CmdletBinding()]
param(
    [ValidateSet('Install', 'Update', 'Start', 'Nodes', 'Repair', 'PatchInfo')]
    [string]$Mode = 'Install',
    [string]$InstallPath = 'C:\ComfyUI',
    [switch]$Nightly,
    [switch]$AllowCpu,
    [switch]$SkipNodes,
    [string[]]$ComfyArgs = @()
)

$ErrorActionPreference = 'Stop'
$InstallPath = [System.IO.Path]::GetFullPath($InstallPath)
$VenvPython = Join-Path $InstallPath 'comfyui_venv\Scripts\python.exe'
$StableIndex = 'https://download.pytorch.org/whl/xpu'
$NightlyIndex = 'https://download.pytorch.org/whl/nightly/xpu'

function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw ("Command failed (exit {0}): {1} {2}" -f $LASTEXITCODE, $Command, ($Arguments -join ' '))
    }
}

function Assert-Installed {
    if (-not (Test-Path -LiteralPath (Join-Path $InstallPath 'main.py') -PathType Leaf)) {
        throw "ComfyUI not found at $InstallPath. Run Install first."
    }
    if (-not (Test-Path -LiteralPath $VenvPython -PathType Leaf)) {
        throw "The ComfyUI virtual environment was not found at $VenvPython. Run Install first."
    }
}

function Assert-CleanGit {
    param([string]$Directory)
    if (-not (Test-Path -LiteralPath (Join-Path $Directory '.git'))) {
        throw "Not a Git checkout: $Directory"
    }
    $changes = & git -C $Directory status --porcelain --untracked-files=no
    if ($LASTEXITCODE -ne 0) { throw "Unable to inspect Git status: $Directory" }
    if ($changes) {
        throw "Tracked local changes in $Directory. Commit/stash them before updating; nothing will be reset."
    }
}

function Update-Checkout {
    param([string]$Directory)
    Assert-CleanGit $Directory
    Invoke-Checked 'git' @('-C', $Directory, 'pull', '--ff-only')
}

function Install-PyTorchXpu {
    param([switch]$Force)
    $index = if ($Nightly) { $NightlyIndex } else { $StableIndex }
    $arguments = @('-m', 'pip', 'install', '--upgrade')
    if ($Force) { $arguments += '--force-reinstall' }
    if ($Nightly) { $arguments += '--pre' }
    $arguments += @('torch', 'torchvision', 'torchaudio', '--index-url', $index)
    Write-Host "Installing PyTorch XPU from $index"
    Invoke-Checked $VenvPython $arguments
}

function Install-Requirements {
    Invoke-Checked $VenvPython @('-m', 'pip', 'install', '-r', (Join-Path $InstallPath 'requirements.txt'))
    $managerReq = Join-Path $InstallPath 'manager_requirements.txt'
    if (Test-Path -LiteralPath $managerReq) {
        Write-Host 'Installing the ComfyUI built-in Manager dependencies...'
        Invoke-Checked $VenvPython @('-m', 'pip', 'install', '-r', $managerReq)
    }
}

function Test-Xpu {
    # A working torch import is always required, even if CPU fallback was requested.
    Invoke-Checked $VenvPython @('-c', 'import torch; print("PyTorch:", torch.__version__)')
    & $VenvPython -c 'import torch,sys; ok=hasattr(torch,"xpu") and torch.xpu.is_available(); print("XPU available:",ok); print("GPU:",torch.xpu.get_device_name(0) if ok else "not detected"); sys.exit(0 if ok else 4)'
    if ($LASTEXITCODE -ne 0) {
        if ($AllowCpu) {
            Write-Warning 'Intel XPU is unavailable. Continuing because -AllowCpu was supplied.'
        } else {
            throw 'Intel XPU is unavailable. Update your Intel GPU driver and check hardware compatibility. Use -AllowCpu only if CPU fallback is intended.'
        }
    }
}

function Install-CustomNodes {
    Assert-Installed
    $root = Join-Path $InstallPath 'custom_nodes'
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $nodes = @(
        @('ComfyUI-GGUF', 'https://github.com/city96/ComfyUI-GGUF.git'),
        @('ComfyUI-VideoHelperSuite', 'https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git'),
        @('ComfyUI-Impact-Pack', 'https://github.com/ltdrdata/ComfyUI-Impact-Pack.git'),
        @('rgthree-comfy', 'https://github.com/rgthree/rgthree-comfy.git')
    )
    foreach ($node in $nodes) {
        $directory = Join-Path $root $node[0]
        Write-Host "Custom node: $($node[0])"
        if (Test-Path -LiteralPath $directory) {
            Update-Checkout $directory
        } else {
            Invoke-Checked 'git' @('clone', $node[1], $directory)
        }
        $req = Join-Path $directory 'requirements.txt'
        if (Test-Path -LiteralPath $req) {
            Invoke-Checked $VenvPython @('-m', 'pip', 'install', '-r', $req)
        }
    }
    # Re-check after extensions have installed their own dependencies.
    Test-Xpu
}

function Assert-Python {
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        throw 'Python not found on PATH. Install 64-bit Python 3.12 or 3.11.'
    }
    Invoke-Checked 'python' @('-c', 'import sys; assert sys.maxsize > 2**32 and sys.version_info[:2] in ((3,11),(3,12)), "Use 64-bit Python 3.11 or 3.12"')
}

try {
    if ($Mode -eq 'PatchInfo') {
        Write-Warning 'The legacy ComfyUI-GGUF Triton patch is retired. It is not applied automatically: the upstream installer removed it, and Intel calls native Windows Triton XPU experimental. GGUF itself works without that patch.'
        exit 2
    }

    if ($Mode -eq 'Install') {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git for Windows is required.' }
        if (Test-Path -LiteralPath $InstallPath) {
            if (-not (Test-Path -LiteralPath (Join-Path $InstallPath 'main.py'))) {
                throw "The target path already exists but is not a ComfyUI installation: $InstallPath. Choose another folder; no files were deleted."
            }
            Update-Checkout $InstallPath
        } else {
            Write-Host "Cloning ComfyUI into $InstallPath"
            Invoke-Checked 'git' @('clone', '--depth', '1', 'https://github.com/Comfy-Org/ComfyUI.git', $InstallPath)
        }
        if (-not (Test-Path -LiteralPath $VenvPython)) {
            Assert-Python
            Invoke-Checked 'python' @('-m', 'venv', (Join-Path $InstallPath 'comfyui_venv'))
        }
        Invoke-Checked $VenvPython @('-m', 'pip', 'install', '--upgrade', 'pip')
        Install-PyTorchXpu
        Install-Requirements
        Test-Xpu
        if (-not $SkipNodes) { Install-CustomNodes }
        Write-Host "Installation complete: $InstallPath"
    } elseif ($Mode -eq 'Update') {
        Assert-Installed
        Update-Checkout $InstallPath
        Invoke-Checked $VenvPython @('-m', 'pip', 'install', '--upgrade', 'pip')
        Install-PyTorchXpu
        Install-Requirements
        Test-Xpu
        if (-not $SkipNodes) { Install-CustomNodes }
        Write-Host "Update complete: $InstallPath"
    } elseif ($Mode -eq 'Repair') {
        Assert-Installed
        Install-PyTorchXpu -Force
        Test-Xpu
        Write-Host 'PyTorch XPU repair complete.'
    } elseif ($Mode -eq 'Nodes') {
        Install-CustomNodes
        Write-Host 'Custom node installation complete.'
    } elseif ($Mode -eq 'Start') {
        Assert-Installed
        Test-Xpu
        $env:SYCL_CACHE_PERSISTENT = '1'
        $env:SYCL_CACHE_DIR = Join-Path $InstallPath 'sycl_cache'
        New-Item -ItemType Directory -Path $env:SYCL_CACHE_DIR -Force | Out-Null
        if (-not $AllowCpu) { $env:ONEAPI_DEVICE_SELECTOR = 'level_zero:gpu' }
        $flags = @()
        if (Test-Path -LiteralPath (Join-Path $InstallPath 'manager_requirements.txt')) {
            $flags += '--enable-manager'
        }
        $flags += $ComfyArgs
        Push-Location $InstallPath
        try {
            Write-Host 'Starting ComfyUI: http://127.0.0.1:8188'
            Invoke-Checked $VenvPython (@('main.py') + $flags)
        } finally {
            Pop-Location
        }
    }
    exit 0
} catch {
    Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
