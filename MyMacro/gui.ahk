; If not A_IsAdmin ; Needed to Edit Files
;   Run *RunAs "%A_ScriptFullPath%"
#SingleInstance, force
; #Include %A_ScriptDir%\logger.ahk
#NoEnv

SetBatchLines, -1
Thread, NoTimers
DetectHiddenWindows, On
SetTitleMatchMode, 2
DetectHiddenText, On
SetWorkingDir %A_ScriptDir%
;----------------------------------------------------
global GuiLogFile := A_ScriptDir . "/guiLog.log"
global EditorPath :="C:\Program Files\VSCodium\VSCodium.exe"  
global WorkDir := "Macros"
global NewRecordName := "TestRecord"
global RecordFolderPath := A_ScriptDir . "\" . WorkDir "\"
global PlaySpeed := 1.0
global UpdateLatestSelectOnRecord := True
global LogOptions := ({
  (Join  
  "LogColor": False,
  "LogSleep": True,
  "LogKeyboard": True,
  "LogMouse": True,
  "LogWindow": False
)})
global TimingMode := "Precise" 
global FileSaveMode := "Override"
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
global NewRecordPath := "Null"
global LatestSelectPath := "Null"
global LatestSelectName := "Null"
global IsRecordingPlaying := False
global PlayTitle
global PlayingPID
global AHK := A_IsCompiled ? A_ScriptDir "\AutoHotkey.exe" : A_AhkPath
IfNotExist, %AHK%
{
  MsgBox, 4096, Error, Can't Find %AHK% !
  Exit
}
;----------------------------------------------------

global WM_ON_LOGGER := 0x0401
global WM_OFF_LOGGER := 0x0402
global WM_PAUSE_LOGGER := 0x0403
global WM_RESUME_LOGGER := 0x0404
global WM_UPDATE_LOG_OPTIONS := 0x0405

Run, %A_ScriptDir%/Logger.ahk,,, loggerPID
Sleep, 200

LoggerPath := A_ScriptDir . "\Logger.ahk"
If (FileExist(LoggerPath)) {
  WinGet, scriptPID, PID, % LoggerPath
  global LoggerHwnd := WinExist("ahk_pid" . scriptPID)
} else {
  MsgBox, 4096, Error, Can't Find %LoggerPath% !
  Exit
}
;----------------------------------------------------

; Send custom messages to control logger script
PostLoggerMessage(ID) {
  MsgBox, % ID
  PostMessage, ID, 0,0,, % "ahk_id" . LoggerHwnd
  MsgBox, % ErrorLevel
}

PostUpdateLogger() {
  payload := ""
  For, i,v in LogOptions
  {
    payload .= i ":" v "`n"
  }
  payload .= "FileSaveMode:" FileSaveMode "`n"
  payload .= "NewRecordPath:" NewRecordPath "`n"
  payload .= "TimingMode:" TimingMode "`n"

  PostMessage, 0x0405, payload,,, % "ahk_id" . LoggerHwnd
}
;----------------------------------------------------

