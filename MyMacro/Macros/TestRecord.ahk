#SingleInstance force
    #NoEnv
    ps := 1.0 
Loop, 1 
 {
  Sleep, 100 //ps
Loop, 7
  Send, {WheelDown}
  Sleep, 100 //ps
Loop, 6
  Send, {WheelUp}
  Sleep, 100 //ps
Loop, 6
  Send, {WheelDown}
  Sleep, 100 //ps
Loop, 6
  Send, {WheelUp}
}