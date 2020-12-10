@echo off
cd /d "%~dp0"

if "%*"  NEQ "" echo %*
if "%*" EQU "" call %0 test
if "%~1" EQU "" goto:eof

call:doIt %1

if "%VSCODE_PID%" EQU "" pause
goto:eof

:doIt
echo %*
goto:eof

