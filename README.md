# Mac Keyboard for Windows

Use an Apple Magic Keyboard on Windows the way you would on a Mac.

## Setup

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Download `MacKeyboard.ahk`, move it somewhere permanent (like Documents), and double-click it.
   Choose **Yes** on the admin prompt (needed for ⌘L). A green **H** icon appears in the tray.
3. That's it — it now starts automatically with Windows. To turn that off, right-click the tray icon → uncheck *Start with Windows*.

## Shortcuts

| Mac | Does |
|---|---|
| ⌘ + any letter/number | Same as Ctrl + key (⌘C, ⌘V, ⌘Z, ⌘T, ⌘W, ⌘S, ...) |
| ⌘⇧Z | Redo |
| ⌘Q | Quit app |
| ⌘H / ⌘M | Minimize |
| ⌘Tab | Switch apps |
| ⌘Space | Open Start menu |
| ⌘E | Open File Explorer |
| ⌃⌘F | Full screen |
| ⌃⌘Q | Lock screen |
| ⌘⇧3 / ⌘⇧4 | Screenshot / snip area |
| ⌘← ⌘→ / ⌘↑ ⌘↓ | Line start/end / document start/end (add ⇧ to select) |
| ⌥← ⌥→ | Jump by word (add ⇧ to select) |
| ⌘⌫ / ⌥⌫ | Delete to line start / delete word |
| ⌘[ ⌘] | Back / forward (browsers, Explorer) |
| In Explorer: ⌘⌫, ⌘↑, ⌘↓ | Delete file, parent folder, open |

**Top-row keys** (on by default, like a Mac):

| Key | Does |
|---|---|
| F1 / F2 | Brightness down / up |
| F7 / F8 / F9 | Previous / play-pause / next |
| F10 / F11 / F12 | Mute / volume down / volume up |

Need real F-keys? Right-click the tray icon → uncheck *Mac top-row keys*.
Brightness works on laptop screens, and on external monitors that support DDC/CI (usually an on/off option in the monitor's own menu).

## Notes

- Pause everything any time: tray icon → *Suspend Hotkeys*.
- ⌘L works like Ctrl+L (address bar). To make that possible, Windows' own Win+L lock is turned off while the script runs — lock with ⌃⌘Q instead. Win+L comes back when you exit the script.
- Some Windows shortcuts (like Win+D) now behave as ⌘ shortcuts instead.
