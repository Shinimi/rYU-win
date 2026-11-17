. "$PSScriptRoot\..\..\scripts\common.ps1"
$prof = $PROFILE.CurrentUserCurrentHost
if (Test-Path $prof) {
  $t = [IO.File]::ReadAllText($prof)
  Write-Text $prof ([regex]::Replace($t, '(?s)# ---- rYu crimson prompt ----.*?# ---- /rYu ----\r?\n?', ''))
}
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Terminal.lnk", "$([Environment]::GetFolderPath('Desktop'))\Terminal.lnk" -Force -ErrorAction SilentlyContinue
$k = 'HKCU:\Console'
$tbl = @(0x0C0C0C,0xDA3700,0x0EA113,0xDD963A,0x1F0FC5,0x981788,0x009CC1,0xCCCCCC,0x767676,0xFF783B,0x0CC616,0xD6D661,0x5648E7,0x9E00B4,0xA5F1F9,0xF2F2F2)
for ($i = 0; $i -lt 16; $i++) { Set-ItemProperty $k ("ColorTable{0:D2}" -f $i) $tbl[$i] -Type DWord }
Set-ItemProperty $k ScreenColors 0x07 -Type DWord
Ok 'prompt removed (Terminal and fastfetch are still in %LOCALAPPDATA%\Programs)'
