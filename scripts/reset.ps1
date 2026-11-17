# rYu-win full reset. Run reset.cmd instead of this file.
# Undoes every module AND removes the apps the installer added, so Windows looks
# like it did before rYu-win. Your configs get backed up to the desktop first.
param([switch]$Yes)

$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  $a = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  if ($Yes) { $a += ' -Yes' }
  Start-Process powershell -Verb RunAs -ArgumentList $a
  exit
}

$root = Split-Path -Parent $PSScriptRoot
. "$root\scripts\common.ps1"
$ErrorActionPreference = 'Continue'

Write-Host ''
Write-Host '  rYu-win - full reset' -ForegroundColor Red
Write-Host '  --------------------'
Write-Host '  This puts Windows back the way it was before rYu-win:'
Write-Host '   - taskbar, start menu, right-click menu, icons, cursor, accent color, lock screen back to normal'
Write-Host '   - removes GlazeWM, YASB, tacky-borders, thide, Flow Launcher, Open-Shell, Nilesoft Shell,'
Write-Host '     AccentColorizer, ExplorerBlurMica, btop, rYuSwitch, the portable Terminal, fastfetch, Spicetify'
Write-Host '   - removes the Discord / Spotify / Waterfox themes'
Write-Host '  Your GlazeWM / YASB / borders / fastfetch configs are copied to your desktop first.'
Write-Host '  Your wallpapers, Discord, Spotify, Steam and Telegram themselves are left alone.'
Write-Host ''
if (-not $Yes) {
  $ans = (Read-Host '  Type YES to reset').Trim()
  if ($ans -cne 'YES') { Write-Host '  cancelled, nothing changed.'; Start-Sleep 3; exit }
}

$log = Join-Path $TempDir 'reset.log'
Start-Transcript $log -Force | Out-Null

# ---- 1. backup ----
$bak = Join-Path ([Environment]::GetFolderPath('Desktop')) ("rYu-win-backup-" + (Get-Date -Format 'yyyy-MM-dd-HHmm'))
New-Item -ItemType Directory -Force $bak | Out-Null
foreach ($d in "$env:USERPROFILE\.glzr", "$env:USERPROFILE\.config\yasb", "$env:USERPROFILE\.config\tacky-borders",
               "$env:USERPROFILE\.config\fastfetch", "$env:APPDATA\FlowLauncher\Themes") {
  if (Test-Path $d) { Copy-Item $d (Join-Path $bak (Split-Path $d -Leaf)) -Recurse -Force -ErrorAction SilentlyContinue }
}
Ok "configs backed up to $bak"

# ---- 2. undo every module (reverse install order) ----
# 'animations' is skipped on purpose: Windows has window animations on by default.
$order = 'core','accent','glass','icons','cursor','startmenu','rightclick','terminal','wsanim',
         'sidescreen','admin','lockscreen','discord','spotify','browsers'
[array]::Reverse($order)
foreach ($m in $order) {
  $u = "$root\modules\$m\undo.ps1"
  if (-not (Test-Path $u)) { continue }
  Write-Host ''
  Write-Host "== undo $m" -ForegroundColor Red
  & powershell -NoProfile -ExecutionPolicy Bypass -File $u
}

# ---- 3. stop everything that's left ----
Write-Host ''
Write-Host '== removing apps' -ForegroundColor Red
$procs = 'glazewm','yasb','tacky-borders','thide','rYuSwitch','Flow.Launcher','AccentColorizer','btop4win',
         'StartMenu','fastfetch'
foreach ($p in $procs) { Get-Process $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue }

# autostart: Run keys, startup shortcuts and scheduled tasks pointing at any of them
$pattern = 'glazewm|yasb|tacky-borders|thide|Flow\.Launcher|AccentColorizer|rYuSwitch|btop4win'
$run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$props = Get-ItemProperty $run -ErrorAction SilentlyContinue
if ($props) {
  foreach ($p in $props.PSObject.Properties) {
    if ($p.Name -notlike 'PS*' -and $p.Value -is [string] -and $p.Value -match $pattern) {
      Remove-ItemProperty $run -Name $p.Name -ErrorAction SilentlyContinue
      Say "autostart removed: $($p.Name)"
    }
  }
}
$su = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$wsh = New-Object -ComObject WScript.Shell
Get-ChildItem $su -Filter *.lnk -ErrorAction SilentlyContinue | ForEach-Object {
  if ($wsh.CreateShortcut($_.FullName).TargetPath -match $pattern) { Remove-Item $_.FullName -Force; Say "startup shortcut removed: $($_.Name)" }
}
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
  $_.TaskName -like 'rYu*' -or (($_.Actions | ForEach-Object { $_.Execute }) -join ' ') -match $pattern
} | ForEach-Object { Unregister-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -Confirm:$false; Say "task removed: $($_.TaskName)" }

