#Requires -RunAsAdministrator
#Requires -Version 7

param(
    [uint64]$Size = 20GB,
    [string]$Label = "OS",
    [string]$ISO = "D:\资源\其他\Win11_24H2_Chinese_Simplified_x64.iso",
    [string]$DriverPath = "D:\资源\驱动\dismExportDrivers\",
    [string]$Version = "Windows 11 专业版"
)

$ErrorActionPreference = "Stop"

$tmpDir = Join-Path $psscriptroot temps
if(-not (Test-Path $tmpDir)) {
    New-Item -Path $tmpDir -ItemType Directory
}
$vhdxFile = Join-Path $tmpDir test.vhdx
$vhdx = New-VHD -Path $vhdxFile -SizeBytes $Size -Dynamic
$disk = Mount-VHD -Path $vhdx.Path -Passthru | Get-Disk

Initialize-Disk -Number $disk.Number -PartitionStyle GPT
$partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter
$volume = $partition | Format-Volume -FileSystem NTFS -NewFileSystemLabel $Label
$vhdxRoot = "$($volume.DriveLetter):\"

$mntISO = Mount-DiskImage -ImagePath $ISO
$volISO = $mntISO | Get-Volume
$installWim = Resolve-Path "$($volISO.DriveLetter):\sources\install.wim"
$imgIdx = (Get-WindowsImage -ImagePath $installWim | where { $_.ImageName.Equals($Version) }).ImageIndex

Expand-WindowsImage -ImagePath $installWim -ApplyPath $vhdxRoot -Index $imgIdx
# 安装驱动
if (Test-Path $DriverPath) {
    $driverPath = Resolve-Path $DriverPath
    $null = Add-WindowsDriver -Path $vhdxRoot -Driver $driverPath -Recurse
}


$null = $mntISO | Dismount-DiskImage
Dismount-VHD -Path $vhdx.Path
# Remove-Item $vhdx.Path