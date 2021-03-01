<# : cmd portion
@echo off
cd /d "%~dp0"
<# : cmd portion
powershell -noprofile "Invoke-Expression (${%~f0} | Out-String)"

set wait=3
echo %~n0: %*

:loop
:: if no more arguments break the loop
if "%~1"=="" (
  goto:end
)
call:doIt %1
shift
goto:loop

goto:eof

:doIt
echo :doIt: %*
setlocal 

set path=C:\Users\srebe\AppData\Local\gmaster\bin;%path%
call start "" gmaster --path=%1

goto:eof

:end
:: Wenn mit Coderunner in VS-Code gestartet wurde, sofort beeenden
if not "%VSCODE_PID%"=="" goto:eof

:wait
choice /c wq /t %wait% /d q /m "W=pause, Q=quit(%wait%s)"
if errorlevel 2 goto:eof
if errorlevel 1 goto:exit
goto:eof

:exit
pause
goto:eof

: end cmd / begin powershell #>

$parentId = (Get-WmiObject Win32_Process | Where-Object { $_.ProcessId -eq $PID}).ParentProcessId;
$parentHandle = ((Get-Process -id $parentId)  | Select-Object MainWindowHandle).MainWindowHandle;

Set-Variable SW_MINIMIZE -Option Constant -Value 6;

$signature = @'
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@
$type = Add-Type -MemberDefinition $signature -Name ShowWindowName -Namespace ShowWindow -Using System.Text -PassThru

$type::ShowWindow($parentHandle, $SW_MINIMIZE);