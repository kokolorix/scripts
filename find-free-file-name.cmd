
@echo off
cd /d "%~dp0"

if "%*" NEQ "" echo %*
:: empty call => call with test argument
if "%*" EQU "" call %0 temp\afile.txt
if "%~1"=="" goto:eof

:loop
:: if no more arguments break the loop
if "%~1"=="" (
  :: if not started in VSCode pause
  if "%VSCODE_PID%"=="" pause
  goto:eof
)
call:doIt %1
shift
goto:loop

:doIt <file>
call:find_free_file_name %1 file
echo write %file%
call echo.>"%file%"
call echo %file%>>"%file%"
goto:eof

:find_free_file_name <dateiName> <outVar>
@REM echo %*
for /l %%i in (1, 1, 99) do (
    call:check_path %1 %%i file
    if errorlevel 0 goto:out
)
:out
set %~2=%file%
exit /b 0 

:check_path <path> <num> <out>
@REM echo %*
set var=00%~2
set var=%var:~-2%
set ex=%~x1
set end=%var%%ex%
set file=%~dpn1-%end%
if not exist "%file%" (
    set %~3=%~dpn1-%end%
    exit /b 0 
  ) else (
    exit /b -1      
  )
