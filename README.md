# Mac Keyboard for Windows

Use an Apple Magic Keyboard on Windows the way you would on a Mac.

## Setup

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Download `MacKeyboard.ahk` and double-click it. A green **H** icon appears in the tray.
3. **Start with Windows:** press `Win+R`, type `shell:startup`, and put a shortcut to `MacKeyboard.ahk` in that folder.

## Shortcuts

| Mac | Does |
|---|---|
| ⌘ + any letter/number | Same as Ctrl + key (⌘C, ⌘V, ⌘Z, ⌘T, ⌘W, ⌘S, ...) |
| ⌘⇧Z | Redo |
| ⌘Q | Quit app |
| ⌘H / ⌘M | Minimize |
| ⌘Tab | Switch apps |
| ⌘Space | Search (like Spotlight) |
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
- ⌘L can't be remapped because Windows reserves Win+L for locking. Use Ctrl+L (or F6) for the address bar.
- Some Windows shortcuts (like Win+E, Win+D) now behave as ⌘ shortcuts instead.
