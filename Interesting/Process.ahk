
#Persistent
#SingleInstance, force
F12::
ReloadAllAhkScripts() {
    DetectHiddenWindows, On
    SetTitleMatchMode, 2
    WinGet, allAhkExe, List, ahk_class AutoHotkey
    Loop, % allAhkExe {
        hwnd := allAhkExe%A_Index%
        if (hwnd = A_ScriptHwnd)  ; ignore the current window for reloading
        {
            continue
        }
        PostMessage, 0x0405, 65303,,, % "ahk_id" . hwnd
        MsgBox, % hwnd . " " . ErrorLevel
    }
    Reload
}