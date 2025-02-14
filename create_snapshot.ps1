param(
    [string]$VHDX = "C:\Users\jaign\Codes\TempsProjects\vhd-demo\temps\test.vhdx"
)

$ErrorActionPreference = "Stop"

$date = Get-Date -Format "yyyy.M.d"
$vhdxFile = (Resolve-Path $VHDX) | Get-Item
$snapShotVhdxName = "$($vhdxFile.BaseName)-$date$($vhdxFile.Extension)"
$snapShotVhdxDir = Join-Path ($vhdxFile.Directory | Resolve-Path) "snapshots"
$snapShotVhdx = Join-Path $snapShotVhdxDir $snapShotVhdxName
if(-not (Test-Path $snapShotVhdxDir)) {
    New-Item -Path $snapShotVhdxDir -ItemType Directory
}
if(Test-Path $snapShotVhdx) {
    Write-Host "今日快照已经存在：$date"
    return
} 

Move-Item $vhdxFile $snapShotVhdx
New-VHD -Path $vhdxFile -ParentPath $snapShotVhdx
