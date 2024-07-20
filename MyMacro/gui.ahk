#SingleInstance, force
#NoEnv

SetBatchLines, -1
Thread, NoTimers
DetectHiddenWindows, On
SetTitleMatchMode, 2
DetectHiddenText, On
SetWorkingDir %A_ScriptDir%

;----------------------------------------------------
global GuiLogFile := ".Logs\GuiLog.log"
FileDelete %GuiLogFile%
Log(name, text) {
  FileAppend, %name%:[%text%]`n, %GuiLogFile%,
}
Log("DateTime", A_Now)
;----------------------------------------------------
; Static Options
;----------------------------------------------------
global EditorPath := "C:\Program Files\VSCodium\VSCodium.exe"  
global SettingsPath := "settings"
global UpdateLatestSelectOnRecord := True
global isTipEnabled := True
;----------------------------------------------------
; Dynamic Options
;----------------------------------------------------
LoadSettings()
; If set Always Override on Startup
global WorkDir
global NewRecordName
global RecordFolderPath
global PlaySpeedRecord
global PlaySpeedMultiplier
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
global CoordinateMode

LoadSettings() {
  Loop, Read, %SettingsPath%
  {
    option := StrSplit(A_LoopReadLine, ":",,2)
    label := option[1]
    ; Log("labelInit", label)
    %label% := option[2]
  }
}
UpdateSettings() {
NewSettings = 
(
WorkDir:%WorkDir%
NewRecordName:%NewRecordName%
RecordFolderPath:%RecordFolderPath%
PlaySpeedRecord:%PlaySpeedRecord%
PlaySpeedMultiplier:%PlaySpeedMultiplier%
NewRecordPath:%NewRecordPath%
LatestSelectPath:%LatestSelectPath%
LatestSelectName:%LatestSelectName%
MainGuiHwnd:%MainGuiHwnd%
isLogKeyboard:%isLogKeyboard%
isLogMouse:%isLogMouse%
isLogSleep:%isLogSleep%
isLogWindow:%isLogWindow%
isLogColor:%isLogColor%
isAggregateMode:%isAggregateMode%
isPreciseMode:%isPreciseMode%
isAppendSaveMode:%isAppendSaveMode%
isOverrideSaveMode:%isOverrideSaveMode%
isNewSaveMode:%isNewSaveMode%
SharedPath:%SharedPath%
CoordinateMode:%CoordinateMode%
)
  FileDelete, %SettingsPath%
  FileAppend, %NewSettings%, %SettingsPath%
}
;----------------------------------------------------
; Util Options
;----------------------------------------------------
global FileSaveModes := "New,Override,Append"
global CoordinateModes := "Screen,Window"
global TimingModes = "Precise,Aggregate" 
global LogOptions := "Color,Keyboard,Mouse,Sleep,Window"
global IsRecordingPlaying := False
global RecentTip := ""
global TipBackup := ""
global TipToggle := 0
global PlayTitle
global PlayingPID
global PlayingPID
global PlayingHwnd
global guiHwnds := []
global buttonHwnds := []
global lastWMHideTime := []
global buttonToggled := []
global optionToggled := []
global buttonEnabled := []
global DestructionBlock
global SharedPath := A_ScriptDir "\Macros\.shared.ahk"
;----------------------------------------------------
global WM_ON_LOGGER := 0x0401
global WM_OFF_LOGGER := 0x0402
global WM_PAUSE_LOGGER := 0x0403
global WM_RESUME_LOGGER := 0x0404
global WM_TEST_LOGGER := 0x0405
global WM_PLAY_SPEED_M := 0x040A
global WM_PLAY_STOP := 0x040B
OnMessage(WM_PLAY_STOP, "ScriptPlayEnd")

global LoggerPath := "Logger.ahk"
WinGet, LoggerPID, PID, % LoggerPath
if (LoggerPID = "") {
  MsgBox, 4096, Error, LoggerPID is Null, Increase Sleep Timer
  Exit
}
; Log("LoggerPID", LoggerPID)
global LoggerHwnd := WinExist("ahk_pid" LoggerPID)
if (LoggerHwnd + 0 = 0) {
  MsgBox, 4096, Error, LoggerHwnd is Null, Increase Sleep Timer
  Exit
}
; Log("LoggerHwnd", LoggerHwnd)
PostLoggerMessage(WM_TEST_LOGGER)

PostLoggerMessage(ID) {
  PostMessage, ID, 0,0,, % "ahk_id" LoggerHwnd
  ; Log("PostLoggerMessage", ID " " ErrorLevel " " LoggerHwnd) 
}

;----------------------------------------------------
Gui, Main: +AlwaysOnTop +ToolWindow -Caption
Gui, Main: +HwndMain_gui_id
global MainGuiHwnd := Main_gui_id
; Log("Main", Main_gui_id + 0)
FileDelete, %SharedPath%
shared =
(
  global MainGuiHwnd := %MainGuiHwnd%
)
FileAppend, %shared%, %SharedPath%
Gui, Main: Font, s11 
Gui, Main: Margin, 0, 0

; global DynamicButtons := "Play,Edit,Exit"
; global StaticButtons := "Record"
; global SpecialButtons := "Pause" ; Work when not recording
MainButtons = 
(
[F1]Record
[F2]Pause
[F3]Play
[F4]Edit
[F5]Exit
)
For i,text in StrSplit(Mainbuttons, "`n")
{
  hotkey := SubStr(text, 2, InStr(text, "]") - 2)
  label := RegExReplace(text, ".*]")
  Hwnd:= label "_id"
  Gui, Main: Add, Button, x+0 h22 v%label% default g%label% hwnd%Hwnd%, %A_Space%%text%%A_Space%
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
global GuiX, GuiY, GuiWidth, GuiHeight
WinGetPos, GuiX, GuiY, GuiWidth, GuiHeight, Macro Recorder

DisableMainButton("Pause")
UpdateTip("Welcome!")

Return
;----------------------------------------------------

RecordHotkey:
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
    PostLoggerMessage(WM_OFF_LOGGER)
    if (buttonToggled["Pause"]) 
      ResumeButton()
    IsRecordingPlaying := False
    buttonToggled["Record"] := False
    GuiControl, Main: , Record, [F1]Record
    EnableMainButton("Play")
    EnableMainButton("Edit")
    EnableMainButton("Exit")
    DisableMainButton("Pause")
    UpdateTip("Saved " + NewRecordName)
  }
  else { ; Go to State 2
    SetNewRecordPath()
    UpdateSettings()
    PostLoggerMessage(WM_ON_LOGGER)
    IsRecordingPlaying := True
    buttonToggled["Record"] := True
    GuiControl, Main: , Record, [F1]Stop
    DisableMainButton("Play")
    DisableMainButton("Edit")
    DisableMainButton("Exit")
    EnableMainButton("Pause")
    UpdateTip("Recording to " + NewRecordName)
  }
Return

Pause:
  if (buttonToggled["Pause"]) { ; Revert to State 1
    Resume()
  } else { ; Go to State 2
    If (buttonToggled["Record"]) {
      PostLoggerMessage(WM_PAUSE_LOGGER)
    } else if (buttonToggled["Play"]) {
      Log("POST", "")
      PostPlayToggleMessage()
    }
    IsRecordingPlaying := False
    TipBackup = %RecentTip%
    UpdateTip("Paused " + RecentTip)
    buttonToggled["Pause"] := True
    GuiControl, Main: , Pause, [F2]Resume
  }
Return

Resume() {
  If (buttonToggled["Record"]) {
    UpdateSettings()
    PostLoggerMessage(WM_RESUME_LOGGER)
  } else if (buttonToggled["Play"]) {
    PostPlayToggleMessage()
    PostSpeedMultiplier()
  }
  ResumeButton()
}

ResumeButton() {
  IsRecordingPlaying := True
  UpdateTip(TipBackup)
  buttonToggled["Pause"] := False
  GuiControl, Main: , Pause, [F2]Pause
}

ScriptPlayEnd(wParam, lParam, msg, hwnd) {
  PlayEnd()
} 

PlayEnd() {
  ResumeButton()
  IsRecordingPlaying := False
  buttonToggled["Play"] := False
  GuiControl, Main: , Play, [F3]Play
  EnableMainButton("Record")
  EnableMainButton("Exit")
  DisableMainButton("Pause")
  UpdateTip("Finished: " PlayTitle)
}

Play:
  if (buttonToggled["Play"]) { ; Revert to State 1
    PlayStop()
    if (buttonToggled["Pause"]) 
      ResumeButton()
    IsRecordingPlaying := False
    buttonToggled["Play"] := False
    GuiControl, Main: , Play, [F3]Play
    EnableMainButton("Record")
    EnableMainButton("Exit")
    DisableMainButton("Pause")
    UpdateTip("Stopped: " PlayTitle)
  } 
  else { ; Go to State 2
    If (!FileExist(LatestSelectPath)) {
      UpdateTip("File " LatestSelectName " does not exist")
      Return
    }
    PlayStart()
    PostSpeedMultiplier()
    IsRecordingPlaying := True
    buttonToggled["Play"] := True
    GuiControl, Main: , Play, [F3]Stop
    DisableMainButton("Record")
    DisableMainButton("Exit")
    EnableMainButton("Pause")
    UpdateTip("Playing:" PlayTitle)
  }
Return 

PostPlayToggleMessage() {
  DetectHiddenWindows, On
  WM_COMMAND := 0x0111
  ID_FILE_PAUSE := 65403
  PostMessage, WM_COMMAND, ID_FILE_PAUSE,,, % "ahk_id" PlayingHwnd
  Log("PostPlayToggleMessage", PlayingHwnd " " ErrorLevel)
  MsgBox, PostPlayToggleMessage %ErrorLevel%
}

PostSpeedMultiplier() {
  dot := InStr(PlaySpeedMultiplier, ".")
  index := dot = 0 ? 0 : StrLen(PlaySpeedMultiplier) - dot
  PseudoInt := StrReplace(PlaySpeedMultiplier, ".")
  PostMessage, WM_PLAY_SPEED_M, Index, PseudoInt,, % "ahk_id" PlayingHwnd
  ; Log("PostSpeedMultiplier", PlayingHwnd " " ErrorLevel)
}

PlayStart() {
  DetectHiddenWindows, On
  global PlayTitle, PlayingPID, PlayingHwnd
  PlayTitle := LatestSelectName
  MsgBox, % LatestSelectPath
  Run, %LatestSelectPath%,,, OutputPID
  SetTimer, CheckPlay, 1000 ; In case of an premature end
  Sleep, 200
  WinGet, PlayingPID, PID, % LatestSelectPath
  PlayingHwnd := WinExist("ahk_pid" PlayingPID)
}

PlayStop() {
  SetTimer, CheckPlay, Off
  Process, Close, %PlayingPID%
}

CheckPlay:
global PlayingPID
  Exists := ProcessExist(PlayingPID)
  if (Exists)  {
    Return
  } else {
    PlayEnd()
  }
Return

ProcessExist(PID) {
  Process, Exist, %PID%
  return ErrorLevel
}

Edit:
global LatestSelectPath, LatestSelectName
  if (FileExist(LatestSelectPath)) {
    val := """" EditorPath """ """ LatestSelectPath """"
    Run, *RunAs %val%
      UpdateTip("Editing " LatestSelectName)
  } else {
    UpdateTip("File " LatestSelectName " does not exist")
}
Return

Exit:
  UpdateSettings()
  Gui, Tip: Destroy
  Process, Close, %loggerPID%
  ExitApp

UpdateTip(text:="") {
  global TipToggle ; Cycles trough guis to prevent flickering from Destroying
  if(text = "" || !isTipEnabled)
    return
  Gui, Tip%TipToggle%: +AlwaysOnTop +ToolWindow -Caption
  Gui, Tip%TipToggle%: +HwndTip_gui_id
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
  label := A_GuiControl
  state := buttonEnabled[label]
  If (label = "Pause") { 
    If (!IsRecordingPlaying) 
      OpenClickOptionGui(label)
  } 
  else if (state) {
    ; if (hasValue(DynamicButtons, label)) 
      OpenClickOptionGui(label)
    ; else If (hasValue(StaticButtons, label))
      ; OpenStaticOptionGui(label)
  }
Return

; OptionsX chain (Ctrl hotkey support)
; label := RegExReplace(A_ThisLabel, "OptionHotkey$")
; state := buttonEnabled[label]
; if (state) {
;   OpenStaticOptionGui(label)
; }
; Return

RecordOptionHotkey:
PlayOptionHotkey:
EditOptionHotkey:
ExitOptionHotkey:
label := RegExReplace(A_ThisLabel, "OptionHotkey$")
state := buttonEnabled[label]
if (state) {
  OpenKeyOptionGui(label)
}
Return

; Special treatment, Options function different than Button
PauseOptionHotkey:
label := RegExReplace(A_ThisLabel, "OptionHotkey$")
if (!IsRecordingPlaying) {
  OpenKeyOptionGui(label)
  ; OpenStaticOptionGui(label)
}
Return

; Do not try to understand how this works
OpenClickOptionGui(title) {
  ; Log("Clicklabel", title)
  Hwnd := guiHwnds[title]
  isHiddenbyWM := A_TickCount - lastWMHideTime[Hwnd] < 200 ; byWM (if not passed)
  if (!isHiddenbyWM || !guiHwnds[title] || !optionToggled[label]) {  ; If passed
    optionToggled[label] := True
    LoadOptionsGui(title)
    ; Log("Show", !wasHidden)
  } else {
    optionToggled[label] := False
    ; Log("DestroyedOnClick", Hwnd)
    Return
  } 
}

; This too, leave, please...
OpenKeyOptionGui(title) {
  ; Log("Keylabel", title)
  Hwnd := guiHwnds[title]
  isHiddenbyWM := A_TickCount - lastWMHideTime[Hwnd] < 100 ; byWM (if not passed)
  DetectHiddenWindows, Off
  if (!isHiddenbyWM || !guiHwnds[title] || !optionToggled[label]) {
    optionToggled[label] := True
    LoadOptionsGui(title)
    ; Log("Show", Hwnd)
    DestructionBlock := False
  } 
  else if (!DestructionBlock && !WinExist("ahk_id " Hwnd) + 0) {
    optionToggled[label] := True
    ; Log("Regenerated", Hwnd)
    LoadOptionsGui(title)
  } 
  else {
    optionToggled[label] := False
    ; Log("DestroyedOnHotkey", Hwnd)
    DestructionBlock := Hwnd
    Gui, %title%: Destroy
  }
  DetectHiddenWindows, On
}


LoadOptionsGui(title) {
  Gui, %title%: +AlwaysOnTop +ToolWindow -Caption 
  Gui, %title%: +Hwnd%title%_gui_id
  guiHwnds[title] := %title%_gui_id
  Gui, %title%: Font, s11
  Gui, %title%: Margin, 1, 1
  
  Load%title%Options()
  
  Hwnd := buttonHwnds[title]
  ControlGetPos, X, Y, w, h, , ahk_id %Hwnd%
  Y := h
  X := X + GuiX
  Gui, %title%: Show, w120 x%X% y%Y%, (title)

  OnMessage(0x0006, "WM_ACTIVATE")
}

; Event handler to close the GUI when it loses focus
WM_ACTIVATE(wParam, lParam, msg, Hwnd) {
  Hwnd:= Format("0x{:X}", Hwnd)
  if(Hwnd != MainGuiHwnd) {
    ; Log("HwndWM", Hwnd)
    if (wParam = 0) {
      If (DestructionBlock != Hwnd) {
        ; Log("Destroy", DestructionBlock)
        Gui, Destroy
        lastWMHideTime[Hwnd] := A_TickCount
      }
      DestructionBlock := False
    }
  }
}

LoadRecordOptions() {
  global RecordInputText
  Gui, Record: Add, Edit, x0 w120 h20 vRecordInputText ToolTip, %NewRecordName%
  Gui, Record: Add, Button, x1 w0 h0 Hidden gSubmitRecord Default, 
  global IsOverride, IsNew, IsAppend
  For i,mode in StrSplit(FileSaveModes, ",")
  {
    isMode:= is%mode%SaveMode ? "Checked" : ""
    Gui, Record: Add, Checkbox, %isMode% vIs%mode% g%mode%, %mode% 
  }
  global IsScreen, IsWindow
  For i,mode in StrSplit(CoordinateModes, ",")
    {
      isMode := CoordinateMode = mode ? "Checked" : ""
      Gui, Record: Add, Checkbox, %isMode% vIs%mode% g%mode%, %mode%Mode 
    }
}

Screen:
Window:
  CoordinateMode := A_ThisLabel
  GuiControl, , Is%CoordinateMode%, 1
  UpdateTip("SetCoordinateMode: " CoordinateMode)
  For i,mode in StrSplit(CoordinateModes, ",")
  {
    If (mode != CoordinateMode)  {
      GuiControl, , Is%mode%, 0
    }
  }
Return

SubmitRecord:
global NewRecordName
  GuiControlGet, inputText, , RecordInputText
  If (inputText = "")
    NewRecordName := "Record_" A_Now
  else 
    NewRecordName = %inputText%
  UpdateTip("LatestNewRecordName: " NewRecordName)
  Gui, Record: Hide
Return

Append:
New:
Override:
global FileSaveModes
  is%A_ThisLabel%SaveMode := True
  GuiControl, , Is%A_ThisLabel%, 1
  UpdateTip("SetSaveMode: " A_ThisLabel ":" is%A_ThisLabel%SaveMode)
  For i,mode in StrSplit(FileSaveModes, ",")
  {
    If (mode != A_ThisLabel)  {
      is%mode%SaveMode := False
      GuiControl, , Is%mode%, 0
    }
  }
Return

LoadPauseOptions() {
  global IsAggregate, IsPrecise
  For i,mode in StrSplit(TimingModes, ",")
  {
    isMode:= is%mode%Mode ? "Checked" : ""
    Gui, Pause: Add, Checkbox, x1 %isMode% vIs%mode% g%mode%, %mode%Mode
  }
  
  global PSRecordInputText, DecreasePSRecord, IncreasePSRecord
  Gui, Pause: Add, Text, x0 w1, SpdR:
  Gui, Pause: Add, Button, x+0 w20 h20 vDecreasePSRecord gDecreasePSRecord, -
  Gui, Pause: Add, Edit, x+0 w40 h20 vPSRecordInputText Tooltip, %PlaySpeedRecord%
  Gui, Pause: Add, Button, x+0 w20 h20 vIncreasePSRecord gIncreasePSRecord, +
  Gui, Pause: Add, Button, x+0 w0 h0 Hidden gSubmitPS Default, 

  global PSMultiplierInputText, DecreasePSMultiplier, IncreasePSMultiplier
  Gui, Pause: Add, Text, x0 w1, SpdM:
  Gui, Pause: Add, Button, x+0 w20 h20 vDecreasePSMultiplier gDecreasePSMultiplier, -
  Gui, Pause: Add, Edit, x+0 w40 h20 vPSMultiplierInputText Tooltip, %PlaySpeedMultiplier%
  Gui, Pause: Add, Button, x+0 w20 h20 vIncreasePSMultiplier gIncreasePSMultiplier, +
  Gui, Pause: Add, Button, x+0 w0 h0 Hidden gSubmitPS Default, 

  global isKeyboard, isMouse, isColor, isWindow, isSleep
  For i, name in StrSplit(LogOptions, ",") {
    isTrue:= isLog%name% ? "Checked" : ""
    Gui, Pause: Add, Checkbox, x1  %isTrue% vIs%name% gLog%name%, Log%name%
  }
}

Precise:
Aggregate:
global TimingModes

  is%A_ThisLabel%Mode := True
  GuiControl, , Is%A_ThisLabel%, 1
  UpdateTip("SetTimingMode: " A_ThisLabel ":" is%A_ThisLabel%Mode)
  For i,mode in StrSplit(TimingModes, ",")
  {
    If (mode != A_ThisLabel)  {
      is%mode%Mode := False
      GuiControl, , Is%mode%, 0
    }
  }
Return

DecreasePSRecord:
DecreasePSMultiplier:
global PlaySpeedRecord, PlaySpeedMultiplier
  mode := StrReplace(A_ThisLabel, "DecreasePS")
  label := "PlaySpeed" mode
  value := %label%
  if (value > 1) 
    value--
  else if (value > 0.2)
    value := value - 0.1
  value := RTrim(RTrim(inputText, "0"), ".")
  %label% := value
  GuiControl,, PS%mode%InputText, %value%
Return

IncreasePSRecord:
IncreasePSMultiplier:
global PlaySpeedRecord, PlaySpeedMultiplier
  mode := StrReplace(A_ThisLabel, "IncreasePS")
  label := "PlaySpeed" mode
  value := %label%
  If (value < 1) 
    value := value + 0.1
  else 
    value++
  value := RTrim(RTrim(inputText, "0"), ".")
  %label% := value
  GuiControl,, PS%mode%InputText, %value%
Return

SubmitPS:
global PlaySpeedRecord, PlaySpeedMultiplier
  GuiControlGet, inputText, , PSRecordInputText
  if (RegExMatch(inputText, "^\d+(\.\d+)?$") && inputText > 0) {
    inputText := inputText + 0.0
    PlaySpeedRecord := RTrim(RTrim(inputText, "0"), ".")
  }
  GuiControlGet, inputText, , PSMultiplierInputText
  if (RegExMatch(inputText, "^\d+(\.\d+)?$") && inputText > 0) {
    inputText := inputText + 0.0
    PlaySpeedMultiplier := RTrim(RTrim(inputText, "0"), ".")
  }
  UpdateTip("SetPlaySpeed: Record:" PlaySpeedRecord " Multiplier:" PlaySpeedMultiplier)
Return

LogKeyboard:
LogMouse:
LogColor:
LogWindow:
LogSleep:
global IsRecordingPlaying, LogOptions
  is%A_ThisLabel% := !is%A_ThisLabel%
  UpdateTip("Set" + A_ThisLabel ": " + is%A_ThisLabel%)
Return

LoadPlayOptions() {
  Loop, %RecordFolderPath%\*.ahk
  {
    SplitPath, A_LoopFilePath, fileName
    fileName := StrReplace(fileName, ".ahk", "")
    If (SubStr(fileName, 1, 1) != ".")
      Gui, Play: Add, Button, h20 gPlayFile, %fileName%
  }
}

PlayFile:
global LatestSelectPath, LatestSelectName
  GuiControlGet, ButtonText, FocusV  ; Get the text of the clicked button
  LatestSelectPath := RecordFolderPath ButtonText ".ahk"
  LatestSelectName := ButtonText
  Gosub, Play
Return

LoadEditOptions() {
  Loop, %RecordFolderPath%\*.ahk
  {
    SplitPath, A_LoopFilePath, fileName
    fileName := StrReplace(fileName, ".ahk", "")
    If (SubStr(fileName, 1, 1) != ".")
      Gui, Edit: Add, Button, h20 gEditFile, %fileName%
  }
}

; C:\Users\Name\..My\VSCode\AutoHotKey\MyMacro\Macros\Record_20240717225252.ahk
EditFile:
global RecordFolderPath, LatestEditPath
  GuiControlGet, ButtonText, FocusV  ; Get the text of the clicked button
  LatestSelectPath := RecordFolderPath ButtonText ".ahk"
  LatestSelectName := ButtonText
  Gosub, Edit
Return

LoadExitOptions() {
  global WorkDirInputText
  ; Gui, Exit: Add, Text, x0, %A_Space%WorkDir:%A_Space%
  ; Gui, Exit: Add, Text, x+0 w50 vWorkDir, %WorkDir%%A_Space%
  
  Gui, Exit: Add, Edit, x0 w120 h20 vWorkDirInputText Tooltip, %WorkDir%
  Gui, Exit: Add, Button, x+0 w0 h0 Hidden gSetWorkDir Default, 
  Loop, Files, Macros\*.*, D
  {
    dirName := A_LoopFileName
    If (SubStr(dirName, 1, 1) != ".")
      Gui, Exit: Add, Button, x0 h20 gChangeWorkDir, %dirName%
  }
}

SetWorkDir:
global WorkDir
  GuiControlGet, inputText, , WorkDirInputText
  WorkDir := inputText
  RecordFolderPath := A_ScriptDir "\Macros\" WorkDir "\"
  IfNotExist, %RecordFolderPath%
      FileCreateDir, %RecordFolderPath%
  UpdateTip("SetRecordFolder: " WorkDir)
Return

ChangeWorkDir:
global WorkDir	
  GuiControlGet, ButtonText, FocusV 
  WorkDir := ButtonText
  RecordFolderPath := A_ScriptDir "\Macros\" WorkDir "\"
  GuiControl,, WorkDirInputText, %WorkDir%
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

SetNewRecordPath() {
  global NewRecordName, RecordFolderPath, NewRecordPath
  if (NewRecordName = "Null" || NewRecordName = "") {
    NewRecordName := "Record_" A_Now
  }
  else if (!isOverrideSaveMode && RegExMatch(NewRecordName, "Record_\d{12}")) {
    NewRecordName := "Record_" A_Now
  }
  else if (isNewSaveMode && !RegExMatch(NewRecordName, "Record_\d{12}")) {
    highest := 0
    Loop, %RecordFolderPath%\*.ahk
    {
      SplitPath, A_LoopFilePath, FileName
      if (InStr(FileName, NewRecordName "_")) {
        number := StrSplit(FileName, NewRecordName "_")[2]
        number := StrReplace(number, ".ahk", "")
        if (number > highest) 
          highest := number
      }
    }
    highest++
    NewRecordName := NewRecordName "_" highest
  }
  
  if (isOverrideSaveMode && FileExist(NewRecordPath)) {
    overrideBackupPath := "Macros\override_backup"
    FileDelete %overrideBackupPath% 
    FileMove, %NewRecordPath%, %overrideBackupPath%
  }

  NewRecordPath := A_ScriptDir "\Macros\" WorkDir "\" NewRecordName ".ahk"

  if (UpdateLatestSelectOnRecord) {
    LatestSelectPath := NewRecordPath
    LatestSelectName := NewRecordName
  }
}


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

ExitHandler: 
  if (buttonToggled["Record"]) ; Revert to State 1
    PostLoggerMessage(WM_OFF_LOGGER)
  UpdateSettings()  
  PID := DllCall("GetCurrentProcessId")
  RunWait, taskkill \pid %PID%,, hide