# Shared install-location management for the ComfyUI installer entry points.
# The local marker belongs to this installer checkout, not the ComfyUI checkout.
$script:InstallPathMarkerName = '.comfyui-install-path'

function ConvertTo-ComfyInstallPath {
    param([Parameter(Mandatory=$true)][string]$PathValue)

    $candidate = $PathValue.Trim().Trim('"')
    if ([string]::IsNullOrWhiteSpace($candidate)) {
        throw 'The ComfyUI installation path must not be empty.'
    }
    if (-not [System.IO.Path]::IsPathRooted($candidate) -or $candidate -match '^[A-Za-z]:[^\\/]') {
        throw "Use a fully qualified path such as C:\ComfyUI or D:\AI\ComfyUI: $candidate"
    }
    $normalized = [System.IO.Path]::GetFullPath($candidate).TrimEnd('\', '/')
    $root = [System.IO.Path]::GetPathRoot($normalized).TrimEnd('\', '/')
    if ($normalized -eq $root) {
        throw "Refusing to use a drive/share root as a ComfyUI installation directory: $normalized"
    }
    return $normalized
}

function Get-ComfyInstallPathMarker {
    param([Parameter(Mandatory=$true)][string]$ScriptDirectory)
    $marker = Join-Path $ScriptDirectory $script:InstallPathMarkerName
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { return $null }
    $value = [System.IO.File]::ReadAllText($marker).Trim()
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Installation path marker is empty: $marker"
    }
    try {
        return ConvertTo-ComfyInstallPath $value
    } catch {
        throw ("Invalid installation path in marker {0}: {1}" -f $marker, $_.Exception.Message)
    }
}

function Resolve-ComfyInstallPath {
    param(
        [string]$ExplicitPath,
        [bool]$WasSpecified,
        [bool]$AskDuringInstall,
        [Parameter(Mandatory=$true)][string]$ScriptDirectory
    )

    if ($WasSpecified) {
        return ConvertTo-ComfyInstallPath $ExplicitPath
    }

    $remembered = Get-ComfyInstallPathMarker $ScriptDirectory
    if ($AskDuringInstall) {
        $suggested = if ($remembered) { $remembered } else { 'C:\ComfyUI' }
        $answer = Read-Host "ComfyUI installation directory [$suggested] (Enter to accept)"
        if ([string]::IsNullOrWhiteSpace($answer)) { $answer = $suggested }
        return ConvertTo-ComfyInstallPath $answer
    }

    if ($remembered) { return $remembered }
    throw "Installation path marker is missing ($script:InstallPathMarkerName). Run Install.bat/Install.ps1 once, or supply -InstallPath (first argument for .bat files)."
}

function Save-ComfyInstallPathMarker {
    param(
        [Parameter(Mandatory=$true)][string]$ScriptDirectory,
        [Parameter(Mandatory=$true)][string]$PathValue
    )
    $path = ConvertTo-ComfyInstallPath $PathValue
    $marker = Join-Path $ScriptDirectory $script:InstallPathMarkerName
    [System.IO.File]::WriteAllText($marker, ($path + [Environment]::NewLine), (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Remembered installation directory: $path"
}
