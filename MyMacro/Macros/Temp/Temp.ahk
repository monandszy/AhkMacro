#SingleInstance force
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
Sleep, 0 //(sR*sM)
  tt = logger.ahk - AutoHotKey - VSCodium
  WinWait, %tt%
  IfWinNotActive, %tt%,, WinActivate, %tt%
}
PostMessage, 0x040B, 0,0,, % "ahk_id" MainGuiHwnd
ExitApp
; RecordingTime: 5656