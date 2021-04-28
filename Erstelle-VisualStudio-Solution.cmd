@echo off

cd /d "%~dp0"
title %~dpn0 %~n1

set /a argc=0
for %%x in (%*) do (
	set /a argc+=1
	call :do-it %%x
)
REM echo %argc%
REM pause
if %argc%==0 call :do-it "Alles.groupproj"
goto:wait

:do-it
call powershell -File "%cd%\Tools\Generiere-VS-Projekte.ps1" "%cd%\%~n1.groupproj" 
goto:eof

:wait
set wait=2
choice /c wq /t %wait% /d q /m "W=pause, Q=quit(%wait%s)"
if errorlevel 2 goto:eof
if errorlevel 1 goto:exit

:exit
pause

