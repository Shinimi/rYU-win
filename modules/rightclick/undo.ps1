. "$PSScriptRoot\..\..\scripts\common.ps1"
$dir = "$env:ProgramFiles\Nilesoft Shell"
foreach ($f in "$dir\shell.nss", "$dir\imports\terminal.nss", "$dir\imports\theme.nss") {
  if (Test-Path "$f.original") { Copy-Item "$f.original" $f -Force }
}
if (Test-Path "$dir\shell.exe") { & "$dir\shell.exe" -unregister -treat -silent }
Ok 'normal right-click menu back (restart Explorer)'
