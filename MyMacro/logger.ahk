#InstallKeybdHook
#Persistent
#SingleInstance, force
#NoEnv
CoordMode, ToolTip

SetBatchLines, -1
DetectHiddenWindows on
SetTitleMatchMode, 2
Thread, NoTimers
SetWorkingDir %A_ScriptDir%
; global Coord := "Screen"

; global NewRecordFile = "TEST"
global ExcludedKeys := "F1,F2,F3,F4,F5,F6,F8,F9,F10,F11,F12"
global SpecialKeys := "NumpadLeft,NumpadRight,NumpadEnter,Home,End,PgUp,PgDn,Left,Right,Up,Down,Delete,Insert"
global ControlKeys := "Alt,Control,Shift,Win"
global MouseKeys := "LButton,RButton,MButton,XButton1,XButton2"
global PressedLog := []
global LogArr := []
global Aggregator := ""
global AggregateActionDelay := 100
global LoggerLogFile = A_ScriptDir . "/Log/LoggerLog.log"
;----------------------------------------------------
global LatestRecordName := "TestRecord"
global FileSaveMode := "Override"
global TimingMode := "Precise"
global LogOptions := []
; "LogColor,LogSleep,LogKeyboard,LogMouse,LogWindow,TimingMode,FileSaveMode,NewRecordPath"
; global LogOptions := ({
  ; (Join  
  ; "LogColor": False,
  ; "LogSleep": True,
  ; "LogKeyboard": True,
  ; "LogMouse": True,
  ; "LogWindow": False,
  ; "TimingMode": "",
  ; "FileSaveMode": "",
  ; "NewRecordPath": "",
; )})
;----------------------------------------------------
FileDelete %LoggerLogFile%
Log(name, text) {
  FileAppend, %name%:[%text%]`n, %LoggerLogFile%,
}
Log("DateTime", A_Now)

Unstuck() {
  ; Sometimes it stops registering hotkeys, this helps for some reason..?
}

;----------------------------------------------------
global WM_ON_LOGGER := 0x0401
global WM_OFF_LOGGER := 0x0402
global WM_PAUSE_LOGGER := 0x0403
global WM_RESUME_LOGGER := 0x0404
global WM_UPDATE_LOGGER := 0x0405
global WM_BROADCAST := 0x0406
OnMessage(WM_ON_LOGGER, "RecordStart")
OnMessage(WM_OFF_LOGGER, "RecordEnd")
OnMessage(WM_PAUSE_LOGGER, "Pause")
OnMessage(WM_RESUME_LOGGER, "Resume")
OnMessage(WM_UPDATE_LOGGER, "UpdateLogOptions")
;----------------------------------------------------

UpdateLogOptions(wParam, lParam, msg, hwnd) {
  ; Get the new options from wParam and lParam

  ; Parse the new options and update LogOptions
  Log("Update", wParam)
  Log("Update", lParam)
  Log("Update", msg)
  ; Loop, Parse, newLogOptions, `n
  ; {
  ;     RegExMatch(A_LoopField, "(\w+):(\w+)", match)
  ;     key := match1
  ;     value := match2 = "True"
  ;     LogOptions[key] := value
  ; }
}
;----------------------------------------------------

RecordStart(wParam, lParam, msg, hwnd) {
  ; Suspend, On
  LogArr := []
  Aggregator := ""
  ; RedirectLogKeyboard(LogOptions["LogKeyboard"])
  ; RedirectLogMouse(LogOptions["LogMouse"])
  
  ; SetTimer, FlushLog, 5000 
  ; Suspend, Off
  ; SetTimer, LogWindow, %f%
  ; if (f="On")
  ;   Gosub, LogWindow
}

RecordEnd(wParam, lParam, msg, hwnd) {
  ; RedirectLogKeyboard("Off")
  ; RedirectLogMouse("Off")
  ; If (TimingMode = "Aggregate")
  ;   LogAggregator()
  ; FlushLog()
  ; SetTimer, FlushLog, Off 
  ; Suspend, On
}

Pause(wParam, lParam, msg, hwnd) {
  Suspend, On
  FlushLog()
  SetTimer, FlushLog, Off 
}

