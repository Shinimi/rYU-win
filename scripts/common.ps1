# Shared helpers for the rYu-win modules.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Global:RepoRoot = Split-Path -Parent $PSScriptRoot
$Global:DataDir  = "$env:ProgramData\rYu"
$Global:TempDir  = Join-Path $env:TEMP 'rYu-win'
New-Item -ItemType Directory -Force $TempDir | Out-Null

function Say($msg)  { Write-Host "  $msg" }
function Ok($msg)   { Write-Host "  [ok] $msg" -ForegroundColor Red }
function Warn($msg) { Write-Host "  [!] $msg" -ForegroundColor Yellow }

# Downloads the first asset of a repo's latest release that matches $pattern.
function Get-ReleaseAsset([string]$repo, [string]$pattern) {
  $rel = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest" -Headers @{ 'User-Agent' = 'rYu-win' }
  $asset = $rel.assets | Where-Object { $_.name -match $pattern } | Select-Object -First 1
  if (-not $asset) { throw "no release file matching '$pattern' in $repo" }
  $out = Join-Path $TempDir $asset.name
  Say "downloading $($asset.name)"
  Invoke-WebRequest $asset.browser_download_url -OutFile $out -UseBasicParsing
  return $out
}

function Expand-To([string]$zip, [string]$name) {
  $dir = Join-Path $TempDir $name
  Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
  Expand-Archive $zip $dir -Force
  return $dir
}

function Install-Msi([string]$msi) {
  $p = Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /qn /norestart" -Wait -PassThru
  if ($p.ExitCode -notin 0, 3010) { throw "msiexec failed ($($p.ExitCode)) for $msi" }
}

function Set-RunKey([string]$name, [string]$cmd) {
  Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $name -Value $cmd
}
function Remove-RunKey([string]$name) {
  Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $name -ErrorAction SilentlyContinue
}

# Writes text as UTF-8 without BOM (some apps choke on the BOM).
function Write-Text([string]$path, [string]$text) {
  New-Item -ItemType Directory -Force (Split-Path -Parent $path) | Out-Null
  [IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding $false))
}

function Clear-IconCache {
  Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
  Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db" -Force -ErrorAction SilentlyContinue
}

# Restarts Explorer, then brings thide back (it hides the taskbar again).
function Restart-Explorer {
  Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
  Start-Sleep 2
  if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
  $th = "$env:LOCALAPPDATA\thide\thide.exe"
  if (Test-Path $th) { Start-Sleep 3; Start-Process $th -ArgumentList 'start' }
}

# Starts a program as the normal (non-admin) user even from an admin shell.
function Start-AsUser([string]$exe) {
  if (Test-Path $exe) { Start-Process explorer.exe -ArgumentList "`"$exe`"" }
}
