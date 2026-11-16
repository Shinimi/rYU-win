. "$PSScriptRoot\..\..\scripts\common.ps1"
Get-ChildItem "$env:APPDATA\Waterfox\Profiles" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  Remove-Item (Join-Path $_.FullName 'chrome\userChrome.css'), (Join-Path $_.FullName 'chrome\userContent.css') -Force -ErrorAction SilentlyContinue
}
Ok 'Waterfox theme removed'
