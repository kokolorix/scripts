@echo off
powershell -window minimized -command ""
@REM echo "%~dpn0.ps1" %*
powershell -file "%~dpn0.ps1" %*
@REM pause