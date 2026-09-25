# Decide whether a destination is an existing ComfyUI checkout or can be cloned into.
# Git accepts a target directory that already exists when that directory is empty.
function Test-ComfyExistingCheckout {
    param([Parameter(Mandatory=$true)][string]$Directory)

    if (-not (Test-Path -LiteralPath $Directory)) {
        return $false
    }
    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        throw "The install target is a file, not a directory: $Directory. No files were deleted."
    }

    if (Test-Path -LiteralPath (Join-Path $Directory 'main.py') -PathType Leaf) {
        return $true
    }

    # Include hidden/system files such as .git and desktop.ini. Do not overwrite an
    # incomplete checkout, user data, or a folder that merely looks empty in Explorer.
    $contents = @(Get-ChildItem -LiteralPath $Directory -Force -ErrorAction Stop)
    if ($contents.Count -eq 0) {
        Write-Host "Reusing the existing empty directory for ComfyUI: $Directory"
        return $false
    }

    $examples = ($contents | Select-Object -First 5 -ExpandProperty Name) -join ', '
    throw "The install target exists but is neither a ComfyUI checkout nor an empty directory: $Directory. Contents include: $examples. Back up or move existing files, or choose another folder. No files were deleted."
}
