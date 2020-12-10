@echo off
cd /d "%~dp0"

if "%*"  NEQ "" echo %*
if "%*" EQU "" call %0 a b c d e f g h i j k l m n o p  q r s t u v w x y z

:loop
if "%~1"=="" goto:eof
call:print %1
shift
goto:loop

:print
echo %1
goto:eof
