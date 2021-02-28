param($processId=0, $x=2600, $y=-150, $cx=1000, $cy=500)

"Id: $processId, x: $x, y: $y, cx: $cx, cy: $cy" | Out-Host;

$signature = @'
[DllImport("user32.dll")]
public static extern bool SetWindowPos(
    IntPtr hWnd,
    IntPtr hWndInsertAfter,
    int X,
    int Y,
    int cx,
    int cy,
    uint uFlags);
'@

$type = Add-Type -MemberDefinition $signature -Name SetWindowPosition -Namespace SetWindowPos -Using System.Text -PassThru

# $processId = (Get-WmiObject Win32_Process | Where-Object { $_.Name -eq 'WindowsTerminal.exe' -and $_.CommandLine -match '.+Identity-Backend.+'} | Select-Object ProcessId).ProcessId;
$handle = ((Get-Process -id $processId)  | Select-Object MainWindowHandle).MainWindowHandle;

# $alwaysOnTop = New-Object -TypeName System.IntPtr -ArgumentList (-1)
$top = New-Object -TypeName System.IntPtr -ArgumentList (0)
# $type::SetWindowPos($handle, $alwaysOnTop, 0, 0, 0, 0, 0x0003)
$type::SetWindowPos($handle, $top, $x, $y, $cx, $cy, 0x0040)
