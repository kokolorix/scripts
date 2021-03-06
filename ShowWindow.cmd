<# : batch portion
@echo off & setlocal
Echo %*

(for %%I in ("%~f0";%*) do @echo(%%~I) | ^
powershell -noprofile "$argv = $input | ?{$_}; iex (${%~f0} | out-string)"

goto :EOF
: end batch / begin powershell #>

#"Result:"
#$argv | %{ "`$argv[{0}]: $_" -f $i++ }
$processId = $argv[1];
$nCmdShow = $argv[2];

$signature = @'
[DllImport("user32.dll")]
public static extern bool ShowWindow(
   IntPtr hWnd,
   int nCmdShow);
'@
$type = Add-Type -MemberDefinition $signature -Name ShowWindowName -Namespace ShowWindow -Using System.Text -PassThru

$handle = ((Get-Process -id $processId)  | Select-Object MainWindowHandle).MainWindowHandle;

Set-Variable SW_FORCEMINIMIZE -Option Constant -Value 11;
Set-Variable SW_HIDE -Option Constant -Value 0;
Set-Variable SW_MAXIMIZE -Option Constant -Value 3;
Set-Variable SW_MINIMIZE -Option Constant -Value 6;
Set-Variable SW_RESTORE -Option Constant -Value 9;
Set-Variable SW_SHOW -Option Constant -Value 5;
Set-Variable SW_SHOWDEFAULT -Option Constant -Value 10;
Set-Variable SW_SHOWMAXIMIZED -Option Constant -Value 3;
Set-Variable SW_SHOWMINIMIZED -Option Constant -Value 2;
Set-Variable SW_SHOWMINNOACTIVE -Option Constant -Value 7;
Set-Variable SW_SHOWNA -Option Constant -Value 8;
Set-Variable SW_SHOWNOACTIVATE -Option Constant -Value 4;
Set-Variable SW_SHOWNORMAL -Option Constant -Value 1;

$type::ShowWindow($handle, $nCmdShow);
