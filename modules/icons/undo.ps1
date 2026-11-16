. "$PSScriptRoot\..\..\scripts\common.ps1"
$di = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons'
foreach ($l in [char[]]'CDEFGHIJ') { Remove-Item "$di\$l" -Recurse -Force -ErrorAction SilentlyContinue }
Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons' -Name '3','4' -ErrorAction SilentlyContinue
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions' | ForEach-Object {
  $old = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).IconBeforeRyu
  if ($old) { Set-ItemProperty $_.PSPath 'Icon' $old; Remove-ItemProperty $_.PSPath 'IconBeforeRyu' }
}
foreach ($root in 'HKCU:\Software\Classes\CLSID', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CLSID') {
  Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object {
    $k = Join-Path $_.PSPath 'DefaultIcon'
    $v = (Get-ItemProperty $k -ErrorAction SilentlyContinue).'(default)'
    if ($v -and $v -like "*\rYu\icons\*") { Remove-Item $k -Recurse -Force }
  }
}
Clear-IconCache
Ok 'default icons back (restart Explorer)'
