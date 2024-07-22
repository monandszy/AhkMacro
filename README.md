<div align="center">
  <img src="Release/Toolbar.png" alt="Toolbar Description">
</div>

## How to Use:
1. **Download** the latest release or the Monacro folder.
2. **Configure** the constants in the settings file, especially the Editor Path.
3. **Run** `Main.ahk` or `Monacro.exe`.

## Navigation:
- **Left-click** a button or use the visible hotkeys to trigger an action.
- **Right-click** a button or use `Ctrl + Hotkey` to open the options menu.
- **Close the options menu** by repeating the action or losing focus.

## Actions:
- **Record**: Sends a message to unlock/lock the Logger. It will periodically flush the recording.
- **Play**: Runs the most recent script.
- **Pause**: Sends a message to lock the logger or pause the running script.
- **Edit**: Opens the most recent script in the editor.
- **Exit**: Flushes options, stops the Logger, and closes the GUI.

## Options:

### Record
<div align="center">
  <img src="Release/Record.png" alt="Record Options">
</div>

- **Input Field**: Set a name for a new record.
- **New**: Create a new name with a suffix _(d++) based on the highest existing record.
- **Override**: Replace the file if it exists and create a backup.
- **Append**: Add the record to the end of the file. Remove `ExitApp` and `PostMessage` manually.
- **Screen Mode/Window Mode**: Mode of Coordinate Logging.

### Pause
<div align="center">
  <img src="Release/Pause.png" alt="Pause Options">
</div>

- **Precise Mode**: Registers Up and Down presses with precise delay.
- **Aggregate Mode**: Registers only Down presses, combines letters, creates key loops, and has a set delay.
- **SpdR**: Speed of Recording - The speed that is logged during recording.
- **SpdM**: Speed Multiplier - Script PlaySpeed is calculated by (SpdR * SpdM).
- **Various Log Option Toggles**:
  - **Log Color**: Waits for color before clicking.
  - **Log Keyboard**: Registers key presses.
  - **Log Mouse**: Registers mouse clicks and wheel actions.
  - **Log Sleep**: Logs delay between actions.
  - **Log Window**: Logs window changes.

### Play/Edit
<div align="center">
  <img src="Release/Play&Edit.png" alt="Play and Edit Options">
</div>

- **Pick a file** to play or edit.

### Exit
<div align="center">
  <img src="Release/Exit.png" alt="Exit Options">
</div>

- **Open WorkDir** in editor.
- **Create/Pick a WorkDir**. (Folder from which files are shown and recorded to)

## TODO:
- Implement second tooltip updating during script runtime.
- Update mouse delays in precise mode to reflect actual timing.
- Develop a hotkey manager to set hotkeys for scripts in the GUI, based on WorkDir.
- Add functionality to delete/rename files in Edit/Play.
- Make AggregateDelay modifiable (currently set to 200).
- Better gui code management
- Shared util function file

## How it came to be
This is a heavy rewrite of a modification of a macro made by FeiYue, that I found some time ago on reddit (see Deprecated folder) I really liked the toolbar gui concept, some logger logic is also based on the original. This was my first real ahk project, I have somehow hammered the v1 in one week. The option guis are probably a bit overcomplicated, but hey, it works!
## How it works
The program runs in two threads, initialized by the Main file. First the Toolbar gui is initialized in a loop, based on a string list of [key]label. Next are the labels for actions %label%Hotkey that change the Main button states, execute actions, or send messages. After that there are %label%OptionsHotkey that are send to an Option gui recreator, that toggles the create and destroy of the gui, to refresh it's contents. On create a Load%label%Options label is called. Those labels and their respected checkbox/editbox/button action sublabels continue until the end of the file. \
The logger initialzes the hotkeys in pararell with the gui in a suspended state. Most of it's logic consists of if statements that change the logged output.