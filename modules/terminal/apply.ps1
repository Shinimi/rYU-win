# Windows Terminal (portable zip build, works on LTSC) + fastfetch + crimson prompt
. "$PSScriptRoot\..\..\scripts\common.ps1"
$here = $PSScriptRoot
$tmp = $TempDir

# 1) Windows Terminal portable
$wtDir = "$env:LOCALAPPDATA\Programs\WindowsTerminal"
if (-not (Test-Path "$wtDir\wt.exe")) {
  Say 'Windows Terminal'
  $zip = Get-ReleaseAsset 'microsoft/terminal' '^Microsoft\.WindowsTerminal_[\d\.]+_x64\.zip$'
  $ex = Join-Path $tmp 'wt'; Remove-Item $ex -Recurse -Force -ErrorAction SilentlyContinue
  Expand-Archive $zip $ex -Force
  $inner = Get-ChildItem $ex -Directory | Select-Object -First 1
  New-Item -ItemType Directory -Force $wtDir | Out-Null
  Copy-Item "$($inner.FullName)\*" $wtDir -Recurse -Force
}
New-Item -ItemType File -Force "$wtDir\.portable" | Out-Null
New-Item -ItemType Directory -Force "$wtDir\settings" | Out-Null
Copy-Item (Join-Path $here 'settings.json') "$wtDir\settings\settings.json" -Force

# Start Menu + Desktop shortcut (Flow Launcher finds it)
$sh = New-Object -ComObject WScript.Shell
foreach ($lnkPath in @("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Terminal.lnk", "$([Environment]::GetFolderPath('Desktop'))\Terminal.lnk")) {
  $l = $sh.CreateShortcut($lnkPath); $l.TargetPath = "$wtDir\wt.exe"; $l.WorkingDirectory = $env:USERPROFILE; $l.Save()
}

# 2) fastfetch
Say 'fastfetch'
$ffDir = "$env:LOCALAPPDATA\Programs\fastfetch"
if (-not (Test-Path "$ffDir\fastfetch.exe")) {
  $zip = Get-ReleaseAsset 'fastfetch-cli/fastfetch' 'windows-amd64\.zip$'
  $ex = Join-Path $tmp 'ff'; Remove-Item $ex -Recurse -Force -ErrorAction SilentlyContinue
  Expand-Archive $zip $ex -Force
  $exe = Get-ChildItem $ex -Recurse -Filter fastfetch.exe | Select-Object -First 1
  New-Item -ItemType Directory -Force $ffDir | Out-Null
  Copy-Item "$($exe.DirectoryName)\*" $ffDir -Recurse -Force
}
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$ffDir*") { [Environment]::SetEnvironmentVariable('Path', "$userPath;$ffDir", 'User') }
$cfgDir = "$env:USERPROFILE\.config\fastfetch"
New-Item -ItemType Directory -Force $cfgDir | Out-Null
Copy-Item (Join-Path $here 'logo.txt') "$cfgDir\logo.txt" -Force
$cfg = (Get-Content (Join-Path $here 'config.jsonc') -Raw).Replace('__LOGO__', ("$cfgDir\logo.txt" -replace '\\', '/'))
[IO.File]::WriteAllText("$cfgDir\config.jsonc", $cfg)

# 3) PowerShell prompt
Say 'PowerShell prompt'
try { Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force -ErrorAction Stop } catch { }
$prof = $PROFILE.CurrentUserCurrentHost
New-Item -ItemType Directory -Force (Split-Path $prof) | Out-Null
$block = Get-Content (Join-Path $here 'crimson-prompt.txt') -Raw
$old = if (Test-Path $prof) { Get-Content $prof -Raw } else { '' }
$old = [regex]::Replace($old, '(?s)# ---- rYu crimson prompt ----.*?# ---- /rYu ----\r?\n?', '')
[IO.File]::WriteAllText($prof, $old + $block)

# 4) old console (conhost) colors too
Say 'console colors'
$k = 'HKCU:\Console'
$tbl = @(0x0E0B1A,0x6E5BC2,0x7FBF8F,0x8A7AE0,0x3C14DC,0x5B3AB0,0x7CA8E8,0xC8C6D9,0x2F2A4A,0x8C78E0,0x9AD4A8,0xACA0F0,0x7A5CFF,0x7F60D0,0x95C0F4,0xFFFFFF)
for ($i = 0; $i -lt 16; $i++) { Set-ItemProperty $k ("ColorTable{0:D2}" -f $i) $tbl[$i] -Type DWord }
Set-ItemProperty $k ScreenColors 0x07 -Type DWord   # gray-ish text on near-black

Ok 'Terminal + fastfetch + prompt (Win+Enter)'
