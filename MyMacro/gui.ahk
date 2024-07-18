; If not A_IsAdmin ; Needed to Edit Files
  ; Run *RunAs "%A_ScriptFullPath%"
#SingleInstance, force
#Include %A_ScriptDir%\logger.ahk
#NoEnv

SetBatchLines, -1
; Thread, NoTimers
; CoordMode, ToolTip
SetTitleMatchMode, 2
DetectHiddenWindows, On
DetectHiddenText, On
SetWorkingDir %A_ScriptDir%

;----------------------------------------------------
global MyLogFile:= A_ScriptDir . "/log.log"
global EditorPath:="C:\Program Files\VSCodium\VSCodium.exe"  
global TimingMode = "Precise" 
global FileSaveMode := "Append"
global RecordFolderName := "Macros"
global RecordFolderPath := A_ScriptDir . "\" . RecordFolderName "\"
global PlaySpeed := 1.0
global UpdateLatestSelectOnRecord := True
global LogOptions := ({
  (Join  
  "LogKeyboard": False,
  "LogControl": False,
  "LogSpecial": False,
  "LogMouse": False,
  "LogColor": False,
  "LogWindow": False,
  "LogDelay": False
)})
;----------------------------------------------------
global GuiX, GuiY, GuiWidth, GuiHeight
global SaveModes := "New,Override,Append"
global TimingModes = "Precise,Aggregate" 
global guiHwnds := []
global buttonHwnds := []
global lastWMHideTime := []
global buttonToggled := []
global buttonEnabled := []
global RecentTip := ""
global TipBackup := ""
global TipToggle := 0
global LatestRecordName := "Null"
global LatestRecordPath := "Null"
global LatestSelectPath := "Null"
global LatestSelectName := "Null"
global PlayTitle
global PlayingPID
global AHK := A_IsCompiled ? A_ScriptDir "\AutoHotkey.exe" : A_AhkPath
IfNotExist, %AHK%
{
  MsgBox, 4096, Error, Can't Find %AHK% !
  Exit
}
;----------------------------------------------------

