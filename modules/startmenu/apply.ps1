# Open-Shell start menu: Windows 7 layout, dark, near-black glass, no "recently added" noise.
. "$PSScriptRoot\..\..\scripts\common.ps1"
$sm = "$env:ProgramFiles\Open-Shell\StartMenu.exe"
if (-not (Test-Path $sm)) {
  $setup = Get-ReleaseAsset 'Open-Shell/Open-Shell-Menu' '^OpenShellSetup_.*\.exe$'
  Start-Process $setup -ArgumentList '/qn ADDLOCAL=StartMenu' -Wait
}
$k = 'HKCU:\Software\OpenShell\StartMenu\Settings'
New-Item -Path $k -Force | Out-Null
function D($n, $v) { Set-ItemProperty $k -Name $n -Value $v -Type DWord }
D 'MenuStyle' 2
Set-ItemProperty $k 'SkinW7' 'Immersive' -Type String
Set-ItemProperty $k 'SkinOptionsW7' @('LIGHT=0','DARK=1','AUTO=0','USER_IMAGE=1','USER_NAME=0','CENTER_NAME=0','SMALL_ICONS=0','OPAQUE=0','DISABLE_MASK=0','BLACK_TEXT=0','BLACK_FRAMES=0','TRANSPARENT_LESS=0','TRANSPARENT_MORE=1') -Type MultiString
D 'EnableStartButton' 0
D 'WinKey' 1
D 'HighlightNew' 0
D 'HighlightNewApps' 0
D 'RecentPrograms' 0
D 'MenuShadow' 1
D 'EnableGlass' 1
D 'GlassOverride' 1
D 'GlassColor' 0x00080510
D 'GlassIntensity' 100
D 'GlassBlending' 100
D 'GlassOpacity' 85
D 'MainMenuAnimation' 2
D 'MenuFadeSpeed' 200
if (Test-Path $sm) { Start-Process $sm -ArgumentList '-reloadsettings'; Ok 'Open-Shell start menu' }
else { Warn 'Open-Shell did not install' }
