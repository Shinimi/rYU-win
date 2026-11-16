. "$PSScriptRoot\..\..\scripts\common.ps1"
Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name LockScreenImage,LockScreenOverlaysDisabled -ErrorAction SilentlyContinue
Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name DisableAcrylicBackgroundOnLogon,DisableLogonBackgroundImage -ErrorAction SilentlyContinue
Ok 'default lock screen back'
