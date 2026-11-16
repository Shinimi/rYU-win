# Runs GlazeWM (and tacky-borders) as admin at login, so keybinds keep working while
# an admin window is focused (games with anti-cheat, Task Manager, installers...).
. "$PSScriptRoot\..\..\scripts\common.ps1"
try {
  $glaze = "$env:ProgramFiles\glzr.io\GlazeWM\glazewm.exe"
  $tacky = Get-ChildItem "$env:LOCALAPPDATA\tacky-borders" -Recurse -Filter tacky-borders.exe -ErrorAction SilentlyContinue | Select-Object -First 1
  $user = "$env:USERDOMAIN\$env:USERNAME"

  # take them out of the normal autostart
  $run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
  $props = Get-ItemProperty $run
  foreach ($p in $props.PSObject.Properties) {
    if ($p.Value -is [string] -and ($p.Value -match 'glazewm\.exe' -or $p.Value -match 'tacky-borders\.exe')) {
      Remove-ItemProperty $run -Name $p.Name
      Write-Host "removed autostart: $($p.Name)"
    }
  }
  $su = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
  Get-ChildItem $su -Filter *.lnk -ErrorAction SilentlyContinue | ForEach-Object {
    $t = (New-Object -ComObject WScript.Shell).CreateShortcut($_.FullName).TargetPath
    if ($t -match 'glazewm|tacky-borders') { Remove-Item $_.FullName -Force; Write-Host "removed startup shortcut: $($_.Name)" }
  }

  $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
  $trg = New-ScheduledTaskTrigger -AtLogOn -User $user
  $pri = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
  Register-ScheduledTask -TaskName 'rYu GlazeWM' -Force -Settings $set -Trigger $trg -Principal $pri `
    -Action (New-ScheduledTaskAction -Execute $glaze -Argument 'start') | Out-Null
  if ($tacky) {
    Register-ScheduledTask -TaskName 'rYu tacky-borders' -Force -Settings $set -Trigger $trg -Principal $pri `
      -Action (New-ScheduledTaskAction -Execute $tacky.FullName) | Out-Null
  }

  # restart them as admin now
  foreach ($p in 'glazewm', 'rYuSwitch', 'tacky-borders') { Get-Process $p -ErrorAction SilentlyContinue | Stop-Process -Force }
  Start-Sleep 2
  Start-ScheduledTask 'rYu GlazeWM'
  if ($tacky) { Start-ScheduledTask 'rYu tacky-borders' }
  Ok 'GlazeWM + borders run as admin from login on'
} catch { Write-Host "Something failed: $_" -ForegroundColor Yellow }
