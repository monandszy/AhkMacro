#SingleInstance force
SetWorkingDir %A_ScriptDir%
If not A_IsAdmin {
  Run *RunAs "%A_ScriptFullPath%"
  ExitApp
}

ExitHandler: 
  PID := DllCall("GetCurrentProcessId")
  RunWait, taskkill /pid %PID%,, hide