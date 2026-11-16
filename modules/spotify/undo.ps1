. "$PSScriptRoot\..\..\scripts\common.ps1"
$exe = "$env:LOCALAPPDATA\spicetify\spicetify.exe"
if (Test-Path $exe) { & $exe restore }
Ok 'Spotify back to normal'
