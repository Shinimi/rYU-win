# Crimson accent color, plus AccentColorizer so the leftover blue bits
# (drive-space bars, progress bars) turn crimson too.
. "$PSScriptRoot\..\..\scripts\common.ps1"
$dir = "$env:LOCALAPPDATA\AccentColorizer"
New-Item -ItemType Directory -Force $dir | Out-Null
Get-Process AccentColorizer -ErrorAction SilentlyContinue | Stop-Process -Force
if (-not (Test-Path "$dir\AccentColorizer.exe")) {
  $exe = Get-ReleaseAsset 'krlvm/AccentColorizer' '^AccentColorizer-Static-x64\.exe$'
  Copy-Item $exe "$dir\AccentColorizer.exe" -Force
}

# accent = #DC143C
$dwm = 'HKCU:\Software\Microsoft\Windows\DWM'
Set-ItemProperty $dwm AccentColor 0xFF3C14DC -Type DWord           # ABGR
Set-ItemProperty $dwm ColorizationColor 0xC4DC143C -Type DWord     # ARGB
Set-ItemProperty $dwm ColorizationAfterglow 0xC4DC143C -Type DWord
Set-ItemProperty $dwm ColorPrevalence 1 -Type DWord                # colored title bars
$acc = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'
New-Item -Path $acc -Force | Out-Null
Set-ItemProperty $acc AccentColorMenu 0xFF3C14DC -Type DWord
Set-ItemProperty $acc StartColorMenu 0xFF1E0A8B -Type DWord
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' ColorPrevalence 0 -Type DWord

New-Item -Path 'HKCU:\Software\AccentColorizer' -Force | Out-Null
Set-ItemProperty 'HKCU:\Software\AccentColorizer' ColorizeProgressBar 1 -Type DWord
Set-RunKey 'AccentColorizer' "`"$dir\AccentColorizer.exe`""
Start-Process "$dir\AccentColorizer.exe"
Ok 'crimson accent'
