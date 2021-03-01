<# : cmd portion
powershell -noprofile "Invoke-Expression (${%~f0} | Out-String)"
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
