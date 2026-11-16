# Steam: installs Millennium (Steam client modding), the rest is two clicks inside Steam.
. "$PSScriptRoot\..\..\scripts\common.ps1"
Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force
$setup = Get-ReleaseAsset 'SteamClientHomebrew/Installer' 'Windows.*\.exe$'
Start-Process $setup -Wait
Ok 'Millennium installer done - see modules\steam\README.md for the theme part'
