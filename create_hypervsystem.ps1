#Requires -RunAsAdministrator
#Requires -Version 7

param(
    [uint64]$Size = 20GB,
    [string]$ISO = "D:\资源\其他\Win11_24H2_Chinese_Simplified_x64.iso",
    [string]$DriverPath = "D:\资源\驱动\dismExportDrivers\nodriver\",
    [string]$Version = "Windows 11 专业版",
    [string]$BootName = "TestBoot"
)

$ErrorActionPreference = "Stop"

$tmpDir = Join-Path $psscriptroot temps
if(-not (Test-Path $tmpDir)) {
    New-Item -Path $tmpDir -ItemType Directory
}
$vhdxFile = Join-Path $tmpDir "test-hyperv.vhdx"
$vhdx = New-VHD -Path $vhdxFile -SizeBytes $Size -Dynamic
$disk = Mount-VHD -Path $vhdx.Path -Passthru | Get-Disk

Initialize-Disk -Number $disk.Number -PartitionStyle GPT
$efiP = New-Partition -DiskNumber $disk.Number -Size 300MB -GptType "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -AssignDriveLetter
$efiV = $efiP | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "EFI"
$sysP = New-Partition -DiskNumber $disk.Number -Offset ($efiP.Offset + $efiP.Size) -UseMaximumSize -AssignDriveLetter
$sysV = $sysP | Format-Volume -FileSystem NTFS -NewFileSystemLabel "System"

$efiDriverLetter = $efiV.DriveLetter + ":"
$vhdxRoot = "$($sysV.DriveLetter):\"

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

$sysRoot = "$($vhdxRoot)Windows"
# 添加引导记录
& bcdboot $sysRoot /s $efiDriverLetter /f UEFI /l zh-cn /description $BootName

$null = $mntISO | Dismount-DiskImage
Dismount-VHD -Path $vhdx.Path
# Remove-Item $vhdx.Path