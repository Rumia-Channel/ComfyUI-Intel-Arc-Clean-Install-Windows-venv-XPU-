# Executes without ComfyUI installation or Intel GPU; designed for Windows PS 5.1.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'install_path.ps1')
$testDirectory = Join-Path $env:TEMP ('comfy-location-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testDirectory -Force | Out-Null

function Assert-Equal {
    param([string]$Actual, [string]$Expected, [string]$Description)
    if ($Actual -cne $Expected) {
        throw "$Description - expected '$Expected', got '$Actual'"
    }
}

try {
    $marker = Join-Path $testDirectory '.comfyui-install-path'
    $chosen = 'D:\AI Models\ComfyUI'
    Save-ComfyInstallPathMarker -ScriptDirectory $testDirectory -PathValue $chosen
    if (-not (Test-Path -LiteralPath $marker)) { throw 'Marker was not written' }
    Assert-Equal ([IO.File]::ReadAllText($marker).Trim()) $chosen 'Marker stores the selected path'
    Assert-Equal (Resolve-ComfyInstallPath -ScriptDirectory $testDirectory -WasSpecified $false -AskDuringInstall $false) $chosen 'Other scripts reuse marker'
    Assert-Equal (Resolve-ComfyInstallPath -ScriptDirectory $testDirectory -ExplicitPath 'E:\Explicit ComfyUI' -WasSpecified $true -AskDuringInstall $false) 'E:\Explicit ComfyUI' 'Explicit argument wins'

    function Read-Host {
        param([string]$Prompt)
        return ''
    }
    Assert-Equal (Resolve-ComfyInstallPath -ScriptDirectory $testDirectory -WasSpecified $false -AskDuringInstall $true) $chosen 'Empty input accepts remembered default'
    function Read-Host {
        param([string]$Prompt)
        return 'F:\Different install\ComfyUI'
    }
    Assert-Equal (Resolve-ComfyInstallPath -ScriptDirectory $testDirectory -WasSpecified $false -AskDuringInstall $true) 'F:\Different install\ComfyUI' 'Install prompt accepts a changed path'
    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue

    Remove-Item -LiteralPath $marker -Force
    function Read-Host {
        param([string]$Prompt)
        return ''
    }
    Assert-Equal (Resolve-ComfyInstallPath -ScriptDirectory $testDirectory -WasSpecified $false -AskDuringInstall $true) 'C:\ComfyUI' 'First install offers legacy default'
    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue

    $missingRejected = $false
    try {
        Resolve-ComfyInstallPath -ScriptDirectory $testDirectory -WasSpecified $false -AskDuringInstall $false | Out-Null
    } catch {
        $missingRejected = $_.Exception.Message -match 'marker is missing'
    }
    if (-not $missingRejected) { throw 'Missing marker must stop maintenance scripts instead of guessing C:\ComfyUI' }

    $rootRejected = $false
    try { ConvertTo-ComfyInstallPath 'D:\' | Out-Null } catch { $rootRejected = $true }
    if (-not $rootRejected) { throw 'Drive root must be rejected' }

    git check-ignore -q -- .comfyui-install-path
    if ($LASTEXITCODE -ne 0) { throw 'Marker is not ignored by Git' }
    $global:LASTEXITCODE = 0
    Write-Host 'Install location marker tests passed.'
} finally {
    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testDirectory -Recurse -Force -ErrorAction SilentlyContinue
}
