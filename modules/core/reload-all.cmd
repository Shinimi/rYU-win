@echo off
rem Restart the bar and the borders.
taskkill /im yasb.exe /f >nul 2>&1
taskkill /im tacky-borders.exe /f >nul 2>&1
ping -n 3 127.0.0.1 >nul
rem Start YASB through Explorer so it runs as a normal app even when GlazeWM runs as admin.
rem (An admin bar can't receive tray icons from normal apps.)
start "" explorer.exe "%ProgramFiles%\YASB\yasb.exe"
for /f "delims=" %%F in ('where /r "%LOCALAPPDATA%\tacky-borders" tacky-borders.exe 2^>nul') do start "" "%%F"
