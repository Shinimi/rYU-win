# Turns Windows' own animations back on (open/close/min/max fades, menu and
# tooltip fades, smooth scrolling). A lot of debloat guides switch these off.
# Run with -Off to switch them off again. Same switch as the GlazeWM tray menu.
param([switch]$Off)
. "$PSScriptRoot\..\..\scripts\common.ps1"
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class RyuSpi {
  [StructLayout(LayoutKind.Sequential)] public struct ANIMATIONINFO { public uint cbSize; public int iMinAnimate; }
  [DllImport("user32.dll", EntryPoint="SystemParametersInfoW")] public static extern bool SetAnim(uint a, uint b, ref ANIMATIONINFO c, uint d);
  [DllImport("user32.dll", EntryPoint="SystemParametersInfoW")] public static extern bool SetBool(uint a, uint b, IntPtr c, uint d);
}
"@
$on = if ($Off) { 0 } else { 1 }
$ai = New-Object RyuSpi+ANIMATIONINFO
$ai.cbSize = 8; $ai.iMinAnimate = $on
[void][RyuSpi]::SetAnim(0x0049, 8, [ref]$ai, 3)
foreach ($a in 0x103F, 0x1043, 0x1003, 0x1013, 0x1005, 0x1007, 0x1017, 0x1019, 0x1015) {
  [void][RyuSpi]::SetBool($a, 0, [IntPtr]$on, 3)
}
$ve = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
New-Item $ve -Force | Out-Null
Set-ItemProperty $ve VisualFXSetting 3 -Type DWord
if ($on) { Ok 'window animations on' } else { Ok 'window animations off' }
