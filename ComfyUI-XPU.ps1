# Windows ComfyUI installer for Intel PyTorch XPU.
# Stable XPU wheels are the default. Nightly and CPU fallback are opt-in.
[CmdletBinding()]
param(
    [ValidateSet('Install', 'Update', 'Start', 'Nodes', 'Repair', 'PatchInfo', 'CheckPython')]
    [string]$Mode = 'Install',
    [string]$InstallPath,
    [switch]$Nightly,
    [switch]$AllowCpu,
    [switch]$SkipNodes,
    [string[]]$ComfyArgs = @()
)

$ErrorActionPreference = 'Stop'
$PathProvided = $PSBoundParameters.ContainsKey('InstallPath')
$VerifyScript = Join-Path $PSScriptRoot 'scripts\verify_environment.py'
$StableIndex = 'https://download.pytorch.org/whl/xpu'
$NightlyIndex = 'https://download.pytorch.org/whl/nightly/xpu'

function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw ("Command failed (exit {0}): {1} {2}" -f $LASTEXITCODE, $Command, ($Arguments -join ' '))
    }
}

function Assert-Uv {
    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
        throw 'uv is required. Install uv from https://docs.astral.sh/uv/getting-started/installation/ and reopen your terminal.'
    }
    Invoke-Checked 'uv' @('--version')
}

function Assert-VenvPython {
    if (-not (Test-Path -LiteralPath $VenvPython -PathType Leaf)) {
        throw "Virtual environment Python is missing: $VenvPython. Run Install first."
    }
    & $VenvPython $VerifyScript python
    if ($LASTEXITCODE -ne 0) {
        throw "Existing comfyui_venv uses an unsupported Python. Back up and rename the virtual environment yourself, then rerun Install. No files were deleted: $VenvPython"
    }
}

function Assert-Installed {
    if (-not (Test-Path -LiteralPath (Join-Path $InstallPath 'main.py') -PathType Leaf)) {
        throw "ComfyUI not found at $InstallPath. Run Install first."
    }
    Assert-VenvPython
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
    $index = if ($Nightly) { $NightlyIndex } else { $StableIndex }
    $arguments = @('pip', 'install', '--python', $VenvPython, '--upgrade',
                   '--reinstall-package', 'torch', '--reinstall-package', 'torchvision',
                   '--reinstall-package', 'torchaudio')
    if ($Nightly) { $arguments += @('--prerelease', 'allow') }
    $arguments += @('torch', 'torchvision', 'torchaudio', '--index-url', $index)
    Write-Host "Installing PyTorch XPU with uv from $index"
    Invoke-Checked 'uv' $arguments
}

function Install-Requirements {
    Invoke-Checked 'uv' @('pip', 'install', '--python', $VenvPython, '-r', (Join-Path $InstallPath 'requirements.txt'))
    $managerReq = Join-Path $InstallPath 'manager_requirements.txt'
    if (Test-Path -LiteralPath $managerReq) {
        Write-Host 'Installing the ComfyUI built-in Manager dependencies...'
        Invoke-Checked 'uv' @('pip', 'install', '--python', $VenvPython, '-r', $managerReq)
    }
}

function Test-Xpu {
    # Run a Python file instead of -c: Windows PowerShell 5.1 can strip quotes
    # within the native-process argument used for inline Python statements.
    & $VenvPython $VerifyScript xpu
    $verifyExit = $LASTEXITCODE
    if ($verifyExit -eq 4) {
        if ($AllowCpu) {
            Write-Warning 'Intel XPU is unavailable. Continuing because -AllowCpu was supplied.'
        } else {
            throw 'Intel XPU is unavailable. Update your Intel GPU driver and check hardware compatibility. Use -AllowCpu only if CPU fallback is intended.'
        }
    } elseif ($verifyExit -ne 0) {
        throw "PyTorch/XPU verification failed (exit $verifyExit). Review the Python error above."
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
            Invoke-Checked 'uv' @('pip', 'install', '--python', $VenvPython, '-r', $req)
        }
    }
    # Re-check after extensions have installed their own dependencies.
    Test-Xpu
}

