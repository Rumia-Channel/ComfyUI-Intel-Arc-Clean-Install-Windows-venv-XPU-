# Windows PowerShell 5.1 regression checks; no network, uv, or actual GPU required.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'install_target.ps1')

$testRoot = Join-Path $env:TEMP ('comfy-install-target-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

function Assert-ThrowsOnTarget {
    param([string]$Directory, [string]$Description)
    $rejected = $false
    try { [void](Test-ComfyExistingCheckout -Directory $Directory) }
    catch { $rejected = $true }
    if (-not $rejected) { throw "Expected refusal for $Description" }
}

try {
    $missing = Join-Path $testRoot 'not-created'
    if (Test-ComfyExistingCheckout -Directory $missing) { throw 'Missing destination should be cloneable' }

    $empty = Join-Path $testRoot 'existing empty folder'
    New-Item -ItemType Directory -Path $empty | Out-Null
    if (Test-ComfyExistingCheckout -Directory $empty) { throw 'Existing empty directory should be cloneable' }

    # Validate real Git behavior on Windows with a local fixture, no GitHub traffic.
    $source = Join-Path $testRoot 'source checkout'
    New-Item -ItemType Directory -Path $source | Out-Null
    git init -q $source
    if ($LASTEXITCODE -ne 0) { throw 'git init fixture failed' }
    Set-Content -LiteralPath (Join-Path $source 'main.py') -Value 'print("test ComfyUI")'
    git -C $source add main.py
    if ($LASTEXITCODE -ne 0) { throw 'git add fixture failed' }
    git -C $source -c user.name=SmokeTest -c user.email=smoke@example.invalid commit -qm fixture
    if ($LASTEXITCODE -ne 0) { throw 'git commit fixture failed' }
    git clone --depth 1 $source $empty
    if ($LASTEXITCODE -ne 0) { throw 'git clone refused an existing empty directory on Windows' }
    if (-not (Test-ComfyExistingCheckout -Directory $empty)) { throw 'Cloned target should be recognized as ComfyUI' }

    $notEmpty = Join-Path $testRoot 'folder with data'
    New-Item -ItemType Directory -Path $notEmpty | Out-Null
    Set-Content -LiteralPath (Join-Path $notEmpty 'user-data.txt') -Value 'preserve'
    Assert-ThrowsOnTarget -Directory $notEmpty -Description 'existing user files'
    if (-not (Test-Path -LiteralPath (Join-Path $notEmpty 'user-data.txt'))) { throw 'User file was unexpectedly modified' }

    $hidden = Join-Path $testRoot 'folder with hidden file'
    New-Item -ItemType Directory -Path $hidden | Out-Null
    Set-Content -LiteralPath (Join-Path $hidden '.gitkeep') -Value 'preserve'
    Assert-ThrowsOnTarget -Directory $hidden -Description 'hidden file'

    $partial = Join-Path $testRoot 'partial checkout'
    New-Item -ItemType Directory -Path (Join-Path $partial '.git') -Force | Out-Null
    Assert-ThrowsOnTarget -Directory $partial -Description 'partial Git checkout'

    $justAFile = Join-Path $testRoot 'target file'
    Set-Content -LiteralPath $justAFile -Value 'preserve'
    Assert-ThrowsOnTarget -Directory $justAFile -Description 'file instead of directory'
    $global:LASTEXITCODE = 0
    Write-Host 'Existing empty destination Git clone and nonempty safety tests passed.'
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
