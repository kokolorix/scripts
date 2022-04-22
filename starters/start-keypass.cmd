@echo off
:: utf-8 codepage
@REM chcp 65001

call taskkill.exe -f -im "KeePass.exe">nul

start "" "C:\BI\Tools\KeyPass\KeePass.exe" "\\SRV-APP02.brunnerinfo.local\Apps\Passw”rter\KeePass\Data\NextGen.kdbx"

@REM start "" "\\SRV-APP02.brunnerinfo.local\Apps\Passw”rter\KeePass\Data\NextGen.kdbx"
call:wait-to-wnd "NextGen.kdbx.*KeePass"


start "" "\\SRV-APP02.brunnerinfo.local\Apps\Passw”rter\KeePass\Data\resi.kdbx"
call:wait-to-wnd "resi.kdbx.*KeePass"

goto:eof



:wait-to-wnd <regex for title>
echo wait to '%~1'
set path=%~dp0\nircmd;%path%
@REM pause

:wait
<nul set /p "=-"

set res="%temp%\9dbbbe4d-a5e5-4169-94d7-b0c77b8edd06"
cmdow /T | findstr "%~1" > %res%
set /p wnd=<%res%
erase %res%

call nircmd wait 1000
if ""=="%wnd%" goto:wait

goto:eof