function Assert-Python {
    Assert-Uv
    # uv-managed Python is independent of the system PATH (which may contain 3.14).
    Invoke-Checked 'uv' @('python', 'install', '3.12')
    $managedPython = & uv python find 3.12 --managed-python
    if ($LASTEXITCODE -ne 0 -or -not $managedPython) {
        throw 'uv cannot locate its managed Python 3.12 interpreter.'
    }
    Invoke-Checked ([string]($managedPython | Select-Object -Last 1).Trim()) @($VerifyScript, 'python')
}

try {
    if ($Mode -eq 'CheckPython') {
        Assert-Python
        Write-Host 'uv-managed Python 3.12 check passed.'
        exit 0
    }

    if ($Mode -eq 'PatchInfo') {
        Write-Warning 'The legacy ComfyUI-GGUF Triton patch is retired. It is not applied automatically: the upstream installer removed it, and Intel calls native Windows Triton XPU experimental. GGUF itself works without that patch.'
        exit 2
    }

    # Installation always asks when the caller has not explicitly provided a path.
    # Other commands use the locally ignored marker instead of assuming C:\ComfyUI.
    . (Join-Path $PSScriptRoot 'scripts\install_path.ps1')
    $InstallPath = Resolve-ComfyInstallPath -ExplicitPath $InstallPath -WasSpecified $PathProvided -AskDuringInstall ($Mode -eq 'Install') -ScriptDirectory $PSScriptRoot
    $VenvPython = Join-Path $InstallPath 'comfyui_venv\Scripts\python.exe'

    if ($Mode -eq 'Install') {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git for Windows is required.' }
        Assert-Uv
        if (Test-Path -LiteralPath $VenvPython) { Assert-VenvPython } else { Assert-Python }
        if (Test-Path -LiteralPath $InstallPath) {
            if (-not (Test-Path -LiteralPath (Join-Path $InstallPath 'main.py'))) {
                throw "The target path already exists but is not a ComfyUI installation: $InstallPath. Choose another folder; no files were deleted."
            }
            Update-Checkout $InstallPath
        } else {
            Write-Host "Cloning ComfyUI into $InstallPath"
            Invoke-Checked 'git' @('clone', '--depth', '1', 'https://github.com/Comfy-Org/ComfyUI.git', $InstallPath)
        }
        # Record the selected location after validating/cloning ComfyUI, even if a later
        # package installation fails, so the next run can resume at the same location.
        Save-ComfyInstallPathMarker -ScriptDirectory $PSScriptRoot -PathValue $InstallPath
        if (-not (Test-Path -LiteralPath $VenvPython)) {
            $venvDir = Join-Path $InstallPath 'comfyui_venv'
            if (Test-Path -LiteralPath $venvDir) {
                throw "Virtual environment directory exists but Python is missing: $venvDir. Rename it manually if you want a clean uv environment; no files were deleted."
            }
            Invoke-Checked 'uv' @('venv', '--python', '3.12', '--managed-python', $venvDir)
        }
        Assert-VenvPython
        Install-PyTorchXpu
        Install-Requirements
        Test-Xpu
        if (-not $SkipNodes) { Install-CustomNodes }
        Write-Host "Installation complete: $InstallPath"
    } elseif ($Mode -eq 'Update') {
        Assert-Uv
        Assert-Installed
        Update-Checkout $InstallPath
        Install-PyTorchXpu
        Install-Requirements
        Test-Xpu
        if (-not $SkipNodes) { Install-CustomNodes }
        Write-Host "Update complete: $InstallPath"
    } elseif ($Mode -eq 'Repair') {
        Assert-Uv
        Assert-Installed
        Install-PyTorchXpu
        Test-Xpu
        Write-Host 'PyTorch XPU repair complete.'
    } elseif ($Mode -eq 'Nodes') {
        Assert-Uv
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
