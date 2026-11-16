. "$PSScriptRoot\..\..\scripts\common.ps1"
Get-Process AccentColorizer -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-RunKey 'AccentColorizer'
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\DWM' ColorPrevalence 0 -Type DWord
Ok 'AccentColorizer removed (pick a new accent in Settings > Personalization > Colors)'
