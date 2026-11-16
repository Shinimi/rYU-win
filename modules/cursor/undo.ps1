. "$PSScriptRoot\..\..\scripts\common.ps1"
$k = 'HKCU:\Control Panel\Cursors'
foreach ($n in 'Arrow','Help','AppStarting','Wait','Crosshair','IBeam','NWPen','No','SizeNS','SizeWE','SizeNWSE','SizeNESW','SizeAll','UpArrow','Hand','Pin','Person') {
  Set-ItemProperty $k -Name $n -Value '' -Type ExpandString
}
Set-ItemProperty $k '(default)' ''
Add-Type -Name Win -Namespace RyuCur -MemberDefinition '[DllImport("user32.dll")] public static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint d);'
[void][RyuCur.Win]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 3)
Ok 'Windows cursor back'
