; Recorded: 20240721131343
  DetectHiddenWindows, On
  SetTitleMatchMode, 2
  CoordMode, Mouse, Window#SingleInstance force
#NoEnv
#Include C:\Users\Name\..My\VSCode\AutoHotKey\MyMacro\Macros\.shared.ahk
global sM := 1, sR, MainGuiHwnd
OnMessage(0x040A, "HandleMultiplierUpdate")
HandleMultiplierUpdate(wParam, lParam, msg, hwnd) {
  sM := wparam = 0 ? lparam : lParam / (10 * wParam) ; Float Reconstruction
}
sR := 1
Sleep, 200
Loop, 1
{
MouseClick,L, 561, 303,,, D
MouseClick,L, 561, 303,,, U
MouseClick,L, 568, 428,,, D
MouseClick,L, 568, 428,,, U
MouseClick,L, 593, 318,,, D
MouseClick,L, 593, 318,,, U
  tt = Temp.ahk - AutoHotKey - VSCodium
  WinWait, %tt%
  IfWinNotActive, %tt%,, WinActivate, %tt%
}
PostMessage, 0x040B, 0,0,, % "ahk_id" MainGuiHwnd
ExitApp
; RecordingTime: 20954ms; Recorded: 20240721131616
  DetectHiddenWindows, On
  SetTitleMatchMode, 2
  CoordMode, Mouse, WindowMouseClick,L, 836, 333,,, D
MouseClick,L, 840, 337,,, U
MouseClick,L, 832, 256,,, D
MouseClick,L, 832, 257,,, U
MouseClick,L, 840, 392,,, D
MouseClick,L, 840, 392,,, U
}
PostMessage, 0x040B, 0,0,, % "ahk_id" MainGuiHwnd
ExitApp
; RecordingTime: 22735msCoordMode, Mouse, WindowMouseClick,L, 769, 308,,, D
MouseClick,L, 773, 312,,, U
  tt = Main.ahk - AutoHotKey - VSCodium
  WinWait, %tt%
  IfWinNotActive, %tt%,, WinActivate, %tt%
}
; RecordingTime: 3907ms
PostMessage, 0x040B, 0,0,, % "ahk_id" MainGuiHwnd
ExitApp ; If appendMode last 2 lines will be removedCoordMode, Mouse, WindowMouseClick,L, 790, 198,,, D
MouseClick,L, 794, 202,,, U
MouseClick,L, 922, 315,,, D
MouseClick,L, 922, 315,,, U
}
; RecordingTime: 3594ms
PostMessage, 0x040B, 0,0,, % "ahk_id" MainGuiHwnd
ExitApp ; If appendMode last 2 lines will be removed
  ; Appended: 20240721141136
  CoordMode, Mouse, WindowMouseClick,L, 666, 211,,, D
MouseClick,L, 670, 215,,, U
MouseClick,L, 864, 323,,, D
MouseClick,L, 865, 323,,, U
MouseClick,L, 711, 192,,, D
MouseClick,L, 711, 192,,, U
}
; RecordingTime: 1656ms
PostMessage, 0x040B, 0,0,, % "ahk_id" MainGuiHwnd
ExitApp ; If appendMode last 2 lines will be removed