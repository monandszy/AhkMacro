#InstallKeybdHook
#SingleInstance, force
#NoEnv

; global NewRecordFile = "TEST"
global ExcludedKeys := "F1,F2,F3,F4,F5,F6,F8,F9,F10,F11,F12"
global SpecialKeys := "NumpadLeft,NumpadRight,NumpadEnter,Home,End,PgUp,PgDn,Left,Right,Up,Down,Delete,Insert"
global ControlKeys := "Alt,Control,Shift,Win"
global MouseKeys := "LButton,RButton,MButton"
global PressedLog := []
global LogArr := ""
global Aggregator
global AggregateActionDelay := 100
global RecordBlock := False 
; global isLogKeyboard := False
; global isLogControl := False
; global isLogSpecial := False
; global isLogMouse := False
; global isLogColor := False
; global isLogWindow := False
; global isLogDelay := False
; global MyLogFile = A_ScriptDir . "/log.log"

; FileDelete %MyLogFile%
; Log(name, text) {
;   FileAppend, %name%:[%text%]`n, %MyLogFile%,
; }

; Record()
; return

; F7::
; StopTMP:
; Stop()
; return

RecordLog() {
  LogArr := []
  Aggregator := ""
  RedirectKeys("On")
  ; SetTimer, LogWindow, %f%
  ; if (f="On")
  ;   Gosub, LogWindow
}

StopLog() {
  RedirectKeys("Off")
  If (TimingMode = "Aggregate") {
    LogAggregator()
  } 
  FlushLog()
}

PauseLog() {
  RecordBlock := True
  FlushLog()
  SetTimer, FlushLog, Off 
}

ResumeLog() {
  RecordBlock := False
  SetTimer, FlushLog, 5000 
}

FlushLog() {
  global saveMode, LatestRecordPath
  for i, line in LogArr 
    content .= line . "`n"
  MsgBox, %content%
  FileAppend, %content%, %LatestRecordPath%
  LogArr := []
}

RedirectKeys(isEnabled) {
  Loop, 254 
  {
    vkey:=Format("vk{:X}", A_Index)
    key:=GetKeyName(vkey)
    if (!hasValue(ExcludedKeys, key) && key != "") {
      Hotkey, % "~*" vkey, LogHotKey, %isEnabled% UseErrorLevel
      Hotkey, % "~*" vkey " Up", LogUpHotKey, %isEnabled% UseErrorLevel
    }
  }
  For i,key in StrSplit(SpecialKeys, ",")
    {
    sc:=Format("sc{:03X}", GetKeySC(key))
    if (!hasValue(ExcludedKeys, key)) {
      Hotkey, % "~*" sc , LogHotKey, %isEnabled% UseErrorLevel
      Hotkey, % "~*" sc " Up", LogUpHotKey, %isEnabled% UseErrorLevel
    }
  }
  if (isEnabled = "On") {
    SetTimer, FlushLog, 5000 
  } else {
    SetTimer, FlushLog, Off 
  }
}

LogUpHotKey() {
  If (!TimingMode = "Precise" || RecordBlock)
    Return
  vksc := SubStr(A_ThisHotkey, 3, -3)
  key := GetKeyName(vksc)
  ; Log("KeyUp", A_ThisHotkey " " vksc " " key)
  if(hasValue(ControlKeys, SubStr(key, 2))) {
    key := StrReplace(key, "Control", "Ctrl")
    LogControlKey(key)
  }
  ; else if key in MouseKeys
  ; {
  ;   LogMouseKey(key)
  ; } 
  else {
    PressedLog.Remove(vksc)
    key := key . " Up"
    formattedKey := key ~= "\w" ? "{" key "}" : "{" vksc "}"
    LogKeyboard("Send, " + formattedKey)
  }
}
; Critical
LogHotKey() {
  If (RecordBlock)
    Return
  vksc := SubStr(A_ThisHotkey, 3)
  key := GetKeyName(vksc)
  ; Log("KeyDown", A_ThisHotkey " " vksc " " key)
  if(hasValue(ControlKeys, SubStr(key, 2))) {
    key := StrReplace(key, "Control", "Ctrl")
    LogControlKey(key)
  } 
  ; else if(key in LButton,RButton,MButton) {
  ;   LogMouseKey(key)
  ; } 
  ; else if ((key="NumpadLeft" || key="NumpadRight") && !GetKeyState(key,"P")){
  ;   return
  ; }
  else {
    if(TimingMode = "Precise") {
      If (PressedLog[vksc] = "D") 
        return ; Add to pressed down array to prevent duplicaiton
      PressedLog[vksc] := "D"
      key := key . " Down"
      formattedKey := key ~= "\w" ? "{" key "}" : "{" vksc "}"
    }
    else if(TimingMode = "Aggregate") {
      if (StrLen(key) = 1 && key~="\w") {
        Aggregator:= %Aggregator% . %key%
        ; Log("Aggregator", Aggregator)
        return ; Collect Words until interrupted
      } 
      LogAggregator()
      formattedKey := StrLen(key)>1 ? "{" key "}" : "{" vksc "}"
    }
    LogKeyboard("Send, " + formattedKey)
  }
}

LogAggregator() {
  LogKeyboard("Send, " + Aggregator)
  Aggregator := ""
}

LogKeyboard(data) {
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

LogMouseKey(key) {
  return
  ; global gui_id, LogArr, Coord
  ; k:=SubStr(key,1,1)
  ; CoordMode, Mouse, %Coord%
  ; MouseGetPos, X, Y, id
  ; if (id=gui_id)
  ;   return
  ; Logg("MouseClick, " k ", " X ", " Y ",,, D")
  ; CoordMode, Mouse, Screen
  ; MouseGetPos, X1, Y1
  ; t1:=A_TickCount
  ; Critical, Off
  ; KeyWait, %key%
  ; Critical
  ; t2:=A_TickCount
  ; if (t2-t1<=200)
  ;   X2:=X1, Y2:=Y1
  ; else
  ;   MouseGetPos, X2, Y2
  ; i:=LogArr.MaxIndex(), r:=LogArr[i]
  ; if InStr(r, ",,, D") and Abs(X2-X1)+Abs(Y2-Y1)<5
  ;   LogArr[i]:=SubStr(r,1,-5), Logg()
  ; else
  ;   Logg("MouseClick, " k ", " (X+X2-X1) ", " (Y+Y2-Y1) ",,, U")
}

LogControlKey(key) {
  key := StrReplace(key, "Control", "Ctrl")
  return
  ; global LogArr, Coord
  ; k:=InStr(key,"Win") ? key : SubStr(key,2)
  ; if (k="Ctrl")
  ; {
  ;   CoordMode, Mouse, %Coord%
  ;   MouseGetPos, X, Y
  ; }
  ; Logg("{" k " Down}",1)
  ; Critical, Off
  ; KeyWait, %key%
  ; Critical
  ; Logg("{" k " Up}",1)
  ; if (k="Ctrl")
  ; {
  ;   i:=LogArr.MaxIndex(), r:=LogArr[i]
  ;   if InStr(r,"{Blind}{Ctrl Down}{Ctrl Up}")
  ;     LogArr[i]:="MouseMove, " X ", " Y
  ; }
}

; checks if item exists in a string
hasValue(list, item, del:=","){
  if (item = "")
    return False
	haystack:=del
	if !IsObject(list)
		haystack.= list del
	else
		for k,v in list
			haystack.= v del	
	Return !!InStr(del haystack del, del item del)
}
