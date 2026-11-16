. "$PSScriptRoot\..\..\scripts\common.ps1"
Get-Process rYuSwitch -ErrorAction SilentlyContinue | Stop-Process -Force
$cfg = "$env:USERPROFILE\.glzr\glazewm\config.yaml"
if (Test-Path $cfg) {
  $text = [IO.File]::ReadAllText($cfg)
  if ($text -notmatch "focus --workspace 1'") {
    $add = ''
    for ($i = 1; $i -le 9; $i++) { $add += "  - commands: ['focus --workspace $i']`n    bindings: ['lwin+$i']`n" }
    $text = [regex]::Replace($text, "(?m)^keybindings:\r?\n", "keybindings:`n$add")
  }
  $text = $text.Replace("'shell-exec %LOCALAPPDATA%\rYuSwitch\rYuSwitch.exe', ", "")
  Write-Text $cfg $text
  & "$env:ProgramFiles\glzr.io\GlazeWM\cli\glazewm.exe" command wm-reload-config | Out-Null
}
Ok 'Win+1..9 handed back to GlazeWM'
