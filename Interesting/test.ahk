#SingleInstance, force
; Define the path you want to loop over
path := "C:\Users\Name\..My\VSCode\AutoHotKey\MyMacro"

; Loop over directories in the specified path
Loop, Files, %path%\*.*, D
{
    ; Get the full path of the current directory
    dirPath := A_LoopFileFullPath
    
    ; Get the name of the current directory
    dirName := A_LoopFileName

    ; Perform an action with each directory (e.g., display a message box)
    MsgBox, Directory found: %dirName% %dirPath% 
}