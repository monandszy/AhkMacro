#InstallKeybdHook
#Persistent
#SingleInstance, force
#NoEnv
; CoordMode, ToolTip

SetBatchLines, -1
DetectHiddenWindows on
SetTitleMatchMode, 2
Thread, NoTimers
SetWorkingDir %A_ScriptDir%
; global Coord := "Screen"

;----------------------------------------------------
; Static Options
;----------------------------------------------------
global ExcludedKeys := "F1,F2,F3,F4,F5,F6,F8,F9,F10,F11"
global SpecialKeys := "NumpadLeft,NumpadRight,NumpadEnter,Home,End,PgUp,PgDn,Left,Right,Up,Down,Delete,Insert"
global ControlKeys := "Alt,Control,Shift,Win"
global MouseVK = [1,2,4,5,6]
global WheelVK = [156,157,158,159]
global AggregateActionDelay := 100
global LoggerLogFile = A_ScriptDir . "/.Logs/LoggerLog.log"
global SettingsPath := A_ScriptDir . "/settings"
;----------------------------------------------------
; Loaded Options
;----------------------------------------------------
global WorkDir
global NewRecordName
global RecordFolderPath
global PlaySpeed
global FileSaveMode
global NewRecordPath
global LatestSelectPath
global LatestSelectName
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

LoadSettings() {
  Loop, Read, %SettingsPath%
  {
    option := StrSplit(A_LoopReadLine, ":",,2)
    label := option[1]
    %label% := option[2]
  }
}
;----------------------------------------------------
; Dynamic Options
;----------------------------------------------------
global PressedLog := []
global LogArr := []
global Aggregator := ""
global WheelAggregator := ""
global previousWheel := ""
;----------------------------------------------------
FileDelete %LoggerLogFile%
Log(name, text) {
  FileAppend, %name%:[%text%]`n, %LoggerLogFile%,
}
Log("DateTime", A_Now)
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
  Log("Recived!", hwnd)
}

RecordStart(wParam, lParam, msg, hwnd) {
  Log("Event","RecordStart")
  LoadSettings()
  Suspend, Off
  LogArr := []
  Aggregator := ""
  SetTimer, FlushLog, 5000 
}
; SetTimer, LogWindow, %f%
; if (f="On")
;   Gosub, LogWindow

RecordEnd(wParam, lParam, msg, hwnd) {
  Log("Event","RecordEnd")
  Suspend, On
  If (isAggregateMode)
    LogAggregator()
  FlushLog()
  SetTimer, FlushLog, Off 
}

Pause(wParam, lParam, msg, hwnd) {
  Log("Event", "Pause")
  Suspend, On
  FlushLog()
  SetTimer, FlushLog, Off 
}

Resume(wParam, lParam, msg, hwnd) {
  Log("Event","Resume")
  LoadSettings()
  Suspend, Off
  SetTimer, FlushLog, 5000 
}

FlushLog() {
  global LogArr, NewRecordPath
  MsgBox, % NewRecordPath
  if (!isAppendSaveMode) {
    content =
    (
#SingleInstance force
#NoEnv
ps := %PlaySpeed% `n
    )
  }
  content .= "Loop, 1 `n {`n"
  for i, line in LogArr 
  {
    content .= line . "`n"
    Log("Flush", line)
  }
  content .= "}"
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
  If (!isLogKeyboard)
    Return
  vksc := SubStr(A_ThisHotkey, 3)
  key := GetKeyName(vksc)
  ; Log("KeyDown", A_ThisHotkey " " vksc " " key)
  if(isPreciseMode) {
    If (PressedLog[vksc] = "Down") 
      Return
    SendPreciseKey("Down", vksc, key)
    Return
  }
  else if(isAggregateMode) {
    LogWheelAggregator()
    if (StrLen(key) = 1 && key~="\w") {
      Aggregator := Aggregator . key
      Return ; Collect Words until interrupted
    } 
    LogAggregator()
    formattedKey := StrLen(key)>1 ? "{" key "}" : "{" vksc "}"
    LogData("Send, " + formattedKey)
  }
}

SendPreciseKey(state, vksc, key) {
  PressedLog[vksc] := state
  key := key . " " . state
  formattedKey := key ~= "\w" ? "{" key "}" : "{" vksc "}"
  LogData("Send, " + formattedKey)
}

; Controll keys always in Precise mode
LogDownControlKey() {
  If (!isLogKeyboard)
    Return
  If (isAggreateMode)
    LogAggregator()
  vksc := SubStr(A_ThisHotkey, 3)
  key := GetKeyName(vksc)
  If (PressedLog[vksc] = "Down") 
    Return
  key := StrReplace(key, "Control", "Ctrl")
  SendPreciseKey("Down", vksc, key)
}

LogUpControlKey() {
  If (!isLogKeyboard)
    Return
  If (isAggreateMode)
    LogAggregator()
  vksc := SubStr(A_ThisHotkey, 3, -3)
  key := GetKeyName(vksc)
  key := StrReplace(key, "Control", "Ctrl")
  SendPreciseKey("Up", vksc, key)
}

LogAggregator() {
  If (Aggregator != "") {
    LogData("Send, " + Aggregator)
    Aggregator := ""
  }
  LogWheelAggregator()
}

LogWheelAggregator() {
  If (WheelAggregator > 0) {
    LogData("Loop, " WheelAggregator "`n  Send, {" previousWheel "}")
    WheelAggregator := 0
    previousWheel := ""
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
  CoordMode, Mouse, %CoordMode%
  MouseGetPos, X, Y, windowHwnd
  GuiControl, Disable, %windowHwnd%
  ControlGetPos, X, Y, w, h, , ahk_id %windowHwnd%
  If (windowHwnd = MainGuiHwnd) {
    Return
  }
  formattedKey := clickType ", " X ", " Y ",,, " state
  LogData("MouseClick," . formattedKey)
}

; LogWindow() {
;   global oldid, LogArr
;   static oldtitle
;   id:=WinExist("A")
;   WinGetTitle, title
;   WinGetClass, class
;   if (title="" and class="")
;     return
;   if (id=oldid and title=oldtitle)
;     return
;   oldid:=id, oldtitle:=title
;   title:=SubStr(title,1,50)
;   if (!A_IsUnicode)
;   {
;     GuiControl,, MyText, %title%
;     GuiControlGet, s,, MyText
;     if (s!=title)
;       title:=SubStr(title,1,-1)
;   }
;   title.=class ? " ahk_class " class : ""
;   title:=RegExReplace(Trim(title), "[``%;]", "``$0")
;   ;~ s:="tt = " title "`nWinWait, %tt%"
;     ;~ . "`nIfWinNotActive, %tt%,, WinActivate, %tt%"  
;   s:="      tt = " title "`n      WinWait, %tt%"
;     . "`n      IfWinNotActive, %tt%,, WinActivate, %tt%"    
;   i:=LogArr.MaxIndex(), r:=LogArr[i]
;   if InStr(r,"tt = ")=1
;     LogArr[i]:=s, Logg()
;   else
;     Logg(s)
; }

LogData(data) {
  if(isLogSleep) {
    static LastLogTime
    cTime := A_TickCount
    Delay := (LastLogTime ? cTime-LastLogTime : 0), LastLogTime := cTime
    If (isAggregateMode) {
      Log("AD", AggregateActionDelay)
      LogArr.Push("Sleep, " AggregateActionDelay " //ps")  
    } else if (isPreciseMode) {
      Log("D", Delay)
      LogArr.Push("Sleep, " Delay " //ps")
    }
  }
  LogArr.Push(data)
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
