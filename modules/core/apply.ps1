# Core: GlazeWM (tiling) + YASB (bar) + tacky-borders (red borders)
#       + thide (hides the taskbar) + Flow Launcher, all with the crimson configs.
. "$PSScriptRoot\..\..\scripts\common.ps1"
$cfg = "$RepoRoot\config"

function Backup-Once([string]$path) {
  if ((Test-Path $path) -and -not (Test-Path "$path.before-rYu")) { Copy-Item $path "$path.before-rYu" }
}

# ---- GlazeWM
$glaze = "$env:ProgramFiles\glzr.io\GlazeWM\glazewm.exe"
if (-not (Test-Path $glaze)) { Say 'GlazeWM'; Install-Msi (Get-ReleaseAsset 'glzr-io/glazewm' '^standalone-glazewm-.*-x64\.msi$') }
$gdir = "$env:USERPROFILE\.glzr\glazewm"
New-Item -ItemType Directory -Force $gdir | Out-Null
Backup-Once "$gdir\config.yaml"
Copy-Item "$cfg\glazewm\config.yaml" "$gdir\config.yaml" -Force
Copy-Item "$PSScriptRoot\reload-all.cmd" "$gdir\reload-all.cmd" -Force
Ok 'GlazeWM'

# ---- YASB
$yasb = "$env:ProgramFiles\YASB\yasb.exe"
if (-not (Test-Path $yasb)) { Say 'YASB'; Install-Msi (Get-ReleaseAsset 'amnweb/yasb' '^yasb-.*-x64\.msi$') }
$ydir = "$env:USERPROFILE\.config\yasb"
New-Item -ItemType Directory -Force $ydir | Out-Null
Backup-Once "$ydir\config.yaml"; Backup-Once "$ydir\styles.css"
$walls = "$env:USERPROFILE\Pictures\Wallpapers"
New-Item -ItemType Directory -Force $walls | Out-Null
Get-ChildItem "$RepoRoot\wallpapers" -File -Include *.jpg,*.jpeg,*.png -Recurse -ErrorAction SilentlyContinue | Copy-Item -Destination $walls -Force
$y = [IO.File]::ReadAllText("$cfg\yasb\config.yaml").Replace('__WALLPAPERS__', $walls.Replace('\', '\\')).Replace('__YASBDIR__', $ydir)
Write-Text "$ydir\config.yaml" $y
Copy-Item "$cfg\yasb\styles.css" "$ydir\styles.css" -Force
# ryu-apps.exe feeds the "open apps" part of the bar
$fx = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319"
& "$fx\csc.exe" /nologo /target:winexe /optimize+ "/out:$ydir\ryu-apps.exe" "/r:$fx\System.Web.Extensions.dll" "$PSScriptRoot\ryu-apps.cs" | Out-Null
if ($LASTEXITCODE -ne 0) { Warn 'could not build ryu-apps.exe, the open apps list will stay empty' }
Ok 'YASB'

# ---- tacky-borders
$tdir = "$env:LOCALAPPDATA\tacky-borders"
if (-not (Test-Path "$tdir\tacky-borders.exe")) {
  Say 'tacky-borders'
  $ex = Expand-To (Get-ReleaseAsset 'lukeyou05/tacky-borders' '^tacky-borders-v.*\.zip$') 'tacky'
  $exe = Get-ChildItem $ex -Recurse -Filter tacky-borders.exe | Select-Object -First 1
  New-Item -ItemType Directory -Force $tdir | Out-Null
  Copy-Item "$($exe.DirectoryName)\*" $tdir -Recurse -Force
}
$bdir = "$env:USERPROFILE\.config\tacky-borders"
New-Item -ItemType Directory -Force $bdir | Out-Null
Backup-Once "$bdir\config.yaml"
Copy-Item "$cfg\tacky-borders\config.yaml" "$bdir\config.yaml" -Force
Ok 'tacky-borders'

# ---- thide
$hdir = "$env:LOCALAPPDATA\thide"
if (-not (Test-Path "$hdir\thide.exe")) {
  Say 'thide'
  $ex = Expand-To (Get-ReleaseAsset 'amnweb/thide' '^thide-.*-x64-portable\.zip$') 'thide'
  $exe = Get-ChildItem $ex -Recurse -Filter thide.exe | Select-Object -First 1
  New-Item -ItemType Directory -Force $hdir | Out-Null
  Copy-Item "$($exe.DirectoryName)\*" $hdir -Recurse -Force
}
Ok 'thide'

# ---- Flow Launcher (Win+Space through GlazeWM, crimson theme)
$flow = "$env:LOCALAPPDATA\FlowLauncher\Flow.Launcher.exe"
if (-not (Test-Path $flow)) {
  Say 'Flow Launcher'
  $setup = Get-ReleaseAsset 'Flow-Launcher/Flow.Launcher' '^Flow-Launcher-Setup\.exe$'
  Start-Process $setup -ArgumentList '--silent' -Wait
  Start-Sleep 5
}
$fdir = "$env:APPDATA\FlowLauncher"
New-Item -ItemType Directory -Force "$fdir\Themes" | Out-Null
Copy-Item "$cfg\flow-launcher\Crimson.xaml" "$fdir\Themes\Crimson.xaml" -Force
$fset = "$fdir\Settings\Settings.json"
if (-not (Test-Path $fset) -and (Test-Path $flow)) {
  Start-Process $flow; Start-Sleep 8
  Get-Process Flow.Launcher -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 1
}
if (Test-Path $fset) {
  Get-Process Flow.Launcher -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 1
  $j = [IO.File]::ReadAllText($fset)
  # Alt+Space belongs to the YASB search, Win+Space is handled by GlazeWM
  $j = [regex]::Replace($j, '"Hotkey"\s*:\s*"[^"]*"', '"Hotkey": "Ctrl + Alt + F12"')
  $j = [regex]::Replace($j, '"Theme"\s*:\s*"[^"]*"', '"Theme": "Crimson"')
  Write-Text $fset $j
  Ok 'Flow Launcher'
} else { Warn 'Flow Launcher settings not found - pick the Crimson theme in its settings yourself.' }

# ---- hide the little title stubs minimized windows leave behind (taskbar is hidden)
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class RyuMin {
  [StructLayout(LayoutKind.Sequential)] public struct MM { public uint cbSize; public int w, hgap, vgap, arrange; }
  [DllImport("user32.dll", EntryPoint="SystemParametersInfoW")] public static extern bool Get(uint a, uint b, ref MM c, uint d);
  [DllImport("user32.dll", EntryPoint="SystemParametersInfoW")] public static extern bool Set(uint a, uint b, ref MM c, uint d);
}
"@
$mm = New-Object RyuMin+MM; $mm.cbSize = 20
[void][RyuMin]::Get(0x002B, 20, [ref]$mm, 0)
$mm.arrange = 8
[void][RyuMin]::Set(0x002C, 20, [ref]$mm, 3)

# ---- start with Windows
Set-RunKey 'GlazeWM'       "`"$glaze`" start"
Set-RunKey 'YASB'          "`"$yasb`""
Set-RunKey 'tacky-borders' "`"$tdir\tacky-borders.exe`""
Set-RunKey 'thide'         "`"$hdir\thide.exe`" start"
if (Test-Path $flow) { Set-RunKey 'Flow.Launcher' "`"$flow`"" }
Ok 'autostart entries'

# ---- start everything now
foreach ($p in 'glazewm','yasb','tacky-borders','thide','Flow.Launcher') { Get-Process $p -ErrorAction SilentlyContinue | Stop-Process -Force }
Start-Sleep 1
Start-Process $glaze -ArgumentList 'start'; Start-Sleep 2
Start-Process $yasb
Start-Process "$tdir\tacky-borders.exe"
Start-Process "$hdir\thide.exe" -ArgumentList 'start'
if (Test-Path $flow) { Start-Process $flow }
