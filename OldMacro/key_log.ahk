
CustomLogKey:
  CustomLogKey()
  return

; LogKey:
; LogKey()
; return


; LogWindow:
; (tLogWindow)&&LogWindow()
; return

CustomLogKey() {
  Critical
  keyState := SubStr(A_ThisHotkey, -2)
  if (keyState == " Up") 
    k:=GetKeyName(vksc:=SubStr(A_ThisHotkey, 3, -3))
  else 
    k:=GetKeyName(vksc:=SubStr(A_ThisHotkey,3))
  k:=StrReplace(k,"Control","Ctrl"), r:=SubStr(k,2)
  ; FileAppend, "CustomLogKey() ["%A_ThisHotkey%"] k["%k%"] r["%r%"] vksc["%vksc%"]`n", %MyLogFile%
  if r in Alt,Ctrl,Shift,Win
    (tlogkey)&&LogKey_Control(k)
  else if k in LButton,RButton,MButton
    (TlogMouse)&&LogKey_Mouse(k)
  else
    {
    if (!tlogkey)
      return
    if (k="NumpadLeft" or k="NumpadRight") and !GetKeyState(k,"P")
      return
    FileAppend, "ks:["%keyState%"]", %MyLogFile%,
    if (keyState == " Up") 
      k:= k . " Up"
    Else
      k:= k . " Down"
    k:=k~="\w" ? "{" k "}" : "{" vksc "}"
    FileAppend, "kf:["%k%"]`n", %MyLogFile%,
    CustomLog(k,1)
  }
}

; LogKey() {
;   Critical
;   k:=GetKeyName(vksc:=SubStr(A_ThisHotkey,3))
;   k:=StrReplace(k,"Control","Ctrl"), r:=SubStr(k,2)
;   FileAppend, "LogKey() k["%k%"] r["%r%"]`n", %MyLogFile%
;   if r in Alt,Ctrl,Shift,Win
;     (tlogkey)&&LogKey_Control(k)
;   else if k in LButton,RButton,MButton
;     (TlogMouse)&&LogKey_Mouse(k)
;   else
;   {
;     if (!tlogkey)
;       return
;     if (k="NumpadLeft" or k="NumpadRight") and !GetKeyState(k,"P")
;       return
;     k:=StrLen(k)>1 ? "{" k "}" : k~="\w" ? k : "{" vksc "}"
;     Log(k,1)
;   }
; }

LogKey_Control(key) {
  global LogArr, Coord
  k:=InStr(key,"Win") ? key : SubStr(key,2)
  if (k="Ctrl")
  {
    CoordMode, Mouse, %Coord%
    MouseGetPos, X, Y
  }
  Log("{" k " Down}",1)
  Critical, Off
  KeyWait, %key%
  Critical
  Log("{" k " Up}",1)
  if (k="Ctrl")
  {
    i:=LogArr.MaxIndex(), r:=LogArr[i]
    if InStr(r,"{Blind}{Ctrl Down}{Ctrl Up}")
      LogArr[i]:="MouseMove, " X ", " Y
  }
}

LogKey_Mouse(key) {
  global gui_id, LogArr, Coord
  k:=SubStr(key,1,1)
  CoordMode, Mouse, %Coord%
  MouseGetPos, X, Y, id
  if (id=gui_id)
    return
  Log("MouseClick, " k ", " X ", " Y ",,, D")
  CoordMode, Mouse, Screen
  MouseGetPos, X1, Y1
  t1:=A_TickCount
  Critical, Off
  KeyWait, %key%
  Critical
  t2:=A_TickCount
  if (t2-t1<=200)
    X2:=X1, Y2:=Y1
  else
    MouseGetPos, X2, Y2
  i:=LogArr.MaxIndex(), r:=LogArr[i]
  if InStr(r, ",,, D") and Abs(X2-X1)+Abs(Y2-Y1)<5
    LogArr[i]:=SubStr(r,1,-5), Log()
  else
    Log("MouseClick, " k ", " (X+X2-X1) ", " (Y+Y2-Y1) ",,, U")
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
;     LogArr[i]:=s, Log()
;   else
;     Log(s)
; }

CustomLog(str:="", Keyboard:=0) {
  ; FileAppend, "CustomLog: str["%str%"] keyboard["%Keyboard%"]`n", %MyLogFile%
  global LogArr
  static LastTime
  t:=A_TickCount, Delay:=(LastTime ? t-LastTime : 0), LastTime:=t
  IfEqual, str,, return
  i:=LogArr.MaxIndex(), r:=LogArr[i]
  ; if (Keyboard and InStr(r,"Send,") and Delay<1000)
  ; {
  ;   LogArr[i]:=r . str
  ;   return
  ; }
  ; if (Delay>200)
    ;~ LogArr.Push("Sleep, " (Delay//2))
  LogArr.Push("  Sleep, `% " (Delay) " //playspeed")
  LogArr.Push(Keyboard ? "Send, {Blind}" str : str)
}

Log(str:="", Keyboard:=0) {
  ; FileAppend, "Log: str["%str%"] keyboard["%Keyboard%"]`n", %MyLogFile%
  global LogArr
  static LastTime
  t:=A_TickCount, Delay:=(LastTime ? t-LastTime : 0), LastTime:=t
  IfEqual, str, , return
  i:=LogArr.MaxIndex(), r:=LogArr[i]
  ; if (Keyboard and InStr(r,"Send,") and Delay<1000)
  ; {
  ;   LogArr[i]:=r . str
  ;   return
  ; }
  ; if (Delay>200)
    ;~ LogArr.Push("Sleep, " (Delay//2))
  LogArr.Push("  Sleep, `% " (Delay) " //playspeed")
  LogArr.Push(Keyboard ? "Send, " str : str)
}