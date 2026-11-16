# Bibata Modern recolored crimson. Run with -Large for the bigger size.
param([switch]$Large)
. "$PSScriptRoot\..\..\scripts\common.ps1"
$size = if ($Large) { 'Large' } else { 'Regular' }
$dst = "$env:LOCALAPPDATA\Cursors\Bibata-Modern-Crimson"
New-Item -ItemType Directory -Force $dst | Out-Null
Copy-Item "$PSScriptRoot\$size\*" $dst -Force
$map = [ordered]@{
  Arrow='Pointer.cur'; Help='Help.cur'; AppStarting='Work.ani'; Wait='Busy.ani'; Crosshair='Cross.cur'
  IBeam='Text.cur'; NWPen='Handwriting.cur'; No='Unavailable.cur'; SizeNS='Vert.cur'; SizeWE='Horz.cur'
  SizeNWSE='Dgn1.cur'; SizeNESW='Dgn2.cur'; SizeAll='Move.cur'; UpArrow='Alternate.cur'; Hand='Link.cur'
  Pin='Pin.cur'; Person='Person.cur'
}
$k = 'HKCU:\Control Panel\Cursors'
foreach ($n in $map.Keys) { Set-ItemProperty $k -Name $n -Value "$dst\$($map[$n])" -Type ExpandString }
Set-ItemProperty $k '(default)' 'Bibata Modern Crimson'
New-Item -Path "$k\Schemes" -Force | Out-Null
Set-ItemProperty "$k\Schemes" 'Bibata Modern Crimson' (($map.Values | ForEach-Object { "$dst\$_" }) -join ',')
Add-Type -Name Win -Namespace RyuCur -MemberDefinition '[DllImport("user32.dll")] public static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint d);'
[void][RyuCur.Win]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 3)
Ok "crimson cursor ($size)"
