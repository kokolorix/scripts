<# : cmd portion

@echo off

call:getPID pid
call :ShowWindow %pid%
@REM powershell -file .\ShowWindow.ps1 %pid% 6
pause

goto:eof

:getPID  [RtnVar]
::
:: Store the Process ID (PID) of the currently running script in environment variable RtnVar.
:: If called without any argument, then simply write the PID to stdout.
::
setlocal disableDelayedExpansion
:getLock
set "lock=%temp%\%~nx0.%time::=.%.lock"
set "uid=%lock:\=:b%"
set "uid=%uid:,=:c%"
set "uid=%uid:'=:q%"
set "uid=%uid:_=:u%"
setlocal enableDelayedExpansion
set "uid=!uid:%%=:p!"
endlocal & set "uid=%uid%"
2>nul ( 9>"%lock%" (
  for /f "skip=1" %%A in (
    'wmic process where "name='cmd.exe' and CommandLine like '%%<%uid%>%%'" get ParentProcessID'
  ) do for %%B in (%%A) do set "PID=%%B"
  (call )
))||goto :getLock
del "%lock%" 2>nul
endlocal & if "%~1" equ "" (echo(%PID%) else set "%~1=%PID%"
exit /b

:ShowWindow [pid]
:: :: this mysterious line passes all arguments as $argv to the powershell script part
diese geheimnisvolle Zeile übergibt alle argumente als $argv an den powershell script Teil
(for %%I in ("%~f0";%*) do @echo(%%~I) | powershell -noprofile "$argv = $input | ?{$_}; iex (${%~f0} | out-string)"
goto:eof
: end cmd / begin powershell #>

$processId = $argv[1];

Set-Variable SW_MINIMIZE -Option Constant -Value 6;

$signature = @'
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@
$type = Add-Type -MemberDefinition $signature -Name ShowWindowName -Namespace ShowWindow -Using System.Text -PassThru
$handle = ((Get-Process -id $processId)  | Select-Object MainWindowHandle).MainWindowHandle;

$type::ShowWindow($handle, $SW_MINIMIZE);
