# Crimson glass icons for drives, folders, This PC, Network, Recycle Bin
# and the user folders (Desktop, Documents, Downloads...).
. "$PSScriptRoot\..\..\scripts\common.ps1"
$ico = "$DataDir\icons"
New-Item -ItemType Directory -Force $ico | Out-Null
Copy-Item "$PSScriptRoot\*.ico" $ico -Force

# drives + plain folders (machine-wide)
$di = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons'
foreach ($l in [char[]]'CDEFGHIJ') {
  $file = if ($l -eq 'C') { 'drive-system.ico' } else { 'drive.ico' }
  New-Item -Path "$di\$l\DefaultIcon" -Force | Out-Null
  Set-ItemProperty "$di\$l\DefaultIcon" '(default)' "$ico\$file"
}
$si = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons'
New-Item -Path $si -Force | Out-Null
Set-ItemProperty $si '3' "$ico\folder.ico,0"
Set-ItemProperty $si '4' "$ico\folder-open.ico,0"

# user folders
$kf = @{
  '{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}' = 'desktop.ico'
  '{FDD39AD0-238F-46AF-ADB4-6C85480369C7}' = 'documents.ico'
  '{374DE290-123F-4565-9164-39C4925E467B}' = 'downloads.ico'
  '{33E28130-4E1E-4676-835A-98395C3BC3BB}' = 'pictures.ico'
  '{4BD8D571-6D19-48D3-BE97-422220080E43}' = 'music.ico'
  '{18989B1D-99B5-455B-841C-AB7C74E4DDFC}' = 'videos.ico'
}
foreach ($id in $kf.Keys) {
  $k = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\$id"
  if (Test-Path $k) {
    $old = (Get-ItemProperty $k -ErrorAction SilentlyContinue).Icon
    if ($old -and -not (Get-ItemProperty $k -Name 'IconBeforeRyu' -ErrorAction SilentlyContinue)) { Set-ItemProperty $k 'IconBeforeRyu' $old }
    Set-ItemProperty $k 'Icon' "$ico\$($kf[$id]),0"
  }
}

# This PC entries, Network, Recycle Bin (per user)
$pc = @{
  '{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}' = 'desktop.ico'
  '{d3162b92-9365-467a-956b-92703aca08af}' = 'documents.ico'; '{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}' = 'documents.ico'
  '{088e3905-0323-4b02-9826-5d99428e115f}' = 'downloads.ico'; '{374DE290-123F-4565-9164-39C4925E467B}' = 'downloads.ico'
  '{24ad3ad4-a569-4530-98e1-ab02f9417aa8}' = 'pictures.ico';  '{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}' = 'pictures.ico'
  '{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}' = 'music.ico';     '{1CF1260C-4DD0-4ebb-811F-33C572699FDE}' = 'music.ico'
  '{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}' = 'videos.ico';    '{A0953C92-50DC-43bf-BE83-3742FED03C9C}' = 'videos.ico'
  '{20D04FE0-3AEA-1069-A2D8-08002B30309D}' = 'thispc.ico'
  '{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}' = 'network.ico'
  '{679f85cb-0220-4080-b29b-5540cc05aab6}' = 'quickaccess.ico'
}
foreach ($c in $pc.Keys) {
  foreach ($root in 'HKCU:\Software\Classes\CLSID', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CLSID') {
    New-Item -Path "$root\$c\DefaultIcon" -Force | Out-Null
    Set-ItemProperty "$root\$c\DefaultIcon" '(default)' "$ico\$($pc[$c]),0"
  }
}
$rb = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}\DefaultIcon'
New-Item -Path $rb -Force | Out-Null
Set-ItemProperty $rb '(default)' "$ico\recyclebin-empty.ico,0"
Set-ItemProperty $rb 'empty' "$ico\recyclebin-empty.ico,0"
Set-ItemProperty $rb 'full' "$ico\recyclebin-full.ico,0"

Clear-IconCache
Ok 'crimson icons'
