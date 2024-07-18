#SingleInstance, force
global vk := "LButton" ; Replace "vkCodeHere" with the desired virtual key code
LogFile:="C:\Users\Name\Desktop\Temp\Record.txt"
EditorPath:="C:\Program Files\VSCodium\VSCodium.exe"  
If not A_IsAdmin
    Run *RunAs A_ScriptFullPath

SetWorkingDir %A_ScriptDir%

F1::
Open:
MsgBox, Cat
Run, "C:\Users\Name\..My\VSCode\AutoHotKey\Deprecated\test.txt"
Return

F5::
Edit:
Run,% """" EditorPath """ """ LogFile """"
return

