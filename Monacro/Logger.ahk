#InstallKeybdHook
#Persistent
#SingleInstance, force
#NoEnv

SetBatchLines, -1
DetectHiddenWindows on
SetTitleMatchMode, 2
Thread, NoTimers
SetWorkingDir %A_ScriptDir%

;----------------------------------------------------
; Static Options
;----------------------------------------------------
global ExcludedKeys := "F1,F2,F3,F4,F5,F6,F8,F9,F10,F11" ; F12 left to you
global SpecialKeys := "NumpadLeft,NumpadRight,NumpadEnter,Home,End,PgUp,PgDn,Left,Right,Up,Down,Delete,Insert"
global ControlKeys := "Alt,Control,Shift,Win"
global MouseVK = [1,2,4,5,6]
global WheelVK = [156,157,158,159]
global AggregateLogDelay := 200
global SettingsPath := "settings.txt"
global LogColorSleep := 100
;----------------------------------------------------
; Loaded Options
;----------------------------------------------------
global WorkDir
global PlaySpeedRecord
global FileSaveMode
global NewRecordPath
global isLogKeyboard 
global isLogMouse 
global isLogSleep 
global isLogWindow 
global isLogColor 
global isAggregateMode 
global isPreciseMode 
global isAppendSaveMode
global isOverrideSaveMode
global isNewSaveMode
global MainGuiHwnd
global SharedPath
global CoordinateMode

LoadSettings() {
  Loop, Read, %SettingsPath%
  {
    if(Trim(A_LoopReadLine) = "" || InStr(A_LoopReadLine, ";") != 0)
      Continue
    option := StrSplit(A_LoopReadLine, ":",,2)
    label := option[1]
    %label% := option[2]
    ; Log("labelInit", label)
  }
}
;----------------------------------------------------
; Dynamic Options
;----------------------------------------------------
global PressedLog := []
global LogArr := []
global Aggregator := ""
global WheelAggregator := 0
global previousWheel := ""
global KeyboardAggregator := 0
global previousKey := ""
global StartTime
global ElapsedTime
;----------------------------------------------------
; global LoggerLogFile = ".Logs/LoggerLog.log"
; FileDelete %LoggerLogFile%
; Log(name, text) {
;   FileAppend, %name%:[%text%]`n, %LoggerLogFile%,
; }
; Log("DateTime", A_Now)
;----------------------------------------------------
global WM_ON_LOGGER := 0x0401
global WM_OFF_LOGGER := 0x0402
global WM_PAUSE_LOGGER := 0x0403
global WM_RESUME_LOGGER := 0x0404
global WM_TEST_LOGGER := 0x0405
OnMessage(WM_ON_LOGGER, "RecordStart")
OnMessage(WM_OFF_LOGGER, "RecordEnd")
OnMessage(WM_PAUSE_LOGGER, "Pause")
OnMessage(WM_RESUME_LOGGER, "Resume")
OnMessage(WM_TEST_LOGGER, "Test")
;----------------------------------------------------
Suspend, On
RedirectLogKeyboard("On")
RedirectLogMouse("On")
Return
;----------------------------------------------------
Unstuck() {
  ; For some reason this helps?
}

Test(wParam, lParam, msg, hwnd) {
  ; Log("Recived!", hwnd)
}

RecordStart(wParam, lParam, msg, hwnd) {
  StartTime := A_TickCount
  LoadSettings()
  InitFile()
  Suspend, Off
  LogArr := []
  Aggregator := ""
  SetTimer, FlushLog, 5000 
  if (isLogWindow) {
    SetTimer, LogWindow, 3000 
  }
}

RecordEnd(wParam, lParam, msg, hwnd) {
  ElapsedTime += A_TickCount - StartTime
  Suspend, On
  If (isAggregateMode) {
    LogAggregator()
    LogKeyAggregator()
  }
  FlushLog()
  SetTimer, LogWindow, Off
  SetTimer, FlushLog, Off 
  CloseFile()
}

Pause(wParam, lParam, msg, hwnd) {
  ElapsedTime += A_TickCount - StartTime
  Suspend, On
  FlushLog()
  SetTimer, LogWindow, Off
  SetTimer, FlushLog, Off 
}

Resume(wParam, lParam, msg, hwnd) {
  StartTime := A_TickCount
  SpdRBackup := PlaySpeedRecord
  LoadSettings()
  if (SpdRBackup != PlaySpeedRecord) {
    LogData("sR := " PlaySpeedRecord)
  }
  Suspend, Off
  SetTimer, FlushLog, 5000 
  if (isLogWindow) {
    SetTimer, LogWindow, 3000 
  }
}

InitFile() {
If (!FileExist(NewRecordPath)) {
content = 
(
; Recorded: %A_Now%
DetectHiddenWindows, On
SetTitleMatchMode, 2
CoordMode, Mouse, %CoordinateMode%
)
    FileAppend, %content%, %NewRecordPath%
  }
if (!isAppendSaveMode || !FileExist(NewRecordPath)) {
content =
(
#SingleInstance force
#NoEnv
#Include %SharedPath%
global sM := 1, sR, MainGuiHwnd
OnMessage(0x040A, "HandleMultiplierUpdate")
HandleMultiplierUpdate(wParam, lParam, msg, hwnd) {
  sM := wparam = 0 ? lparam : lParam / (10 * wParam) ; Float Reconstruction
}
sR := %PlaySpeedRecord%
Sleep, 200
Loop, 1
{

)
    FileAppend, %content%, %NewRecordPath%
} 
else if (isAppendSaveMode && FileExist(NewRecordPath)) {
content = 
(
    
; Appended: %A_Now%
CoordMode, Mouse, %CoordinateMode%
sR := %PlaySpeedRecord%
Sleep, 200
Loop, 1
{
)
FileAppend, %content%, %NewRecordPath%
  }
}



CloseFile() {
  val := "%"
content = 
(
}
; RecordingTime: %ElapsedTime%ms
PostMessage, 0x040B, 0,0,, %val% "ahk_id" MainGuiHwnd
ExitApp
)
  FileAppend, %content%, %NewRecordPath%
}

FlushLog() {
  global LogArr, NewRecordPath
  for i, line in LogArr 
  {
    content .= line "`n"
  }
  FileAppend, %content%, %NewRecordPath%
  LogArr := []
}

