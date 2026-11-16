. "$PSScriptRoot\..\..\scripts\common.ps1"
foreach ($d in "$env:APPDATA\vesktop\themes", "$env:APPDATA\Vencord\themes") { Remove-Item "$d\crimson.theme.css" -Force -ErrorAction SilentlyContinue }
Ok 'Discord theme removed'
