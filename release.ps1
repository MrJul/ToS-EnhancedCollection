$outputDir = "release"
$name = "enhancedcollection"
$unicodeChar = [char] 0x2615

Write-Output "Deleting directory $outputDir"
if (Test-Path $outputDir) {
	Remove-Item -Recurse -Force $outputDir
}

$ipfDir = "$outputDir\temp\addon_d.ipf\$name";
Write-Output "Creating $ipfDir directory"
New-Item -ItemType Directory -Force $ipfDir | Out-Null

Write-Output "Copying .lua and .xml files"
Get-ChildItem -Filter *.lua | Copy-Item -Destination $ipfDir
Get-ChildItem -Filter *.xml | Copy-Item -Destination $ipfDir

Write-Output "Creating IPF file"
& python buildtools\ipf.py -c -f "$outputDir\$name.ipf" "$outputDir\temp"

if (!(Test-Path "buildtools\IPFUnpacker\ipf_unpack.exe")) {
	Write-Output "Downloading IPFUnpacker"
	Invoke-WebRequest -Uri "https://github.com/r1emu/IPFUnpacker/releases/download/1.3/IPFUnpacker.zip" -OutFile "buildtools\IPFUnpacker.zip"
	Expand-Archive "buildtools\IPFUnpacker.zip" "buildtools"
}

Write-Output "Encrypting IPF file"
& buildtools\IPFUnpacker\ipf_unpack.exe "$outputDir\$name.ipf" encrypt
Move-Item "$outputDir\$name.ipf" "$outputDir\$unicodeChar$name.ipf"

Write-Output "Done"