FileDelete %MyLogFile%
Log(name, text) {
  FileAppend, %name%:[%text%]`n, %MyLogFile%,
}
Log("DateTime", A_Now)

IfNotExist %ScriptsDir%
  FileCreateDir, %ScriptsDir%

;----------------------------------------------------
Gui, Main: +AlwaysOnTop +ToolWindow -Caption
Gui, Main: +E0x08000000 +HwndMain_gui_id
guiHwnds["Main"] := Main_gui_id
Gui, Main: Font, s11 
Gui, Main: Margin, 0, 0

s = 
(
[F1]Record
[F2]Pause
[F3]Play
[F4]Edit
[F5]Exit
)
For i,text in StrSplit(s, "`n")
{
  hotkey := SubStr(text, 2, InStr(text, "]") - 2)
  label := RegExReplace(text, ".*]")
  Hwnd:= label . "_id"
  Gui, Main: Add, Button, x+0 h22 v%label% default g%label% hwnd%Hwnd%, %text%
  buttonHwnds[label] := %Hwnd%
  buttonToggled[label] := False
  buttonEnabled[label] := True
  Hotkey, %hotkey%, %label%Hotkey
  Hotkey, ^%hotkey%, %label%OptionHotkey
}
Gui, Main: Show, NA y0, Macro Recorder
Gui, Main: Submit, NoHide

; Get the position of the main GUI window
; x left edge align ; y top align ; w width ; h height
WinGetPos, GuiX, GuiY, GuiWidth, GuiHeight, Macro Recorder

DisableMainButton("Pause")
UpdateTip("Welcome!")

Return
;----------------------------------------------------

RecordHotkey:
StopHotkey:
PlayHotkey:
EditHotkey:
ExitHotkey:
PauseHotkey:
label := RegExReplace(A_ThisLabel, "Hotkey$")
state := buttonEnabled[label]
if (state) {
  Goto, %label%
}
Return

EnableMainButton(label) {
  GuiControl, Main: Enable , %label%
  buttonEnabled[label] := True
}

DisableMainButton(label) {
  GuiControl, Main: Disable, %label%
  buttonEnabled[label] := False
}

Record:
  if (buttonToggled["Record"]) { ; Revert to State 1
    if (buttonToggled["Pause"]) 
      Resume()
    StopLog()
    buttonToggled["Record"] := False
    GuiControl, Main: , Record, [F1]Record
    EnableMainButton("Play")
    EnableMainButton("Exit")
    DisableMainButton("Pause")
    UpdateTip("Saved " + LatestRecordName)
  }
  else { ; Go to State 2
    SetLatestRecordPath()
    RecordLog()
    buttonToggled["Record"] := True
    GuiControl, Main: , Record, [F1]Stop
    DisableMainButton("Play")
    DisableMainButton("Exit")
    EnableMainButton("Pause")
    UpdateTip("Recording to " + LatestRecordName)
  }
Return

Pause:
  if (buttonToggled["Pause"]) { ; Revert to State 1
    Resume()
  } else { ; Go to State 2
    PauseLog()
    TipBackup = %RecentTip%
    UpdateTip("Paused " + RecentTip)
    buttonToggled["Pause"] := True
    GuiControl, Main: , Pause, [F2]Resume
  }
Return

Resume() {
  ResumeLog()
  UpdateTip(TipBackup)
  buttonToggled["Pause"] := False
  GuiControl, Main: , Pause, [F2]Pause
}

Play:
  if (buttonToggled["Play"]) { ; Revert to State 1
    if (buttonToggled["Pause"]) 
      Resume()
    StopPlay()
    buttonToggled["Play"] := False
    GuiControl, Main: , Play, [F3]Play
    EnableMainButton("Record")
    EnableMainButton("Exit")
    DisableMainButton("Pause")
    UpdateTip("Stopped: " . PlayTitle)
  } 
  else { ; Go to State 2
    If (!FileExist(LatestSelectPath)) {
      UpdateTip("File " LatestSelectName " does not exist")
      Return
    }
    Play()
    buttonToggled["Play"] := True
    GuiControl, Main: , Play, [F3]Stop
    DisableMainButton("Record")
    DisableMainButton("Exit")
    EnableMainButton("Pause")
    UpdateTip("Playing:" . PlayTitle)
  }
Return

Play() {
global PlayTitle, PlayingPID
  PlayTitle := LatestSelectName
  Run, %AHK% /r %LatestRecordPath%,,, OutputPID
  PlayingPID := OutputPID
  SetTimer, CheckPlay, 1000
}

StopPlay() {
  SetTimer, CheckPlay, Off
  Process, Close, %PlayingPID%
}

CheckPlay:
global PlayingPID
  Exists := ProcessExist(PlayingPID)
  if (Exists)  {
    Return
  } else {
    Gosub, Play ; Toggle Stop
    UpdateTip("Finished: " . PlayTitle)
  }
Return

ProcessExist(PID) {
  Process, Exist, %PID%
  return ErrorLevel
}

Edit:
global LatestSelectPath, LatestSelectName
  if (FileExist(LatestSelectPath)) {
    Run, % """" EditorPath """ """ LatestSelectPath """"
      UpdateTip("Editing " LatestSelectName)
  } else {
    UpdateTip("File " LatestSelectName " does not exist")
}
Return

Exit:
Gui, Tip: Destroy
ExitApp

UpdateTip(text:="") {
  global TipToggle ; Cycles trough guis to prevent flickering from Destroying
  if(text = "")
    return
  Gui, Tip%TipToggle%: +AlwaysOnTop +ToolWindow -Caption
  Gui, Tip%TipToggle%: +E0x08000000 +HwndTip_gui_id
  guiHwnds["Tip" + TipToggle] := Tip_gui_id
  Gui, Tip%TipToggle%: Font, bold s11
  Gui, Tip%TipToggle%: Margin, 0, 0
  
  w := GuiX + GuiWidth + 100
  Gui, Tip%TipToggle%: Add, Button, h22 Disabled, %text%
  
  Gui, Tip%TipToggle%: Show, NA y0 X%w%, TipConsole
  Gui, Tip%TipToggle%: Submit, NoHide
  Sleep, 25 ; Delay To Render
  TipToggle:= !TipToggle
  Gui, Tip%TipToggle%: Destroy
  Return
}

;----------------------------------------------------
; Open OptionsX Gui via vlabel (right click support)
MainGuiContextMenu:
state := buttonToggled[A_GuiControl]
if (!state) {
  OpenOptionGui(A_GuiControl)
}
Return

; OptionsX chain (Ctrl hotkey support)
RecordOptionHotkey:
StopOptionHotkey:
PlayOptionHotkey:
EditOptionHotkey:
ExitOptionHotkey:
label := RegExReplace(A_ThisLabel, "OptionHotkey$")
state := buttonToggled[label]
if (!state) {
  OpenOptionGui(label)
}
Return

; Special treatment, options can be accessed even if disabled
PauseOptionHotkey:
  OpenOptionGui(RegExReplace(A_ThisLabel, "OptionHotkey$"))
Return

OpenOptionGui(title) {
  DetectHiddenWindows, On
  ; Check if Gui already created
  Hwnd := guiHwnds[title]
  if (WinExist("ahk_id " . Hwnd) + 0) {
    DetectHiddenWindows, Off
    ; Show/Hide Toggle
    window:= title . "Options"
      if (!WinExist(window) && A_TickCount - lastWMHideTime[Hwnd] > 200) {
        gui, %title%: show,, %window%
      } else {
        gui, %title%: hide
      }
    DetectHiddenWindows, On
    Return
  }
  Gui, %title%: +AlwaysOnTop +ToolWindow -Caption 
  Gui, %title%: +LastFound
  Gui, %title%: +E0x08000000 +Hwnd%title%_gui_id
  guiHwnds[title] := %title%_gui_id
  Gui, %title%: Font, s11
  Gui, %title%: Margin, 1, 1
  
  Load%title%Options()

  OnMessage(0x0006, "WM_ACTIVATE")
}

; Event handler to close the GUI when it loses focus
WM_ACTIVATE(wParam, lParam, msg, Hwnd) {
  Hwnd:= Format("0x{:X}", Hwnd)
  if(Hwnd != guiHwnds["Main"]) {
    if (wParam = 0) {
      ; Timer For eliminating Show after Hide
      lastWMHideTime[Hwnd] := A_TickCount
      Gui, Hide
      Log("gMV", "False")
    }
  }
}

LoadRecordOptions() {
  global RecordInputText
  Gui, Record: Add, Edit, x0 w120 h20 vRecordInputText ToolTip, RecordName
  Gui, Record: Add, Button, x1 w0 h0 Hidden gSubmitRecord Default, 
  global IsOverride, IsNew, IsAppend
  For i,mode in StrSplit(SaveModes, ",")
  {
    isMode:= FileSaveMode = mode ? "Checked" : ""
    Gui, Record: Add, Checkbox, %isMode% vIs%mode% g%mode%, %mode% 
  }

  Hwnd := buttonHwnds["Record"]
  ControlGetPos, X, Y, w, h, , ahk_id %Hwnd%
  Y := h
  X := X + GuiX
  Gui, Record: Show, x%X% y%Y%, ("Record")
}

SubmitRecord:
global LatestRecordName
  GuiControlGet, inputText, , RecordInputText
  LatestRecordName = %inputText%
  UpdateTip("LatestNewRecordName: " . LatestRecordName)
  Gui, Record: Hide
Return

Append:
New:
Override:
global FileSaveMode
  For i,mode in StrSplit(SaveModes, ",")
  {
    checkbox := Is . mode
    if (mode = A_ThisLabel) {
      FileSaveMode := A_ThisLabel
      UpdateTip("SetSaveMode: " . FileSaveMode)
    } else {
      GuiControl, , %checkbox%, 0
    }
  }
Return

LoadPauseOptions() {
  global IsAggregate, IsPrecise, DecreaseSpeed, IncreaseSpeed
  For i,mode in StrSplit(TimingModes, ",")
  {
    isMode:= TimingMode = mode ? "Checked" : ""
    Gui, Pause: Add, Checkbox, x1 %isMode% vIs%mode% g%mode%, %mode%Mode
  }
  
  global PauseInputText
  Gui, Pause: Add, Button, x0 w20 h20 vDecreaseSpeed gDecreaseSpeed, -
  Gui, Pause: Add, Button, x+0 w20 h20 vIncreaseSpeed gIncreaseSpeed, +
  Gui, Pause: Add, Edit, x+0 w30 h20 vPauseInputText
  Gui, Pause: Add, Button, x+0 w0 h0 Hidden gSubmitPause Default, 
  Gui, Pause: Add, Text, x0, %A_Space%PlaySpeed:%A_Space%
  Gui, Pause: Add, Text, x+0 w50 vPlaySpeed, %A_Space%%PlaySpeed%%A_Space%

  Hwnd := buttonHwnds["Pause"]
  ControlGetPos, X, Y, w, h, , ahk_id %Hwnd%
  Y := h
  X := X + GuiX
  Gui, Pause: Show, x%X% y%Y%, ("Pause")
}

SubmitPause:
global PlaySpeed
  GuiControlGet, inputText, , PauseInputText
  if RegExMatch(inputText, "^\d+(\.\d+)?$")
  {
    PlaySpeed = %inputText%
    trimmed := RTrim(PlaySpeed, 0)
    GuiControl,, PlaySpeed, %A_Space%%trimmed%
    UpdateTip("SetPlaySpeed: " . PlaySpeed)
  } else {
    UpdateTip("InvalidPlaySpeed: " . inputText)
  }
Return

DecreaseSpeed:
global PlaySpeed
  if (PlaySpeed > 1) 
    PlaySpeed--
  else if (PlaySpeed > 0.1)
    PlaySpeed:= PlaySpeed - 0.1
  trimmed := RTrim(PlaySpeed, 0)
  GuiControl,, PlaySpeed, %A_Space%%trimmed%
Return

IncreaseSpeed:
global PlaySpeed
  If (PlaySpeed < 1) 
    PlaySpeed:= PlaySpeed + 0.1
  else 
    PlaySpeed++
  trimmed := RTrim(PlaySpeed, 0)
  GuiControl,, PlaySpeed, %A_Space%%trimmed%
Return

Precise:
Aggregate:
global TimingMode
  For i,mode in StrSplit(TimingModes, ",")
  {
    checkbox := Is . mode
    if (mode = A_ThisLabel) {
      TimingMode := A_ThisLabel
      UpdateTip("SetTimingMode: " . TimingMode)
    } else {
      GuiControl, , %checkbox%, 0
    }
  }
Return

LoadPlayOptions() {
  Loop, %RecordFolderPath%\*.ahk
  {
    SplitPath, A_LoopFilePath, FileName
    FileName := StrReplace(FileName, ".ahk", "")
    Gui, Play: Add, Button, h20 gPlayFile, %FileName%
  }
  Hwnd := buttonHwnds["Play"]
  ControlGetPos, X, Y, w, h, , ahk_id %Hwnd%
  Y := h
  X := X + GuiX
  Gui, Play: Show, x%X% y%Y%, ("Play")
}

PlayFile:
global LatestSelectPath, LatestSelectName
  GuiControlGet, ButtonText, FocusV  ; Get the text of the clicked button
  LatestSelectPath := RecordFolderPath . ButtonText . ".ahk"
  LatestSelectName := ButtonText
  Gosub, Play
Return

LoadEditOptions() {
  Loop, %RecordFolderPath%\*.ahk
  {
    SplitPath, A_LoopFilePath, FileName
    FileName := StrReplace(FileName, ".ahk", "")
    Gui, Edit: Add, Button, h20 gEditFile, %FileName%
  }
  Hwnd := buttonHwnds["Edit"]
  ControlGetPos, X, Y, w, h, , ahk_id %Hwnd%
  Y := h
  X := X + GuiX
  Gui, Edit: Show, x%X% y%Y%, ("Edit")
}

; C:\Users\Name\..My\VSCode\AutoHotKey\MyMacro\Macros\Record_20240717225252.ahk
EditFile:
global RecordFolderPath, LatestEditPath
  GuiControlGet, ButtonText, FocusV  ; Get the text of the clicked button
  LatestSelectPath := RecordFolderPath . ButtonText . ".ahk"
  LatestSelectName := ButtonText
  Gosub, Edit
Return

LoadExitOptions() {
  global ExitInputText
  Gui, Exit: Add, Edit, x0 w120 h20 vExitInputText Tooltip, %RecordFolderName%
  Gui, Exit: Add, Button, x+0 w0 h0 Hidden gSubmitExit Default, 

  global isLogKeyboard, isLogControl, isLogSpecial, isLogMouse, isLogColor, isLogWindow, isLogDelay
  For name, value in LogOptions {
    isTrue:= value ? "Checked" : ""
    Gui, Exit: Add, Checkbox, x1 %isTrue% vIs%name% g%name%, %name%
  }

  Hwnd := buttonHwnds["Exit"]
  ControlGetPos, X, Y, w, h, , ahk_id %Hwnd%
  Y := h
  X := X + GuiX
  Gui, Exit: Show, x%X% y%Y%, ("Exit")
}

SubmitExit:
global RecordFolderName
  GuiControlGet, inputText, , ExitInputText
  RecordFolderName := inputText
  RecordFolderPath := A_ScriptDir . "\" . RecordFolderName "\"
  Gui, Play: Destroy
  Gui, Edit: Destroy
  UpdateTip("SetRecordFolder: " . RecordFolderName)
Return

LogKeyboard:
LogControl:
LogSpecial:
LogMouse:
LogColor:
LogWindow:
LogDelay:
  LogOptions[A_ThisLabel] := !LogOptions[A_ThisLabel]
  UpdateTip("Set" + A_ThisLabel ": " + LogOptions[A_ThisLabel])
Return

F10::
Hide:
hidebuttons:=!hidebuttons
if hidebuttons {
  Gui Main:Hide
	Gui Tip:Hide
} else {
  Gui Main:Show
	Gui Tip:Show
}
Return

SetLatestRecordPath() {
  global LatestRecordName, RecordFolderPath, LatestRecordPath
  if (RegExMatch(LatestRecordName, "Record_\d{12}") && FileSaveMode != "Override") 
    LatestRecordName := "Record_" . A_Now
  else if (LatestRecordName = "Null" || LatestRecordName = "") 
    LatestRecordName := "Record_" . A_Now
  LatestRecordPath := A_ScriptDir . "\" . RecordFolderName "\" . LatestRecordName . ".ahk"
  if (FileSaveMode = "Override" && FileExist(LatestRecordPath)) {
    FileDelete %LatestRecordPath% 
  }
  else if(FileSaveMode = "New" && !RegExMatch(LatestRecordName, "Record_\d{12}")) {
    highest:= 0
    Loop, %RecordFolderPath%\*.ahk
    {
      SplitPath, A_LoopFilePath, FileName
      if (InStr(FileName, LatestRecordName "_")) {
        number := StrSplit(FileName, LatestRecordName "_")[2]
        number := StrReplace(number, ".ahk", "")
        if (number > highest) 
          highest := number
      }
    }
    highest++
    LatestRecordName := LatestRecordName "_" highest
    LatestRecordPath := A_ScriptDir "\" RecordFolderName "\" LatestRecordName ".ahk"
  }
  if (UpdateLatestSelectOnRecord) {
    LatestSelectPath := LatestRecordPath
    LatestSelectName := LatestRecordName
  }
}
