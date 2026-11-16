. "$PSScriptRoot\..\..\scripts\common.ps1"
$dll = "$env:ProgramFiles\ExplorerBlurMica\ExplorerBlurMica.dll"
if (Test-Path $dll) { & regsvr32.exe /s /u $dll }
Ok 'glass removed (restart Explorer)'
