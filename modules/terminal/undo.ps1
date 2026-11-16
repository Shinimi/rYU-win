. "$PSScriptRoot\..\..\scripts\common.ps1"
$prof = $PROFILE.CurrentUserCurrentHost
if (Test-Path $prof) {
  $t = [IO.File]::ReadAllText($prof)
  Write-Text $prof ([regex]::Replace($t, '(?s)# ---- rYu crimson prompt ----.*?# ---- /rYu ----\r?\n?', ''))
}
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Terminal.lnk", "$([Environment]::GetFolderPath('Desktop'))\Terminal.lnk" -Force -ErrorAction SilentlyContinue
Ok 'prompt removed (Terminal and fastfetch are still in %LOCALAPPDATA%\Programs)'