RedirectLogMouse(isEnabled) {
  ; VK 1,2,4,5,6
  For i, key in MouseVK {
    vkey := Format("vk{:X}", key)
    Hotkey, % "~*" vkey, LogDownMouseKey, %isEnabled% UseErrorLevel
    Hotkey, % "~*" vkey " Up", LogUpMouseKey, %isEnabled% 
  }
  For i, key in WheelVK {
    vkey := Format("vk{:X}", key)
    Hotkey, % "~*" vkey, LogWheel, %isEnabled% UseErrorLevel
  }
}

RedirectLogKeyboard(isEnabled) {
  Loop, 256 ; 256 VK exist total, skips mouse
  {
    if (hasValue(MouseVK, A_Index) || hasValue(WheelVK, A_Index)) {
      continue ; Skip mouse
    }
    vkey := Format("vk{:X}", A_Index)
    key := GetKeyName(vkey)
    If (!hasValue(ExcludedKeys, key) && key != "") {
      if(hasValue(ControlKeys, SubStr(key, 2))) {
        Hotkey, % "~*" vkey, LogDownControlKey, %isEnabled% UseErrorLevel
        Hotkey, % "~*" vkey " Up", LogUpControlKey, %isEnabled% UseErrorLevel
      }
      else {
        Hotkey, % "~*" vkey, LogHotKey, %isEnabled% UseErrorLevel
        Hotkey, % "~*" vkey " Up", LogUpHotKey, %isEnabled% UseErrorLevel
      } 
    }
  }
  For i, key in StrSplit(SpecialKeys, ",")
  {
    sc:=Format("sc{:03X}", GetKeySC(key))
    if (!hasValue(ExcludedKeys, key)) {
      Hotkey, % "~*" sc , LogHotKey, %isEnabled% UseErrorLevel
      Hotkey, % "~*" sc " Up", LogUpHotKey, %isEnabled% UseErrorLevel
    }
  }
}

LogUpHotKey() {
  If (!isLogKeyboard || !isPreciseMode)
    Return
  vksc := SubStr(A_ThisHotkey, 3, -3)
  key := GetKeyName(vksc)
  ; Log("KeyUp", A_ThisHotkey " " vksc " " key)
  SendPreciseKey("Up", vksc, key)
}

LogHotKey() {
global Aggregator
  If (!isLogKeyboard)
    Return
  vksc := SubStr(A_ThisHotkey, 3)
  key := GetKeyName(vksc)
  ; Log("KeyDown", A_ThisHotkey " " vksc " " key)
  if(isAggregateMode) {
    if (StrLen(key) = 1 && key~="\w") {
      Aggregator := Aggregator key
      Return ; Collect Words until interrupted
    }
    LogAggregator()
    LogNonLetter(vksc, key)
  }
  else if(isPreciseMode) {
    If (PressedLog[vksc] = "Down")
      Return
    SendPreciseKey("Down", vksc, key)
    Return
  }
}

LogNonLetter(vksc, key) {
  if !(previousKey = key) {
    LogKeyAggregator()
    previousKey := key
  } 
  KeyboardAggregator++
}

LogWheel() {
  If (!isLogMouse)
    Return
  vksc := SubStr(A_ThisHotkey, 3)
  key := GetKeyName(vksc)
  if (isPreciseMode) {
    LogData("Send," "{" key "}")
  } else if (isAggregateMode) {
    if !(previousWheel = key) {
      LogWheelAggregator()
      previousWheel := key
    } 
    WheelAggregator++
  }
} 

SendPreciseKey(state, vksc, key) {
  PressedLog[vksc] := state
  key := key " " state
  formattedKey := key ~= "\w" ? "{" key "}" : "{" vksc "}"
  LogData("Send, " + formattedKey)
}

