. "$PSScriptRoot\..\..\scripts\common.ps1"
Get-Process StartMenu -ErrorAction SilentlyContinue | Stop-Process -Force
$p = Get-Package -Name 'Open-Shell*' -ProviderName msi -ErrorAction SilentlyContinue
if ($p) { $p | Uninstall-Package -Force | Out-Null }
Ok 'Open-Shell removed'
