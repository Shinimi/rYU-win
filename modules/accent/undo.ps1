. "$PSScriptRoot\..\..\scripts\common.ps1"
Get-Process AccentColorizer -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-RunKey 'AccentColorizer'
Remove-Item "$env:LOCALAPPDATA\AccentColorizer" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item 'HKCU:\Software\AccentColorizer' -Recurse -Force -ErrorAction SilentlyContinue
# Windows default blue (#0078D7)
$dwm = 'HKCU:\Software\Microsoft\Windows\DWM'
Set-ItemProperty $dwm ColorPrevalence 0 -Type DWord
Set-ItemProperty $dwm AccentColor 0xFFD77800 -Type DWord
Set-ItemProperty $dwm ColorizationColor 0xC40078D7 -Type DWord
Set-ItemProperty $dwm ColorizationAfterglow 0xC40078D7 -Type DWord
$acc = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'
Remove-ItemProperty $acc -Name AccentColorMenu, StartColorMenu, AccentPalette -ErrorAction SilentlyContinue
Ok 'accent back to Windows blue (fully applies after signing out, or pick one in Settings > Personalization > Colors)'