FileDelete %GuiLogFile%
Log(name, text) {
  FileAppend, %name%:[%text%]`n, %GuiLogFile%,
}
Log("DateTime", A_Now)

IfNotExist %ScriptsDir%
  FileCreateDir, %ScriptsDir%

;----------------------------------------------------
Gui, Main: +AlwaysOnTop +ToolWindow -Caption
Gui, Main: +HwndMain_gui_id
guiHwnds["Main"] := Main_gui_id
Gui, Main: Font, s11 
Gui, Main: Margin, 0, 0

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
  Hwnd:= label . "_id"
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
WinGetPos, GuiX, GuiY, GuiWidth, GuiHeight, Macro Recorder

DisableMainButton("Pause")
UpdateTip("Welcome!")

Return
;----------------------------------------------------

F12::
  PostUpdateLogger()
Return

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
    PostLoggerMessage(WM_ON_LOGGER)
    IsRecordingPlaying := False
    buttonToggled["Record"] := False
    GuiControl, Main: , Record, [F1]Record
    EnableMainButton("Play")
    EnableMainButton("Exit")
    DisableMainButton("Pause")
    UpdateTip("Saved " + NewRecordName)
  }
  else { ; Go to State 2
    SetNewRecordPath()
    PostUpdateLogger()
    PostLoggerMessage(WM_OFF_LOGGER)
    IsRecordingPlaying := True
    buttonToggled["Record"] := True
    GuiControl, Main: , Record, [F1]Stop
    DisableMainButton("Play")
    DisableMainButton("Exit")
    EnableMainButton("Pause")
    UpdateTip("Recording to " + NewRecordName)
  }
Return

Pause:
  if (buttonToggled["Pause"]) { ; Revert to State 1
    Resume()
  } else { ; Go to State 2
    PostLoggerMessage(WM_PAUSE_LOGGER)
    IsRecordingPlaying := False
    TipBackup = %RecentTip%
    UpdateTip("Paused " + RecentTip)
    buttonToggled["Pause"] := True
    GuiControl, Main: , Pause, [F2]Resume
  }
Return

Resume() {
  PostLoggerMessage(WM_RESUME_LOGGER)
  IsRecordingPlaying := True
  UpdateTip(TipBackup)
  buttonToggled["Pause"] := False
  GuiControl, Main: , Pause, [F2]Pause
}

Play:
  if (buttonToggled["Play"]) { ; Revert to State 1
    if (buttonToggled["Pause"]) 
      Resume()
    PlayEnd()
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
    PlayStart()
    buttonToggled["Play"] := True
    GuiControl, Main: , Play, [F3]Stop
    DisableMainButton("Record")
    DisableMainButton("Exit")
    EnableMainButton("Pause")
    UpdateTip("Playing:" . PlayTitle)
  }
Return

PlayStart() {
global PlayTitle, PlayingPID
  PlayTitle := LatestSelectName
  Run, %AHK% /r %NewRecordPath%,,, OutputPID
  PlayingPID := OutputPID
  SetTimer, CheckPlay, 1000
}

PlayEnd() {
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
  Process, Close, %loggerPID%
  ExitApp

UpdateTip(text:="") {
  global TipToggle ; Cycles trough guis to prevent flickering from Destroying
  if(text = "")
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
state := buttonEnabled[A_GuiControl]
If (A_GuiControl = "Pause") { ; Special treatment, Options function different than Button
  If (!IsRecordingPlaying) {
    OpenOptionGui(A_GuiControl)
  }
  Return
} 
else if (state) {
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
state := buttonEnabled[label]
if (state) {
  OpenOptionGui(label)
}
Return

; Special treatment, Options function different than Button
PauseOptionHotkey:
label := RegExReplace(A_ThisLabel, "OptionHotkey$")
if (!IsRecordingPlaying) {
  OpenOptionGui(label)
}
Return

OpenOptionGui(title) {
  DetectHiddenWindows, On
  ; Check if Gui already created
  Hwnd := guiHwnds[title]
  wasHidden := A_TickCount - lastWMHideTime[Hwnd] > 200 ; byWM (if passed)
  If (title = "Play" || title = "Edit") {
    if (wasHidden) {
      Log("Show", wasHidden)
    } else if (lastWMHideTime[Hwnd]) {
      Gui, %title%: Destroy
      Log("DoNothing", A_TickCount)
      Return
    }
  } 
  else if (WinExist("ahk_id " . Hwnd) + 0) {
    DetectHiddenWindows, Off
    ; Show/Hide Toggle
    window:= title . "Options"
    if (!WinExist(window) && wasHidden) {
      Gui, %title%: show,, %window%
    } else {
      Gui, %title%: hide
    }
    DetectHiddenWindows, On
    Return
  }
  Gui, %title%: +AlwaysOnTop +ToolWindow -Caption 
  Gui, %title%: +LastFound
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
  if(Hwnd != guiHwnds["Main"]) {
    if (wParam = 0) {
      If (Hwnd = guiHwnds["Play"]  || Hwnd = guiHwnds["Edit"]) {
        Log("destr", "WM")
        Gui, Destroy
      }
      Else {
        Gui, Hide
      }
      ; Timer For eliminating Show after Hide
      lastWMHideTime[Hwnd] := A_TickCount
    }
  }
}

LoadRecordOptions() {
  global RecordInputText
  Gui, Record: Add, Edit, x0 w120 h20 vRecordInputText ToolTip, NewRecordName
  Gui, Record: Add, Button, x1 w0 h0 Hidden gSubmitRecord Default, 
  global IsOverride, IsNew, IsAppend
  For i,mode in StrSplit(SaveModes, ",")
  {
    isMode:= FileSaveMode = mode ? "Checked" : ""
    Gui, Record: Add, Checkbox, %isMode% vIs%mode% g%mode%, %mode% 
  }
}

SubmitRecord:
global NewRecordName
  GuiControlGet, inputText, , RecordInputText
  NewRecordName = %inputText%
  UpdateTip("LatestNewRecordName: " . NewRecordName)
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
  global IsAggregate, IsPrecise
  For i,mode in StrSplit(TimingModes, ",")
  {
    isMode:= TimingMode = mode ? "Checked" : ""
    Gui, Pause: Add, Checkbox, x1 %isMode% vIs%mode% g%mode%, %mode%Mode
  }
  
  global PauseInputText, DecreaseSpeed, IncreaseSpeed
  Gui, Pause: Add, Button, x0 w20 h20 vDecreaseSpeed gDecreaseSpeed, -
  Gui, Pause: Add, Button, x+0 w20 h20 vIncreaseSpeed gIncreaseSpeed, +
  Gui, Pause: Add, Edit, x+0 w30 h20 vPauseInputText
  Gui, Pause: Add, Button, x+0 w0 h0 Hidden gSubmitSpeed Default, 
  Gui, Pause: Add, Text, x0, %A_Space%PlaySpeed:%A_Space%
  Gui, Pause: Add, Text, x+0 w50 vPlaySpeed, %A_Space%%PlaySpeed%%A_Space%

  global isLogKeyboard, isLogControl, isLogSpecial, isLogMouse, isLogColor, isLogWindow, isLogSleep
  For name, value in LogOptions {
    isTrue:= value ? "Checked" : ""
    Gui, Pause: Add, Checkbox, x1  %isTrue% vIs%name% g%name%, %name%
  }

}

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

DecreaseSpeed:
global PlaySpeed
  if (PlaySpeed > 2) 
    PlaySpeed--
  else if (PlaySpeed > 0.1)
    PlaySpeed:= PlaySpeed - 0.1
  trimmed := RTrim(PlaySpeed, 0)
  GuiControl,, PlaySpeed, %A_Space%%trimmed%
  LogSpeedChange()
Return

IncreaseSpeed:
global PlaySpeed
  If (PlaySpeed < 2) 
    PlaySpeed:= PlaySpeed + 0.1
  else 
    PlaySpeed++
  trimmed := RTrim(PlaySpeed, 0)
  GuiControl,, PlaySpeed, %A_Space%%trimmed%
  LogSpeedChange()
Return

SubmitSpeed:
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
  LogSpeedChange()
Return

LogSpeedChange() {
  If (buttonToggled["Pause"]) {
    ; Log new speed paramter
  } else {
    ; format the speed of the latestSelection 
  }
}

LogKeyboard:
LogMouse:
LogColor:
LogWindow:
LogSleep:
global IsRecordingPlaying, LogOptions
  LogOptions[A_ThisLabel] := !LogOptions[A_ThisLabel]
  UpdateTip("Set" + A_ThisLabel ": " + LogOptions[A_ThisLabel])
  If (buttonToggled["Pause"]) 
    Redirect%A_ThisLabel%(LogOptions[A_ThisLabel])
Return

LoadPlayOptions() {
  Loop, %RecordFolderPath%\*.ahk
  {
    SplitPath, A_LoopFilePath, FileName
    FileName := StrReplace(FileName, ".ahk", "")
    Gui, Play: Add, Button, h20 gPlayFile, %FileName%
  }
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
  Gui, Exit: Add, Text, x0, %A_Space%WorkDir:%A_Space%
  Gui, Exit: Add, Text, x+0 w50 vWorkDir, %WorkDir%%A_Space%
  
  Gui, Exit: Add, Edit, x0 w120 h20 vExitInputText Tooltip, SetWorkDir
  Gui, Exit: Add, Button, x+0 w0 h0 Hidden gSetWorkDir Default, 
  Loop, Files, %A_ScriptDir%\*.*, D
  {
    dirName := A_LoopFileName
    Gui, Exit: Add, Button, x0 h20 gChangeWorkDir, %dirName%
  }
}

SetWorkDir:
global WorkDir
  GuiControlGet, inputText, , ExitInputText
  WorkDir := inputText
  RecordFolderPath := A_ScriptDir . "\" . WorkDir "\"
  Gui, Play: Destroy
  Gui, Edit: Destroy
  UpdateTip("SetRecordFolder: " . WorkDir)
Return

ChangeWorkDir:
global WorkDir	
  GuiControlGet, ButtonText, FocusV  ; Get the text of the clicked button
  WorkDir := ButtonText
  GuiControl,, WorkDir, %WorkDir%
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
    NewRecordName := "Record_" . A_Now
  }
  else if (FileSaveMode != "Override" && RegExMatch(NewRecordName, "Record_\d{12}")) {
    NewRecordName := "Record_" . A_Now
  }
  else if (FileSaveMode = "New" && !RegExMatch(NewRecordName, "Record_\d{12}")) {
    highest:= 0
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
  
  if (FileSaveMode = "Override" && FileExist(NewRecordPath)) {
    FileDelete %NewRecordPath% 
  }

  NewRecordPath := A_ScriptDir . "\" . WorkDir "\" . NewRecordName . ".ahk"

  if (UpdateLatestSelectOnRecord) {
    LatestSelectPath := NewRecordPath
    LatestSelectName := NewRecordName
  }
}