; Controll keys always in Precise mode
LogDownControlKey() {
  If (!isLogKeyboard)
    Return
  vksc := SubStr(A_ThisHotkey, 3)
  If (PressedLog[vksc] = "Down") 
    Return
  If (isAggregateMode) {
    LogAggregator()
    LogKeyAggregator()
  }
  key := GetKeyName(vksc)
  key := StrReplace(key, "Control", "Ctrl")
  SendPreciseKey("Down", vksc, key)
}

LogUpControlKey() {
  If (!isLogKeyboard)
    Return
  If (isAggregateMode) {
    LogAggregator()
    LogKeyAggregator()
  }
  vksc := SubStr(A_ThisHotkey, 3, -3)
  key := GetKeyName(vksc)
  key := StrReplace(key, "Control", "Ctrl")
  SendPreciseKey("Up", vksc, key)
}

LogAggregator() {
  if (Aggregator != "") {
    LogData("Send, " Aggregator)
    Aggregator := ""
  }
}

LogWheelAggregator() {
  If (WheelAggregator != 0) {
    If (WheelAggregator = 1) {
      LogData("Send, {" previousWheel "}")
      WheelAggregator := 0
      previousWheel := ""
    } else {
      LogData("Loop, " WheelAggregator "`n  Send, {" previousWheel "}")
      WheelAggregator := 0
      previousWheel := ""
    }
  }
}

LogKeyAggregator() {
  If (KeyboardAggregator != 0) {
    If (KeyboardAggregator = 1) {
      LogData("Send, {" previousKey "}")
      KeyboardAggregator := 0
      previousKey := ""
    } else {
      LogData("Loop, " KeyboardAggregator "`n  Send, {" previousKey "}")
      KeyboardAggregator := 0
      previousKey := ""
    }
  }
}

LogUpMouseKey() {
  If (!isLogMouse || !isPreciseMode)
    Return
  vksc := SubStr(A_ThisHotkey, 3, -3)
  key := GetKeyName(vksc)
  clickType := SubStr(key,1,1)
  SendMouseKey("U", vksc, clickType)
}

LogDownMouseKey() {
  If (!isLogMouse)
    Return
  state := isPreciseMode ? "D" : ""
  vksc := SubStr(A_ThisHotkey, 3)
  key := GetKeyName(vksc)
  If (PressedLog[vksc] = "D") 
    Return
  clickType := SubStr(key,1,1)
  SendMouseKey(state, vksc, clickType)
}


SendMouseKey(state, vksc, clickType) {
  PressedLog[vksc] := state
  CoordMode, Mouse, %CoordinateMode%
  MouseGetPos, X, Y, windowHwnd
  If (windowHwnd = MainGuiHwnd) {
    Return
  }
  formattedKey := clickType ", " X ", " Y ",,, " state

  if (isLogColor) {
  PixelGetColor, color, X, Y, RGB
  delay := isAggregateMode ? 0 : 10
  data =
(
MouseMove, %X%, %Y%, %delay%
while (color != %color%) {
  Sleep, %LogColorSleep%  ; 
  PixelGetColor, color, %X%, %Y%, RGB
} MouseClick, %formattedKey%
)
  LogData(data)
  } else {
  LogData("MouseClick," formattedKey)
  }
  
}

LogData(data) {
  if(isLogSleep) {
    static LastLogTime
    cTime := A_TickCount
    Delay := (LastLogTime ? cTime-LastLogTime : 0), LastLogTime := cTime
    If (isAggregateMode) {
      LogArr.Push("Sleep, " AggregateLogDelay " //(sR*sM)")  
    } else if (isPreciseMode) {
      LogArr.Push("Sleep, " Delay " //(sR*sM)")
    }
  }
  LogArr.Push(data)
}


LogWindow() {
  If (!isLogWindow)
    Return
  static oldtitle, oldHwnd
  hwnd := WinExist("A")
  If (hwnd = MainGuiHwnd)
    return
  WinGetTitle, title, ahk_id %hwnd%
  WinGetClass, class, ahk_id %hwnd%
  if (title = "" && class = "")
    Return
  if (hwnd = oldHwnd && title = oldtitle)
    Return
  oldHwnd := hwnd
  oldtitle := title
  title := SubStr(title, 1, 50)

  if (!A_IsUnicode) {
    GuiControl,, MyText, %title%
    GuiControlGet, s,, MyText
    if (s != title)
      title := SubStr(title, 1, -1)
  }
  title := RegExReplace(Trim(title), "[``%;]", "``$0")
  data := "  tt = " title
    . "`n  WinWait, %tt%"
    . "`n  IfWinNotActive, %tt%,, WinActivate, %tt%"
    
  LogData(data)
}


; checks if item exists in a string
hasValue(list, item, del:=",") {
  if (item = "")
    Return False
	haystack:=del
	if !IsObject(list)
		haystack.= list del
	else
		for k,v in list
			haystack.= v del	
	Return !!InStr(del haystack del, del item del)
}
