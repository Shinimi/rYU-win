# Crimson right-click menu with Nilesoft Shell 1.9.18.
# Keeps Terminal + File manage, drops Go To / Develop.
. "$PSScriptRoot\..\..\scripts\common.ps1"
$dir = "$env:ProgramFiles\Nilesoft Shell"
if (-not (Test-Path "$dir\shell.exe")) {
  # pinned to 1.9.18 - the .nss files here are written for it
  foreach ($x in @(@{u='https://nilesoft.org/download/shell/1.9.18/setup-x64.msi'; t='msi'},
                   @{u='https://nilesoft.org/download/shell/1.9.18/setup.exe';     t='exe'})) {
    $f = Join-Path $TempDir "nilesoft-setup.$($x.t)"
    try { Invoke-WebRequest $x.u -OutFile $f -UseBasicParsing } catch { continue }
    if ((Get-Item $f).Length -lt 500000) { continue }
    if ($x.t -eq 'msi') { try { Install-Msi $f } catch { continue } } else { Start-Process $f -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -Wait }
    if (Test-Path "$dir\shell.exe") { break }
  }
}
if (-not (Test-Path "$dir\shell.exe")) { Warn 'Nilesoft Shell could not be installed'; return }
foreach ($f in "$dir\shell.nss", "$dir\imports\terminal.nss", "$dir\imports\theme.nss") {
  if ((Test-Path $f) -and -not (Test-Path "$f.original")) { Copy-Item $f "$f.original" }
}
Copy-Item "$PSScriptRoot\theme.nss"    "$dir\imports\theme.nss"    -Force
Copy-Item "$PSScriptRoot\terminal.nss" "$dir\imports\terminal.nss" -Force
Copy-Item "$PSScriptRoot\shell.nss"    "$dir\shell.nss"            -Force
& "$dir\shell.exe" -register -treat -silent
Ok 'crimson right-click menu'
