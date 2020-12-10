param($lnk="MyShortcut.lnk", $target="cmd.exe", $arguments="/c pause")

Clear-Host
Set-Location (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)

$wsh = New-Object -comObject WScript.Shell
# $Shortcut = $wsh.CreateShortcut("$lnk")
# $Shortcut.TargetPath = $target
# $Shortcut.Arguments = $arguments
# $Shortcut.Save()

$sc = $wsh.CreateShortcut("infraDATA.lnk");
$sc.TargetPath | Out-Host
