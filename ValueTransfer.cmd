@echo off
:: Jump to label on %1 and end
if not "%~1"=="" call%*&goto:eof

:: the main script part
:main
echo.

start notepad
powershell -command "(gps|where { $_.ProcessName -eq 'notepad'} ).Path" | %~n0 :show Hello
powershell -command "(gps|where { $_.ProcessName -eq 'notepad'} ).Id" | %~n0 :kill

goto:eof

:kill
setlocal
set /p input=""
echo.%input% %*
call taskkill -pid %input%>nul
goto:eof

:show
setlocal
set /p input=""
echo.%input% %*
goto:eof

