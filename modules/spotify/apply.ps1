# Spicetify + rYu Crimson theme for Spotify (desktop version, not Store)
. "$PSScriptRoot\..\..\scripts\common.ps1"
$here = $PSScriptRoot
if (-not (Test-Path "$env:APPDATA\Spotify\Spotify.exe")) {
  Warn 'Spotify (desktop version, not the Store one) not found - install it, open it once, then run this again'
  return
}
$sp = "$env:LOCALAPPDATA\spicetify"
if (-not (Test-Path "$sp\spicetify.exe")) {
  Say 'Spicetify'
  $rel = Invoke-RestMethod 'https://api.github.com/repos/spicetify/cli/releases/latest' -Headers @{ 'User-Agent' = 'rYu-win' }
  $a = $rel.assets | Where-Object { $_.name -match 'windows-x64\.zip$' } | Select-Object -First 1
  $zip = Join-Path $env:TEMP $a.name
  Invoke-WebRequest $a.browser_download_url -OutFile $zip -UseBasicParsing
  New-Item -ItemType Directory -Force $sp | Out-Null
  Expand-Archive $zip $sp -Force
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ($userPath -notlike "*$sp*") { [Environment]::SetEnvironmentVariable('Path', "$userPath;$sp", 'User') }
}
$exe = "$sp\spicetify.exe"

Get-Process Spotify -ErrorAction SilentlyContinue | Stop-Process -Force
& $exe -c | Out-Null
$themes = "$env:APPDATA\spicetify\Themes\Crimson"
New-Item -ItemType Directory -Force $themes | Out-Null
Copy-Item (Join-Path $here 'Crimson\*') $themes -Force

& $exe config current_theme Crimson color_scheme Base inject_css 1 replace_colors 1
& $exe backup apply
Ok 'Spotify themed (after a Spotify update run: spicetify backup apply)'
