# Waterfox gets themed automatically, Helium and Vivaldi need a couple of clicks (see README).
. "$PSScriptRoot\..\..\scripts\common.ps1"
$profiles = Get-ChildItem "$env:APPDATA\Waterfox\Profiles" -Directory -ErrorAction SilentlyContinue
if (-not $profiles) { Warn 'no Waterfox profile found (open Waterfox once, then run again)'; return }
Get-Process waterfox -ErrorAction SilentlyContinue | Stop-Process -Force
foreach ($p in $profiles) {
  $c = Join-Path $p.FullName 'chrome'
  New-Item -ItemType Directory -Force $c | Out-Null
  Copy-Item "$PSScriptRoot\userChrome.css", "$PSScriptRoot\userContent.css" $c -Force
  $uj = Join-Path $p.FullName 'user.js'
  if (-not (Test-Path $uj) -or -not (Select-String -Path $uj -SimpleMatch 'legacyUserProfileCustomizations' -Quiet)) {
    Add-Content $uj 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
  }
}
Ok 'Waterfox themed'
