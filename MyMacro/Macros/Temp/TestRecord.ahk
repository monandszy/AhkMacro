#SingleInstance force
#NoEnv
global SpdM, SpdR
OnMessage(0x040A, "HandleMultiplierUpdate")
HandleMultiplierUpdate(wParam, lParam, msg, hwnd) {
  SpdM := wparam = 0 ? lparam : lParam / (10 * wParam) ; Float Reconstruction
  MsgBox, PlaySpeedMultiplier updated %wParam% %lParam% %SpdM%
}
SpdR := 1
Loop, 1 
{
Sleep, 200 //SpdR
MouseClick,L, 6, 4,,, 
Sleep, 200 //SpdR
MsgBox, T
MouseClick,L, 6, 4,,, 
Sleep, 200 //SpdR
MouseClick,L, 6, 4,,, 
}