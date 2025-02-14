#Requires -RunAsAdministrator
#Requires -Version 7

param (
    [string]$SystemPath = "C:\Users\jaign\Codes\TempsProjects\vhd-demo\temps\test.vhdx",
    [string]$BootName = "TestBoot"
)

$ErrorActionPreference = "Stop"

$efiPartition = Get-Partition | Where-Object { $_.Type -eq "System" -and ( $_ | Get-Volume ).FileSystem -eq "FAT32" }
$efiPartition | Add-PartitionAccessPath -AssignDriveLetter
$efiDriverLetter = (($efiPartition | Get-Partition).DriveLetter) + ":"

$parts = Mount-VHD -Path $SystemPath -Passthru | Get-Disk | Get-Partition
$sysRoot = "$(($parts | where { $_.Type -eq "Basic" }).DriveLetter):\Windows"

# 添加引导记录
& bcdboot $sysRoot /s $efiDriverLetter /f UEFI /l zh-cn /description $BootName

# 移除盘符, 卸载VHD
$efiPartition | Remove-PartitionAccessPath -AccessPath $efiDriverLetter
Dismount-VHD -Path $SystemPath

# 获取引导id
$bcdOut = & bcdedit /enum
$number = (& bcdedit | Select-String -Pattern "^description\s*$BootName$").LineNumber
$lineToCheck = $bcdOut[0..($number-1)]
[Array]::Reverse($lineToCheck)
$idLine = ($lineToCheck | Select-String -Pattern "^identifier\s*(.*)$" | Select-Object -First 1).Line
$id = $idLine -replace "identifier\s*", ""

# 设置默认引导
& bcdedit /default "$id"

# 删除该引导
# & bcdedit /default "{current}"
# & bcdedit /delete "$id" /cleanup