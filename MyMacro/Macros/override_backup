#SingleInstance force
#NoEnv
#Include C:\Users\Name\..My\VSCode\AutoHotKey\MyMacro/Macros/.shared.ahk
global SpdM, SpdR
OnMessage(0x040A, "HandleMultiplierUpdate")
HandleMultiplierUpdate(wParam, lParam, msg, hwnd) {
  SpdM := wparam = 0 ? lparam : lParam / (10 * wParam) ; Float Reconstruction
  MsgBox, PlaySpeedMultiplier updated   
}
nSpdR := 1
Loop, 1
{
}}Sleep, 200 //SpdR * SpdM
MouseClick,L, 6, 4,,, 
Sleep, 200 //SpdR * SpdM
MouseClick,L, 6, 4,,, 
