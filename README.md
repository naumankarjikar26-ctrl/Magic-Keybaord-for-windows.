# Mac Keyboard for Windows

Use an Apple Magic Keyboard on Windows the way you would on a Mac.

## Setup

1. Download **`MacKeyboard.exe`** from the [Releases](../../releases) page (no AutoHotkey needed),
   move it somewhere permanent (like Documents), and double-click it.
   Choose **Yes** on the admin prompt. An icon appears in the tray.
   *(Or install [AutoHotkey v2](https://www.autohotkey.com/) and run `MacKeyboard.ahk` instead.)*
3. **Restart your PC once** when it asks — that's when ⌘ starts acting like a Mac's.
4. That's it — it now starts automatically with Windows. To turn that off, right-click the tray icon → uncheck *Start with Windows*.

## Shortcuts

| Mac | Does |
|---|---|
| ⌘ + any letter/number | Same as Ctrl + key (⌘C, ⌘V, ⌘Z, ⌘T, ⌘W, ⌘S, ...) |
| ⌘⇧Z | Redo |
| ⌘Q | Quit app |
| ⌘M | Minimize |
| ⌘Tab | Switch apps |
| ⌃← ⌃→ | Switch desktop (like Spaces) |
| ⌃↑ | Task View (like Mission Control) |
| ⌘Space or ⌘\\ | Open Start menu |
| ⌘E | Open File Explorer |
| ⌃⌘F | Full screen |
| ⌃⌘Q | Lock screen |
| ⌘⇧S | Snip an area, copy to clipboard only |
| ⌘⇧X (or ⌘⇧4) | Snip an area, copy and save to Pictures\Screenshots |
| ⌘⇧3 | Screenshot |
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

**Touch ID key:** Windows can't use the fingerprint sensor, but the key can work as a button.
Right-click the tray icon → *Set up Touch ID key...* and press it once. Then tap = lock, hold 1 second = sleep.

## Magic Keyboard or regular keyboard

Using a normal Windows keyboard for a while? Right-click the tray icon → *Keyboard: Regular Windows keyboard*.
All Mac shortcuts turn off and ⌘ works as the Windows key again — no restart. Switch back with *Keyboard: Magic Keyboard*.

## Turn off a laptop's built-in keyboard

Magic Keyboard sitting on top of your laptop? Right-click the tray icon → *Turn off built-in keyboard*.
Click it again to turn it back on. Some PCs need a restart for it to take effect.

## Notes

- Pause everything any time: tray icon → *Suspend Hotkeys*.
- Windows is told to treat ⌘ as a spare key (a keyboard "Scancode Map"), and the app turns it into Ctrl — that's why even ⌘L works.
  While the app is closed, ⌘ (and a regular keyboard's Windows key) does nothing. Use Windows mode instead of quitting.
- In Mac mode, use ⌘Space for Start. To remove the ⌘ setup completely: tray icon → uncheck *⌘ works as Ctrl*, then restart.
- This applies to every keyboard on the PC, including a laptop's built-in one.
