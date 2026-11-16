. "$PSScriptRoot\..\..\scripts\common.ps1"
Get-Process btop4win -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-Item "$env:LOCALAPPDATA\btop4win" -Recurse -Force -ErrorAction SilentlyContinue
Ok 'btop removed (Discord/Spotify/Telegram/Steam still go to the side screen, see config/glazewm)'
