<# : batch portion
@echo off & setlocal
Echo %*

(for %%I in ("%~f0";%*) do @echo(%%~I) | ^
powershell -noprofile "$argv = $input | ?{$_}; iex (${%~f0} | out-string)"

goto :EOF
: end batch / begin powershell #>

#"Result:"
#$argv | %{ "`$argv[{0}]: $_" -f $i++ }

$processId = $argv[1]
$x=$argv[2]
$y=$argv[3]
$cx=$argv[4]
$cy=$argv[5]
#param($processId=0, $x=2600, $y=-150, $cx=1000, $cy=500)

$signature = @'
[DllImport("user32.dll")]
public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
'@

$type = Add-Type -MemberDefinition $signature -Name SetWindowPosition -Namespace SetWindowPos -Using System.Text -PassThru
$handle = ((Get-Process -id $processId)  | Select-Object MainWindowHandle).MainWindowHandle;
$top = New-Object -TypeName System.IntPtr -ArgumentList (0)
$type::SetWindowPos($handle, $top, $x, $y, $cx, $cy, 0x0040)
