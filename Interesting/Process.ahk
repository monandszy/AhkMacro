#Persistent
#SingleInstance, force

SetBatchLines, -1
Thread, NoTimers
DetectHiddenWindows, On
SetTitleMatchMode, 2
DetectHiddenText, On
SetWorkingDir %A_ScriptDir%

global LatestSelectPath := "C:\Users\Name\..My\VSCode\AutoHotKey\MyMacro\Macros\TestRecord.ahk"
F12::
ReloadAllAhkScripts() {
    DetectHiddenWindows, On
    SetTitleMatchMode, 2
    WinGet, allAhkExe, List, ahk_class AutoHotkey
    Loop, % allAhkExe 
    {
    hwnd := allAhkExe%A_Index%
    if (hwnd = A_ScriptHwnd)  ; ignore the current window for reloading
        {
            continue
        }
        PostSpeedMultiplier(hwnd)
        MsgBox, % hwnd . " " . ErrorLevel
    }
    Get()
}

; PostPlayToggleMessage(hwnd) {
;     PostMessage, 0x111, 65306,0,, % "ahk_id" . hwnd
; }
  
PostSpeedMultiplier(hwnd) {
    PostMessage, 0x040A, 1,11,, % "ahk_id" . hwnd
}


Get() {
    MsgBox, cat
    WinGet, LoggerPID, PID, % LoggerPath
    WinGet, cPlayingPID, PID, % LatestSelectPath
    cPlayingHwnd := WinExist("ahk_pid" . cPlayingPID)
    MsgBox, % cPlayingHwnd ; Does not equal the triggered one
    PostSpeedMultiplier(cPlayingHwnd)
}