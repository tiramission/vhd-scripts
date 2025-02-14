param(
    [string]$VHDX = "C:\Users\jaign\Codes\TempsProjects\vhd-demo\temps\test.vhdx"
)

$ErrorActionPreference = "Stop"

$parentVhdx = ((Resolve-Path $VHDX) | Get-VHD).ParentPath
if(-not (Test-Path $parentVhdx)) {
    Write-Host "没有父快照"
    return
}

Merge-VHD -Path ([Params]::VHDX) -DestinationPath $parentVhdx
Move-Item $parentVhdx ([Params]::VHDX)