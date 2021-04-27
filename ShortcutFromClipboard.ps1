param($dir = (Join-Path -Path $env:USERPROFILE -ChildPath 'Desktop'))

&start winword

$word = New-Object -ComObject "Word.Application"
$word.Visible = $true
&taskkill -im winword.exe
Return

$clp = Get-Clipboard;
$dir | Out-Host
$clp | Out-Host;

$leaf = ($clp | Split-Path -Leaf -ErrorAction SilentlyContinue); 
$leaf | Out-Host;

$lnkName = $leaf;

$invalidChars = [io.path]::GetInvalidFileNamechars();
$lnkName = ($lnkName -replace "[$invalidChars]","-") + ".lnk"
while($lnkName -match '.*--.*'){   $lnkName = ($lnkName -replace "--","-")}
while($lnkName -match '.*-_.*'){   $lnkName = ($lnkName -replace "-_","-")}
while($lnkName -match '.*_-.*'){   $lnkName = ($lnkName -replace "_-","-")}
while($lnkName -match '.*-\..*'){   $lnkName = ($lnkName -replace "-\.","-")}
while($lnkName -match '.*\.-.*'){   $lnkName = ($lnkName -replace "\.-","-")}
$lnkName | Out-Host;

$lnkPath = (Join-Path -Path $dir -ChildPath $lnkName);

$ws =  New-Object -comObject WScript.Shell;
$lnk = $ws.CreateShortcut($lnkPath);
$lnk.TargetPath = [string]$clp;
$lnk.WorkingDirectory = $dir;
# $lnk.Arguments = %arg%;
# $lnk.Description = "My Application";
# $lnk.IconLocation = "%ico%";
$lnk.Save();

$h = (Get-Item -Path $lnkPath).Handle;
$h |Out-Host;

