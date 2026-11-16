# Side screen: btop4win system monitor in crimson. GlazeWM (core config) starts it and
# sends it, Discord, Spotify, Telegram and Steam to the side screen.
. "$PSScriptRoot\..\..\scripts\common.ps1"

# btop4win needs the Visual C++ runtime, LTSC usually doesn't have it
$vc = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64' -ErrorAction SilentlyContinue
if (-not $vc -or $vc.Installed -ne 1) {
  Say 'Visual C++ runtime'
  Invoke-WebRequest 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile "$TempDir\vc_redist.x64.exe" -UseBasicParsing
  Start-Process "$TempDir\vc_redist.x64.exe" -ArgumentList '/install /quiet /norestart' -Wait
}

$dst = "$env:LOCALAPPDATA\btop4win"
if (-not (Test-Path "$dst\btop4win.exe")) {
  $zip = Get-ReleaseAsset 'aristocratos/btop4win' '^(?!.*(LHM|arm)).*\.zip$'
  $ex = Expand-To $zip 'btop'
  $exe = Get-ChildItem $ex -Recurse -Filter btop4win.exe | Select-Object -First 1
  New-Item -ItemType Directory -Force $dst | Out-Null
  Copy-Item "$($exe.DirectoryName)\*" $dst -Recurse -Force
}
New-Item -ItemType Directory -Force "$dst\themes" | Out-Null
Copy-Item "$PSScriptRoot\crimson.theme" "$dst\themes\crimson.theme" -Force

$conf = "$dst\btop.conf"
$want = [ordered]@{
  color_theme = '"crimson"'; theme_background = 'True'; truecolor = 'True'; rounded_corners = 'True'
  update_ms = '1000'; shown_boxes = '"cpu mem net proc"'; proc_sorting = '"cpu lazy"'
}
$lines = if (Test-Path $conf) { [IO.File]::ReadAllLines($conf) } else { @() }
foreach ($k in $want.Keys) {
  $line = "$k = $($want[$k])"
  $i = [array]::FindIndex([string[]]$lines, [Predicate[string]]{ param($l) $l -match "^\s*$k\s*=" })
  if ($i -ge 0) { $lines[$i] = $line } else { $lines += $line }
}
[IO.File]::WriteAllLines($conf, [string[]]$lines)

Get-Process btop4win -ErrorAction SilentlyContinue | Stop-Process -Force
Start-AsUser "$dst\btop4win.exe"
Ok 'btop on the side screen'
