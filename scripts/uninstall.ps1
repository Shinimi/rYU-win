# rYu-win uninstaller. Run uninstall.cmd instead of this file.
#   uninstall.cmd            -> pick from a list
#   uninstall.cmd all        -> undo everything
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Modules)

$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  $a = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  if ($Modules) { $a += ' ' + ($Modules -join ' ') }
  Start-Process powershell -Verb RunAs -ArgumentList $a
  exit
}

$root = Split-Path -Parent $PSScriptRoot
$list = [ordered]@{
  'core'       = 'GlazeWM + YASB bar + red borders + hidden taskbar + Flow Launcher'
  'accent'     = 'crimson accent color, crimson progress bars'
  'glass'      = 'dark red glass File Explorer'
  'icons'      = 'crimson glass folder / drive icons'
  'cursor'     = 'Bibata Modern cursor in crimson'
  'startmenu'  = 'Open-Shell start menu (Win key)'
  'rightclick' = 'crimson right-click menu (Nilesoft Shell)'
  'animations' = 'turn Windows window animations back on'
  'terminal'   = 'Windows Terminal + fastfetch + prompt (Win+Enter)'
  'wsanim'     = 'slide/fade animation when switching workspaces'
  'lockscreen' = 'lock + sign-in screen use your wallpaper'
  'discord'    = 'Vesktop / Vencord theme'
  'spotify'    = 'Spicetify theme (desktop Spotify)'
  'browsers'   = 'Waterfox theme (Helium/Vivaldi: see README)'
  'steam'      = 'Millennium installer for the Steam theme'
}
$default = @($list.Keys)

if (-not $Modules) {
  Write-Host ''
  Write-Host '  rYu-win - undo' -ForegroundColor Red
  Write-Host '  -------'
  $i = 1; $names = @($list.Keys)
  foreach ($n in $names) {
    $mark = if ($default -contains $n) { '*' } else { ' ' }
    Write-Host ("  {0,2}. {1} {2,-11} {3}" -f $i, $mark, $n, $list[$n]); $i++
  }
  Write-Host ''
  Write-Host '  Enter = undo everything    or numbers like: 1 3 4'
  $ans = (Read-Host '  >').Trim()
  if ($ans -eq '') { $Modules = $default }
  elseif ($ans -eq 'all') { $Modules = $names }
  else { $Modules = $ans -split '[\s,]+' | Where-Object { $_ } | ForEach-Object { if ($_ -match '^\d+$') { $names[[int]$_ - 1] } else { $_ } } }
} elseif ($Modules -contains 'all') { $Modules = @($list.Keys) }

# undo in reverse order
$Modules = @($list.Keys | Where-Object { $Modules -contains $_ }); [array]::Reverse($Modules)
if (-not $Modules) { Write-Host '  nothing picked'; Start-Sleep 3; exit }

$log = Join-Path $env:TEMP 'rYu-win\uninstall.log'
New-Item -ItemType Directory -Force (Split-Path $log) | Out-Null
Start-Transcript $log -Force | Out-Null

$failed = @()
foreach ($m in $Modules) {
  Write-Host ''
  Write-Host "== $m" -ForegroundColor Red
  if (-not (Test-Path "$root\modules\$m\undo.ps1")) { Write-Host '  nothing to undo'; continue }
  & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\modules\$m\undo.ps1"
  if ($LASTEXITCODE -ne 0) { $failed += $m; Write-Host "  [x] $m failed" -ForegroundColor Yellow }
}

if ($Modules | Where-Object { $_ -in 'accent','glass','icons','rightclick' }) {
  Write-Host ''
  Write-Host '  restarting Explorer...'
  . "$root\scripts\common.ps1"
  Restart-Explorer
}

Stop-Transcript | Out-Null
Write-Host ''
if ($failed) { Write-Host "  done, but these failed: $($failed -join ', ')  (log: $log)" -ForegroundColor Yellow }
else { Write-Host '  done. Sign out and back in to finish.' -ForegroundColor Red }
Write-Host ''
Read-Host '  press Enter to close'
