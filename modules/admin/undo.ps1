. "$PSScriptRoot\..\..\scripts\common.ps1"
Unregister-ScheduledTask -TaskName 'rYu GlazeWM' -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName 'rYu tacky-borders' -Confirm:$false -ErrorAction SilentlyContinue
Set-RunKey 'GlazeWM' "`"$env:ProgramFiles\glzr.io\GlazeWM\glazewm.exe`" start"
$t = "$env:LOCALAPPDATA\tacky-borders\tacky-borders.exe"
if (Test-Path $t) { Set-RunKey 'tacky-borders' "`"$t`"" }
Ok 'GlazeWM back to normal autostart'
