# Stops the core apps, removes them from autostart and puts back your old configs.
. "$PSScriptRoot\..\..\scripts\common.ps1"
foreach ($p in 'glazewm','yasb','tacky-borders','thide','rYuSwitch') { Get-Process $p -ErrorAction SilentlyContinue | Stop-Process -Force }
foreach ($k in 'GlazeWM','YASB','tacky-borders','thide','Flow.Launcher') { Remove-RunKey $k }
foreach ($f in "$env:USERPROFILE\.glzr\glazewm\config.yaml", "$env:USERPROFILE\.config\yasb\config.yaml",
               "$env:USERPROFILE\.config\yasb\styles.css", "$env:USERPROFILE\.config\tacky-borders\config.yaml") {
  if (Test-Path "$f.before-rYu") { Copy-Item "$f.before-rYu" $f -Force; Remove-Item "$f.before-rYu" -Force }
}
# bring the taskbar back
$th = "$env:LOCALAPPDATA\thide\thide.exe"
if (Test-Path $th) { Start-Process $th -ArgumentList 'stop' -Wait -ErrorAction SilentlyContinue }
Ok 'core apps stopped and removed from autostart (the apps themselves are still installed)'
