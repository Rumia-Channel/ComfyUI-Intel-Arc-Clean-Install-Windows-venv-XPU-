# Compatibility entry point. The shared installer prompts on Install and otherwise
# reads the ignored .comfyui-install-path marker unless -InstallPath is supplied.
param(
    [string]$InstallPath,
    [switch]$Nightly,
    [switch]$AllowCpu,
    [string[]]$ComfyArgs = @()
)
$options = @{
    Mode = 'Install'
    Nightly = [bool]$Nightly
    AllowCpu = [bool]$AllowCpu
    ComfyArgs = $ComfyArgs
    SkipNodes = $true
}
if ($PSBoundParameters.ContainsKey('InstallPath')) {
    $options.InstallPath = $InstallPath
}
& (Join-Path $PSScriptRoot 'ComfyUI-XPU.ps1') @options
exit $LASTEXITCODE
