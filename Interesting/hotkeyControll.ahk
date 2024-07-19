#SingleInstance, force
#NoEnv
SetTitleMatchMode, 2

OnMessage(0x0401, "Say")

Say() {
  MsgBox, Cat
}

Gui, Main: Add, Button, vEnable gEnable, Enable
Gui, Main: Add, Button, vDisable gDisable, Disable
Gui, Main: Add, Button,, Cat

Hotkey, F11, Enable
Hotkey, F12, Disable
Gui, Main: Show 

; F11::
Enable:
GuiControl, Enable , Cat
; GuiControl, Main: Enable , Cat
return

; F12::
Disable:
GuiControl, Disable , Cat
; GuiControl, Main: Disable , Cat
return