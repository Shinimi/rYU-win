# Lock + sign-in screen: your wallpaper, no blur (needs admin)
param([string]$Image)
. "$PSScriptRoot\..\..\scripts\common.ps1"
$here = $PSScriptRoot
if (-not $Image) {
  $local = Get-ChildItem $here -File -Include *.jpg,*.jpeg,*.png -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($local) { $Image = $local.FullName }
  else {
    # use the current desktop wallpaper (Windows keeps a JPEG copy of it)
    $tw = "$env:APPDATA\Microsoft\Windows\Themes\TranscodedWallpaper"
    $wp = (Get-ItemProperty 'HKCU:\Control Panel\Desktop').WallPaper
    if ($wp -and (Test-Path $wp) -and ($wp -match '\.(jpe?g|png|bmp)$')) { $Image = $wp }
    elseif (Test-Path $tw) { $tmpJ = Join-Path $env:TEMP 'ryu-lock.jpg'; Copy-Item $tw $tmpJ -Force; $Image = $tmpJ }
  }
}
if (-not $Image -or -not (Test-Path $Image)) { Warn 'no image found - put a lock.jpg in modules\lockscreen and run again'; return }
$dst = $DataDir; New-Item -ItemType Directory -Force $dst | Out-Null
$ext = [IO.Path]::GetExtension($Image)
$target = Join-Path $dst ("lock" + $ext)
Copy-Item $Image $target -Force
$p = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'
New-Item -Path $p -Force | Out-Null
Set-ItemProperty $p LockScreenImage $target
Set-ItemProperty $p LockScreenOverlaysDisabled 1 -Type DWord
$s = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
New-Item -Path $s -Force | Out-Null
Set-ItemProperty $s DisableAcrylicBackgroundOnLogon 1 -Type DWord
Set-ItemProperty $s DisableLogonBackgroundImage 0 -Type DWord
# no tips / spotlight text on lock screen
$cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
New-Item -Path $cdm -Force | Out-Null
Set-ItemProperty $cdm RotatingLockScreenEnabled 0 -Type DWord
Set-ItemProperty $cdm RotatingLockScreenOverlayEnabled 0 -Type DWord
Set-ItemProperty $cdm SubscribedContent-338387Enabled 0 -Type DWord
Ok "lock + sign-in screen: $Image (try Win+L)"
