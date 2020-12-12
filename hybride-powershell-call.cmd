<# : batch part
@echo off & setlocal
cd /d "%~dp0"

if "%*" equ "" call %0 a b
if "%*" neq "" echo cmd args: %*
if "%~1" equ "" goto:eof

goto:Call-ps1
@REM goto:Invoke-Expression

:Invoke-Expression
(for %%i in ("%~f0";%*) do @echo(%%~i) | ^
powershell -noprofile "$args = $input | ?{$_}; iex (${%~f0} | Out-String)"
goto:end

:Call-ps1
@REM if exist "%~dpn0.ps1" call erase "%~dpn0.ps1"
@REM call mklink /h "%~dpn0.ps1" "%~0">nul
type "%~0">"%~dpn0.ps1"
@REM echo call powershell -noprofile -file "%~dpn0.ps1" %*
call powershell -noprofile -file "%~dpn0.ps1" %*
@REM call erase "%~dpn0.ps1"
goto:end

@REM call:doIt %*
:end
if "%VSCODE_PID%" equ "" pause
goto:eof

:doIt
@REM echo %* 

@REM (for %%i in ("%~f0";%*) do @echo(%%~i) | ^
@REM powershell -noprofile "$argv = $input | ?{$_}; iex (${%~f0} | Out-String)"
goto:eof
: end batch / begin powershell #>

# param($a, $b)
# $MyInvocation | Out-Host;
# $args  = ('c');
# $args = $input;
"ps args:" 
$i = 0;
$args | ForEach-Object{ "`$args[{0}]: $_" -f $i++ };
#  Invoke-Expression























<#

@echo off
cd /d "%~dp0"

if "%*"  NEQ "" echo %*
if "%*" EQU "" call %0 test
if "%~1" EQU "" goto:eof

call:doIt %1

if "%VSCODE_PID%" EQU "" pause
goto:eof

#>