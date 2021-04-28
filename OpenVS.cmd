@echo off
echo %cd% %*
cd /d "%~dp1"

if exist Erstelle-VisualStudio-Solution.cmd call:make-projects "%~dpn1.groupproj"

start "Start VisualStudio ..." "%~dpn1.sln"
REM pause
goto:eof

:make-projects
if exist %1 call Erstelle-VisualStudio-Solution "%~1"
