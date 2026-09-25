# Compatibility entry point; implementation lives in ComfyUI-XPU.ps1.
param(
    [string]$InstallPath = 'C:\ComfyUI',
    [switch]$Nightly,
    [switch]$AllowCpu,
    [string[]]$ComfyArgs = @()
)
& (Join-Path $PSScriptRoot 'ComfyUI-XPU.ps1') -Mode 'PatchInfo' -InstallPath $InstallPath -Nightly:$Nightly -AllowCpu:$AllowCpu -ComfyArgs $ComfyArgs
exit $LASTEXITCODE
