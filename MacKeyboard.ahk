; Mac Keyboard for Windows
; Makes an Apple Magic Keyboard behave like it does on a Mac.
; Requires AutoHotkey v2: https://www.autohotkey.com
;
;   Command (⌘)  -> acts like Ctrl for shortcuts (⌘C, ⌘V, ⌘T, ...)
;   Option  (⌥)  -> word-by-word text navigation
;   Control (⌃)  -> unchanged

#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook
A_MenuMaskKey := "vkE8"  ; stops a lone Win/Alt release from opening Start or menus

; ===== Settings =====
; true = top-row F7-F12 act as media keys like on a Mac (can also be toggled from the tray icon)
global MAC_MEDIA_KEYS := false

; ===== App groups =====
for exe in ["chrome.exe", "msedge.exe", "firefox.exe", "brave.exe", "opera.exe", "vivaldi.exe", "arc.exe"]
    GroupAdd "Browsers", "ahk_exe " exe
GroupAdd "Explorer", "ahk_class CabinetWClass"
GroupAdd "Explorer", "ahk_class ExploreWClass"

; ===== Tray =====
A_IconTip := "Mac Keyboard for Windows"
A_TrayMenu.Add()
A_TrayMenu.Add("Mac media keys (F7-F12)", ToggleMedia)
if MAC_MEDIA_KEYS
    A_TrayMenu.Check("Mac media keys (F7-F12)")

ToggleMedia(name, *) {
    global MAC_MEDIA_KEYS := !MAC_MEDIA_KEYS
    A_TrayMenu.ToggleCheck(name)
}

; ===== ⌘ + key  ->  Ctrl + key =====
keys := StrSplit("abcdefghijklmnopqrstuvwxyz0123456789")
for k in ["-", "=", "[", "]", "`;", "'", ",", ".", "/", "\"]
    keys.Push(k)
skipPlain := Map("q", 1, "h", 1, "m", 1)           ; handled specially below
skipShift := Map("z", 1, "3", 1, "4", 1, "5", 1)   ; handled specially below
for k in keys {
    if !skipPlain.Has(k)
        Hotkey "#" k, SendKey.Bind("^", k)
    if !skipShift.Has(k)
        Hotkey "#+" k, SendKey.Bind("^+", k)
}
SendKey(mods, key, *) => Send(mods "{" key "}")

; ===== Mac-style app & system shortcuts =====
#q::Send "!{F4}"                     ; ⌘Q  quit app
#h::WinMinimize "A"                  ; ⌘H  hide
#m::WinMinimize "A"                  ; ⌘M  minimize
^#q::DllCall "LockWorkStation"       ; ⌃⌘Q lock screen
^#f::Send "{F11}"                    ; ⌃⌘F full screen
#Space::Send "#s"                    ; ⌘Space  search (like Spotlight)
#+z::Send "^y"                       ; ⌘⇧Z redo
#+3::Send "{PrintScreen}"            ; ⌘⇧3 screenshot
#+4::Send "#+s"                      ; ⌘⇧4 snip area
#+5::Send "#+s"                      ; ⌘⇧5 snip tool
LWin & Tab::AltTab                   ; ⌘Tab switch apps
RWin & Tab::AltTab

; ===== Text navigation =====
#Left::Send "{Home}"                 ; ⌘←  line start
#Right::Send "{End}"                 ; ⌘→  line end
#Up::Send "^{Home}"                  ; ⌘↑  document start
#Down::Send "^{End}"                 ; ⌘↓  document end
#+Left::Send "+{Home}"
#+Right::Send "+{End}"
#+Up::Send "^+{Home}"
#+Down::Send "^+{End}"
#BS::Send "+{Home}{Delete}"          ; ⌘⌫  delete to line start

!Left::Send "^{Left}"                ; ⌥←  previous word
!Right::Send "^{Right}"              ; ⌥→  next word
!+Left::Send "^+{Left}"
!+Right::Send "^+{Right}"
!BS::Send "^{BS}"                    ; ⌥⌫  delete word

; ===== File Explorer (like Finder) =====
#HotIf WinActive("ahk_group Explorer")
#BS::Send "{Delete}"                 ; ⌘⌫  move to Recycle Bin
#Up::Send "!{Up}"                    ; ⌘↑  parent folder
#Down::Send "{Enter}"                ; ⌘↓  open

#HotIf WinActive("ahk_group Browsers") || WinActive("ahk_group Explorer")
#[::Send "!{Left}"                   ; ⌘[  back
#]::Send "!{Right}"                  ; ⌘]  forward

#HotIf WinActive("ahk_group Browsers")
#+z::Send "^+z"                      ; ⌘⇧Z redo (Ctrl+Y opens history in browsers)

; ===== Optional Mac media keys =====
#HotIf MAC_MEDIA_KEYS
F7::Send "{Media_Prev}"
F8::Send "{Media_Play_Pause}"
F9::Send "{Media_Next}"
F10::Send "{Volume_Mute}"
F11::Send "{Volume_Down}"
F12::Send "{Volume_Up}"
#HotIf
