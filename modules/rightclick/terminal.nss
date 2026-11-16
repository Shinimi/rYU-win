// rYu: Terminal -> portable Windows Terminal, plus PowerShell and cmd
menu(type='*' where=(sel.count or wnd.is_taskbar or wnd.is_edit) title=title.terminal sep='top' image=icon.run_with_powershell)
{
	$tip_run_admin=["\xE1A7 Press SHIFT key to run " + this.title + " as administrator", tip.warning, 1.0]
	$has_admin=key.shift() or key.rbutton()
	$wt_path=user.localappdata + '\Programs\WindowsTerminal\wt.exe'

	item(where=path.exists(wt_path) title='Terminal' tip=tip_run_admin admin=has_admin image=icon.run_with_powershell cmd=wt_path arg='-d "@sel.dir\."')
	item(title=title.windows_powershell admin=has_admin tip=tip_run_admin image cmd='powershell.exe' args='-noexit -command Set-Location -Path "@sel.dir\."')
	item(title=title.command_prompt tip=tip_run_admin admin=has_admin image cmd='cmd.exe' args='/K PUSHD "@sel.dir"')
}
