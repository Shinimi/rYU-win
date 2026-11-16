# Dark wine-red glass for File Explorer (ExplorerBlurMica by Maplespe).
# Tweak config.ini: lower "a" = more see-through, higher = more solid.
. "$PSScriptRoot\..\..\scripts\common.ps1"
$dst = "$env:ProgramFiles\ExplorerBlurMica"
New-Item -ItemType Directory -Force $dst | Out-Null
if (-not (Test-Path "$dst\ExplorerBlurMica.dll")) {
  $ex = Expand-To (Get-ReleaseAsset 'Maplespe/ExplorerBlurMica' '^Release_x64\.zip$') 'blurmica'
  $dll = Get-ChildItem $ex -Recurse -Filter ExplorerBlurMica.dll | Select-Object -First 1
  Copy-Item $dll.FullName $dst -Force
}
Copy-Item "$PSScriptRoot\config.ini" $dst -Force
& regsvr32.exe /s "$dst\ExplorerBlurMica.dll"
Ok 'crimson glass Explorer'