Resume(wParam, lParam, msg, hwnd) {
  Suspend, Off
  SetTimer, FlushLog, 5000 
}

FlushLog() {
  global saveMode, LatestRecordPath
  for i, line in LogArr 
  {
    content .= line . "`n"
  }
  Log("Flush","")
  MsgBox, %content%
  FileAppend, %content%, %LatestRecordPath%
  LogArr := []
}

RedirectLogMouse(isEnabled) {
  ; VK 1,2,4,5,6
  For i, key in StrSplit(MouseKeys, ",") {
    vkey := Format("vk{:X}", GetKeyVK(key))
    Log("vkey", vkey)
    Hotkey, % "~*" vkey, LogDownMouseKey, %isEnabled% UseErrorLevel
    Hotkey, % "~*" vkey " Up", LogUpMouseKey, %isEnabled% 
  }
}

RedirectLogKeyboard(isEnabled) {
  vkey := Format("vk{:X}", 3) ; Missing VK3
  Hotkey, % "~*" vkey, LogDownControlKey, %isEnabled% UseErrorLevel
  Hotkey, % "~*" vkey " Up", LogUpControlKey, %isEnabled% UseErrorLevel

  Loop, 248 ; 254 VK exist total, skips mouse
  {
    vkey := Format("vk{:X}", A_Index + 6)
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
global TimingMode
  Unstuck()
  If (TimingMode != "Precise")
    Return
  vksc := SubStr(A_ThisHotkey, 3, -3)
  key := GetKeyName(vksc)
  ; Log("KeyUp", A_ThisHotkey " " vksc " " key)
  SendPreciseKey("Up", vksc, key)
}

LogHotKey() {
global TimingMode
  Unstuck()
  vksc := SubStr(A_ThisHotkey, 3)
  key := GetKeyName(vksc)
  ; Log("KeyDown", A_ThisHotkey " " vksc " " key)
  if(TimingMode = "Precise") {
    If (PressedLog[vksc] = "Down") 
      Return
    SendPreciseKey("Down", vksc, key)
    Return
  }
  else if(TimingMode = "Aggregate") {
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
  If (TimingMode = "Aggregate")
    LogAggregator()
  vksc := SubStr(A_ThisHotkey, 3)
  key := GetKeyName(vksc)
  If (PressedLog[vksc] = "Down") 
    Return
  key := StrReplace(key, "Control", "Ctrl")
  SendPreciseKey("Down", vksc, key)
}

LogUpControlKey() {
  If (TimingMode = "Aggregate")
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
}

LogData(data) {
  static LastLogTime
  cTime := A_TickCount
  Delay := (LastLogTime ? cTime-LastLogTime : 0), LastLogTime := cTime
  i:=LogArr.MaxIndex(), 
  If (TimingMode = "Aggregate") {
    LogArr.Push("  Sleep, " . AggregateActionDelay . " //ps")  
  } else if (TimingMode = "Precise") {
    LogArr.Push("  Sleep, " . Delay . " //ps")
  }
  LogArr.Push(data)
}

LogUpMouseKey() {
  Unstuck()
  If (TimingMode != "Precise")
    Return
  vksc := SubStr(A_ThisHotkey, 3, -3)
  key := GetKeyName(vksc)
  clickType := SubStr(key,1,1)
  Log("LogUpMouseKey", clickType)
  SendMouseKey("U", vksc, clickType)
}

LogDownMouseKey() {
  Unstuck()
  vksc := SubStr(A_ThisHotkey, 3)
  key := GetKeyName(vksc)
  If (PressedLog[vksc] = "D") 
    Return
  clickType := SubStr(key,1,1)
  state := TimingMode = "Precise" ? "D" : ""
  SendMouseKey(state, vksc, clickType)
}

SendMouseKey(state, vksc, clickType) {
  PressedLog[vksc] := state
  CoordMode, Mouse, %CoordMode%
  MouseGetPos, X, Y, windowHwnd
  If (id = guiHwnds["Main"])
    Return
  formattedKey := clickType ", " X ", " Y ",,, " state
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
