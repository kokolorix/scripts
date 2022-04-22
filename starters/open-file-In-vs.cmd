
@echo off
set file=%~1
set line=%~2
set column=%~3

if "%file%" EQU "" set file=C:\Dev\Work\ProdXE7\Basis\Module\DataDic\UserDomFm.cpp
if "%line%" EQU "" set line=100
if "%column%" EQU "" set column=30

echo %file% %line% %column%

set vbs=tmp.vbs
echo.> %vbs%
echo filename = WScript.Arguments(0) >>%vbs%
echo line = WScript.Arguments(1) >>%vbs%
echo column = WScript.Arguments(2) >>%vbs%
echo.>> %vbs%
echo On Error Resume Next >>%vbs%
echo Err.Clear >>%vbs%
echo Set dte = getObject(,"VisualStudio.DTE.16.0") >>%vbs%
echo.>> %vbs%
echo If Err.Number ^<^> 0 Then >>%vbs%
echo     Set dte = WScript.CreateObject("VisualStudio.DTE") >>%vbs%
echo     Err.Clear >>%vbs%
echo End If >>%vbs%
echo.>> %vbs%
echo dte.MainWindow.Activate >>%vbs%
echo dte.MainWindow.Visible = True >>%vbs%
echo dte.UserControl = True >>%vbs%
echo dte.ItemOperations.OpenFile filename >>%vbs%
echo dte.ActiveDocument.Selection.MoveToLineAndOffset line, column - 2 >>%vbs%

call cscript %vbs% "%file%" %line% %column%
erase %vbs%









@REM visual studio 2019 open file on line commandline"C:\Program Files (x86)\Common Files\Microsoft Shared\MSEnv\VSLauncher.exe" "%1"

set path=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE;%path%
devenv.exe /Command "Edit.GoTo 100" /Edit ""

@REM "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe" /Command "Edit.GoTo 100"
