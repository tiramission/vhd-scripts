$tmpDir = Join-Path $psscriptroot temps
$vhdxFile = Join-Path $tmpDir test.vhdx

Dismount-DiskImage -ImagePath "D:\资源\其他\Win11_24H2_Chinese_Simplified_x64.iso"
Dismount-VHD -Path $vhdxFile
Remove-Item $vhdxFile