# ---- 4. uninstall the installed apps ----
function Remove-InstalledApp([string]$namePattern) {
  $keys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
          'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
          'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
  $apps = Get-ItemProperty $keys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match $namePattern }
  foreach ($a in $apps) {
    Say "uninstalling $($a.DisplayName)"
    if ($a.PSChildName -match '^\{[0-9A-Fa-f\-]+\}$' -and $a.UninstallString -match 'msiexec') {
      Start-Process msiexec.exe -ArgumentList "/x $($a.PSChildName) /qn /norestart" -Wait
    } elseif ($a.QuietUninstallString) {
      Start-Process cmd.exe -ArgumentList "/c `"$($a.QuietUninstallString)`"" -Wait -WindowStyle Hidden
    } elseif ($a.UninstallString) {
      Start-Process cmd.exe -ArgumentList "/c `"$($a.UninstallString) /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /S`"" -Wait -WindowStyle Hidden
    }
  }
}
Remove-InstalledApp '^GlazeWM'
Remove-InstalledApp '^YASB'
Remove-InstalledApp '^Nilesoft Shell'
Remove-InstalledApp '^Open-Shell'

# Flow Launcher (Squirrel installer)
$fl = "$env:LOCALAPPDATA\FlowLauncher\Update.exe"
if (Test-Path $fl) { Say 'uninstalling Flow Launcher'; Start-Process $fl -ArgumentList '--uninstall -s' -Wait }

# Spicetify (Spotify itself was already restored by the spotify undo)
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath) {
  $keep = $userPath.Split(';') | Where-Object { $_ -and $_ -notmatch '\\spicetify$|\\Programs\\fastfetch$' }
  [Environment]::SetEnvironmentVariable('Path', ($keep -join ';'), 'User')
}

# ---- 5. Windows look back to default ----
# cursor scheme entry
Remove-ItemProperty 'HKCU:\Control Panel\Cursors\Schemes' -Name 'Bibata Modern Crimson' -ErrorAction SilentlyContinue

Write-Host ''
Say 'restarting Explorer...'
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep 3
if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
Start-Sleep 2

# ---- 6. delete leftover files ----
$dirs = "$env:LOCALAPPDATA\tacky-borders", "$env:LOCALAPPDATA\thide", "$env:LOCALAPPDATA\AccentColorizer",
        "$env:LOCALAPPDATA\rYuSwitch", "$env:LOCALAPPDATA\btop4win", "$env:LOCALAPPDATA\FlowLauncher",
        "$env:LOCALAPPDATA\Programs\WindowsTerminal", "$env:LOCALAPPDATA\Programs\fastfetch",
        "$env:LOCALAPPDATA\Cursors\Bibata-Modern-Crimson", "$env:LOCALAPPDATA\spicetify",
        "$env:APPDATA\spicetify", "$env:APPDATA\FlowLauncher",
        "$env:ProgramFiles\ExplorerBlurMica", "$env:ProgramFiles\glzr.io", "$env:ProgramFiles\YASB",
        "$env:ProgramData\rYu",
        "$env:USERPROFILE\.glzr", "$env:USERPROFILE\.config\yasb", "$env:USERPROFILE\.config\tacky-borders",
        "$env:USERPROFILE\.config\fastfetch"
$left = @()
foreach ($d in $dirs) {
  if (Test-Path $d) {
    Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path $d) { $left += $d } else { Say "deleted $d" }
  }
}
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Flow Launcher*" -Recurse -Force -ErrorAction SilentlyContinue
Clear-IconCache

Stop-Transcript | Out-Null
Write-Host ''
Ok 'reset done. Sign out and back in (or restart) to finish.'
if ($left) {
  Write-Host '  These were in use and could not be deleted yet, delete them after a restart:' -ForegroundColor Yellow
  $left | ForEach-Object { Write-Host "    $_" }
}
Write-Host ''
Write-Host '  Still by hand, if you used them:'
Write-Host '   - Telegram: Settings > Chat settings > pick a default theme'
Write-Host '   - Steam: run the Millennium installer again and choose Uninstall'
Write-Host '   - Discord/Vesktop: Settings > Themes, turn the crimson theme off if it is still listed'
Write-Host '   - Helium / Vivaldi: switch back to the default theme in their settings'
Write-Host "  Configs backup: $bak"
Write-Host "  Log: $log"
Write-Host ''
Read-Host '  press Enter to close'
