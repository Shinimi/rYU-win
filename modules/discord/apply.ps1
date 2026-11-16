# Crimson theme for Vesktop / Vencord (Discord)
. "$PSScriptRoot\..\..\scripts\common.ps1"
$ErrorActionPreference = 'SilentlyContinue'
$here = $PSScriptRoot
$css  = Join-Path $here 'crimson.theme.css'
$targets = @(
  @{ themes = "$env:APPDATA\vesktop\themes";  settings = "$env:APPDATA\vesktop\settings\settings.json"; exe = 'vesktop' },
  @{ themes = "$env:APPDATA\Vencord\themes";  settings = "$env:APPDATA\Vencord\settings\settings.json"; exe = 'Discord' }
)
$found = $false
foreach ($t in $targets) {
  $root = Split-Path (Split-Path $t.themes)
  if (-not (Test-Path $root)) { continue }
  $found = $true
  $exePath = $null
  $running = Get-Process $t.exe -ErrorAction SilentlyContinue
  if ($running) { $exePath = $running[0].Path; Stop-Process -Name $t.exe -Force; Start-Sleep 2 }
  New-Item -ItemType Directory -Force $t.themes | Out-Null
  Copy-Item $css (Join-Path $t.themes 'crimson.theme.css') -Force
  if (Test-Path $t.settings) {
    $j = Get-Content $t.settings -Raw | ConvertFrom-Json
    $list = @()
    if ($j.PSObject.Properties.Name -contains 'enabledThemes') { $list = @($j.enabledThemes) }
    if ($list -notcontains 'crimson.theme.css') { $list += 'crimson.theme.css' }
    $j | Add-Member -NotePropertyName enabledThemes -NotePropertyValue $list -Force
    [IO.File]::WriteAllText($t.settings, ($j | ConvertTo-Json -Depth 50))
    Ok "$($t.exe): theme on"
  } else {
    Ok "$($t.exe): theme copied - turn on 'rYu Crimson' in Settings > Themes"
  }
  if ($exePath) { Start-Process $exePath }
}
if (-not $found) { Warn 'Vesktop / Vencord not found - install one, then run this again' }
