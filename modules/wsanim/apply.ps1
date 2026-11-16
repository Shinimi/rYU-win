# rYuSwitch: slide + fade when switching workspaces with Win+1..9.
# Built from rYuSwitch.cs with the C# compiler that ships with Windows.
. "$PSScriptRoot\..\..\scripts\common.ps1"
$dst = "$env:LOCALAPPDATA\rYuSwitch"
New-Item -ItemType Directory -Force $dst | Out-Null
Get-Process rYuSwitch -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 300
$fx  = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319"
& "$fx\csc.exe" /nologo /target:winexe /optimize+ "/out:$dst\rYuSwitch.exe" `
  "/r:$fx\System.Windows.Forms.dll" "/r:$fx\System.Drawing.dll" "/r:$fx\System.Web.Extensions.dll" `
  "$PSScriptRoot\rYuSwitch.cs"
if ($LASTEXITCODE -ne 0) { throw 'compile failed' }

Start-Process "$dst\rYuSwitch.exe"
Start-Sleep -Milliseconds 500
if (-not (Get-Process rYuSwitch -ErrorAction SilentlyContinue)) { throw 'rYuSwitch did not start, GlazeWM config left alone' }

# Win+1..9 now go through rYuSwitch, and it starts together with GlazeWM
$cfg = "$env:USERPROFILE\.glzr\glazewm\config.yaml"
$text = [IO.File]::ReadAllText($cfg)
$text = [regex]::Replace($text, "(?m)^  - commands: \['focus --workspace [1-9]'\]\r?\n    bindings: \['lwin\+[1-9]'\]\r?\n", '')
if ($text -notmatch "rYuSwitch.exe") { $text = $text.Replace("startup_commands: [", "startup_commands: ['shell-exec %LOCALAPPDATA%\rYuSwitch\rYuSwitch.exe', ") }
Write-Text $cfg $text
& "$env:ProgramFiles\glzr.io\GlazeWM\cli\glazewm.exe" command wm-reload-config | Out-Null
Ok 'workspace switch animation'
