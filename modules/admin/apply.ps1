# Runs GlazeWM (and tacky-borders) as admin at login, so keybinds keep working while
# an admin window is focused (games with anti-cheat, Task Manager, installers...).
. "$PSScriptRoot\..\..\scripts\common.ps1"
try {
  $glaze = "$env:ProgramFiles\glzr.io\GlazeWM\glazewm.exe"
  $tacky = Get-ChildItem "$env:LOCALAPPDATA\tacky-borders" -Recurse -Filter tacky-borders.exe -ErrorAction SilentlyContinue | Select-Object -First 1
  $user = "$env:USERDOMAIN\$env:USERNAME"

  # take them out of the normal autostart
  $run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
  $removed = @{}
  $props = Get-ItemProperty $run
  foreach ($p in $props.PSObject.Properties) {
    if ($p.Value -is [string] -and ($p.Value -match 'glazewm\.exe' -or $p.Value -match 'tacky-borders\.exe')) {
      $removed[$p.Name] = $p.Value
      Remove-ItemProperty $run -Name $p.Name
      Write-Host "removed autostart: $($p.Name)"
    }
  }
  $su = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
  Get-ChildItem $su -Filter *.lnk -ErrorAction SilentlyContinue | ForEach-Object {
    $t = (New-Object -ComObject WScript.Shell).CreateShortcut($_.FullName).TargetPath
    if ($t -match 'glazewm|tacky-borders') {
      $bak = "$env:TEMP\rYu-win\startup-backup"; New-Item -ItemType Directory -Force $bak | Out-Null
      Move-Item $_.FullName $bak -Force; Write-Host "moved startup shortcut: $($_.Name)"
    }
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
  try { Start-ScheduledTask 'rYu GlazeWM' -ErrorAction Stop } catch { Write-Host "task error: $_" }
  if ($tacky) { try { Start-ScheduledTask 'rYu tacky-borders' -ErrorAction Stop } catch { } }
  Start-Sleep 4

  if (Get-Process glazewm -ErrorAction SilentlyContinue) {
    Ok 'GlazeWM + borders run as admin from login on'
  } else {
    # some setups refuse to start an elevated task (0x800702E4), put everything back
    Write-Host 'The admin task did not start on this PC, going back to normal autostart.' -ForegroundColor Yellow
    'rYu GlazeWM', 'rYu tacky-borders' | ForEach-Object { Unregister-ScheduledTask $_ -Confirm:$false -ErrorAction SilentlyContinue }
    foreach ($k in $removed.Keys) { New-ItemProperty $run -Name $k -Value $removed[$k] -PropertyType String -Force | Out-Null }
    $bak = "$env:TEMP\rYu-win\startup-backup"
    if (Test-Path $bak) { Get-ChildItem $bak -Filter *.lnk | Move-Item -Destination $su -Force }
    Start-Process $glaze -ArgumentList 'start'
    if ($tacky) { Start-Process $tacky.FullName }
  }
} catch { Write-Host "Something failed: $_" -ForegroundColor Yellow }
