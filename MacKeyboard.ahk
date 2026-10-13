; Mac Keyboard for Windows
; Makes an Apple Magic Keyboard behave like it does on a Mac.
; Requires AutoHotkey v2: https://www.autohotkey.com
;
;   Command (⌘)  -> acts like Ctrl for shortcuts (⌘C, ⌘V, ⌘T, ...)
;   Option  (⌥)  -> word-by-word text navigation
;   Control (⌃)  -> unchanged

#Requires AutoHotkey v2.0
#SingleInstance Force

; Run as administrator: needed to free up ⌘L (see below), and lets shortcuts work in admin apps too.
; If you say No to the prompt, everything else still works.
if !A_IsAdmin {
    try {
        Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
        ExitApp
    }
}

; Close any other running copy of this script (e.g. an old copy in another folder)
DetectHiddenWindows true
SetTitleMatchMode 2
for hwnd in WinGetList("MacKeyboard ahk_class AutoHotkey")
    if hwnd != A_ScriptHwnd {
        try PostMessage 0x111, 65307, , , hwnd  ; tray menu "Exit"
        WinWaitClose hwnd, , 2                  ; let it finish before we change settings
    }
DetectHiddenWindows false

InstallKeybdHook
A_MenuMaskKey := "vkE8"  ; stops a lone Win/Alt release from opening Start or menus

; ===== Settings =====
; true = top-row keys act like on a Mac: F1/F2 brightness, F7-F9 media, F10-F12 volume
; (can also be toggled from the tray icon; turn off when you need real F-keys)
global MAC_MEDIA_KEYS := true

; ===== ⌘ + key  ->  Ctrl + key =====
keys := StrSplit("abcdefghijklmnopqrstuvwxyz0123456789")
for k in ["-", "=", "[", "]", "`;", "'", ",", ".", "/", "\"]
    keys.Push(k)
skipPlain := Map("e", 1, "q", 1, "h", 1, "m", 1)   ; handled specially below
skipShift := Map("z", 1, "3", 1, "4", 1, "5", 1)   ; handled specially below
for k in keys {
    if !skipPlain.Has(k)
        Hotkey "#" k, SendKey.Bind("^", k)
    if !skipShift.Has(k)
        Hotkey "#+" k, SendKey.Bind("^+", k)
}
SendKey(mods, key, *) => Send(mods "{" key "}")

; ===== Free up ⌘L =====
; Windows locks the screen on Win+L before any script can catch it, so turn that
; shortcut off while this script runs (⌃⌘Q still locks) and turn it back on when it exits.
; Needs admin rights.
LOCK_POLICY := "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System"
SetWinLLock(on) {
    try RegWrite on ? 0 : 1, "REG_DWORD", LOCK_POLICY, "DisableLockWorkstation"
}
SetWinLLock(false)
OnExit (*) => SetWinLLock(true)

LockScreen(*) {
    SetWinLLock(true)
    DllCall "LockWorkStation"
    Sleep 1000
    SetWinLLock(false)
}

; ===== App groups =====
for exe in ["chrome.exe", "msedge.exe", "firefox.exe", "brave.exe", "opera.exe", "vivaldi.exe", "arc.exe"]
    GroupAdd "Browsers", "ahk_exe " exe
GroupAdd "Explorer", "ahk_class CabinetWClass"
GroupAdd "Explorer", "ahk_class ExploreWClass"

; ===== Tray =====
A_IconTip := "Mac Keyboard for Windows" (A_IsAdmin ? "" : " (not admin: ⌘L off)")
A_TrayMenu.Add()
A_TrayMenu.Add("Mac top-row keys (brightness, media, volume)", ToggleMedia)
if MAC_MEDIA_KEYS
    A_TrayMenu.Check("Mac top-row keys (brightness, media, volume)")

ToggleMedia(name, *) {
    global MAC_MEDIA_KEYS := !MAC_MEDIA_KEYS
    A_TrayMenu.ToggleCheck(name)
}

; ===== Start with Windows =====
; On by default: a scheduled task starts this script (as admin, with no prompt) when you sign in.
; Untick it in the tray menu to turn off.
TASK_NAME := "MacKeyboard"
SETTINGS_KEY := "HKCU\Software\MacKeyboardForWindows"
try FileDelete A_Startup "\Mac Keyboard.lnk"  ; replaced by the scheduled task
A_TrayMenu.Add("Start with Windows", ToggleStartup)
if RegRead(SETTINGS_KEY, "AutoStart", 1) && A_IsAdmin {
    A_TrayMenu.Check("Start with Windows")
    SetTimer () => SetStartup(true), -3000  ; in the background; also fixes it if the file moved
}

ToggleStartup(name, *) {
    on := !RegRead(SETTINGS_KEY, "AutoStart", 1)
    if !A_IsAdmin || !SetStartup(on, true)
        return MsgBox("Restart the script and choose Yes on the admin prompt to change this.", "Mac Keyboard")
    RegWrite on, "REG_DWORD", SETTINGS_KEY, "AutoStart"
    A_TrayMenu.ToggleCheck(name)
}

SetStartup(on, wait := false) {
    if !on
        return RunWait('schtasks /Delete /F /TN "' TASK_NAME '"', , "Hide") = 0
    ps := "
    (
    param($ahk, $script, $name)
    $ErrorActionPreference = 'Stop'
    $user = $env:USERDOMAIN + '\' + $env:USERNAME
    $a = New-ScheduledTaskAction -Execute $ahk -Argument ([char]34 + $script + [char]34)
    $t = New-ScheduledTaskTrigger -AtLogOn -User $user
    $s = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan)
    $p = New-ScheduledTaskPrincipal -UserId $user -RunLevel Highest -LogonType Interactive
    Register-ScheduledTask -TaskName $name -Action $a -Trigger $t -Settings $s -Principal $p -Force | Out-Null
    )"
    file := A_Temp "\MacKeyboardTask.ps1"
    try FileDelete file
    FileAppend ps, file
    cmd := 'powershell -NoProfile -ExecutionPolicy Bypass -File "' file '" "' A_AhkPath '" "' A_ScriptFullPath '" "' TASK_NAME '"'
    if !wait
        return Run(cmd, , "Hide")
    return RunWait(cmd, , "Hide") = 0
}

; ===== Mac-style app & system shortcuts =====
#q::Send "!{F4}"                     ; ⌘Q  quit app
#h::WinMinimize "A"                  ; ⌘H  hide
#m::WinMinimize "A"                  ; ⌘M  minimize
^#q::LockScreen()                    ; ⌃⌘Q lock screen
^#f::Send "{F11}"                    ; ⌃⌘F full screen
#Space:: {                           ; ⌘Space  open Start menu
    KeyWait "LWin", "T3"             ; wait until ⌘ is let go, or Windows closes Start again
    KeyWait "RWin", "T3"
    Send "{LWin}"
}
#e::Run "explorer.exe"               ; ⌘E  open File Explorer
#+z::Send "^y"                       ; ⌘⇧Z redo
#+3::Send "{PrintScreen}"            ; ⌘⇧3 screenshot
#+4::Send "#+s"                      ; ⌘⇧4 snip area
#+5::Send "#+s"                      ; ⌘⇧5 snip tool
~LWin::Send "{Blind}{vkE8}"          ; tapping ⌘ alone doesn't open Start (like a Mac)
~RWin::Send "{Blind}{vkE8}"
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

; ===== Mac top-row keys =====
#HotIf MAC_MEDIA_KEYS
F1::ChangeBrightness(-10)
F2::ChangeBrightness(10)
F7::Send "{Media_Prev}"
F8::Send "{Media_Play_Pause}"
F9::Send "{Media_Next}"
F10::Send "{Volume_Mute}"
F11::Send "{Volume_Down}"
F12::Send "{Volume_Up}"
#HotIf

; ===== Brightness =====
ChangeBrightness(step) {
    ; Laptop / built-in screens (WMI)
    level := ""
    try {
        wmi := ComObjGet("winmgmts:\\.\root\WMI")
        for m in wmi.ExecQuery("SELECT CurrentBrightness FROM WmiMonitorBrightness")
            level := Max(0, Min(100, m.CurrentBrightness + step))
        if level != "" {
            for m in wmi.ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods")
                m.WmiSetBrightness(1, level)
            return ShowLevel("Brightness", level)
        }
    }

    ; External monitors (DDC/CI) - the monitor showing the active window
    hMon := DllCall("MonitorFromWindow", "Ptr", WinExist("A"), "UInt", 1, "Ptr")
    count := 0
    if !DllCall("dxva2\GetNumberOfPhysicalMonitorsFromHMONITOR", "Ptr", hMon, "UInt*", &count) || !count
        return ShowLevel("Brightness not supported on this display")
    size := A_PtrSize + 256  ; PHYSICAL_MONITOR: HANDLE + WCHAR[128]
    mons := Buffer(size * count, 0)
    if !DllCall("dxva2\GetPhysicalMonitorsFromHMONITOR", "Ptr", hMon, "UInt", count, "Ptr", mons)
        return ShowLevel("Brightness not supported on this display")
    loop count {
        h := NumGet(mons, (A_Index - 1) * size, "Ptr")
        lo := 0, cur := 0, hi := 0
        if DllCall("dxva2\GetMonitorBrightness", "Ptr", h, "UInt*", &lo, "UInt*", &cur, "UInt*", &hi) {
            level := Max(lo, Min(hi, cur + Round(step * (hi - lo) / 100)))
            DllCall("dxva2\SetMonitorBrightness", "Ptr", h, "UInt", level)
        }
    }
    DllCall("dxva2\DestroyPhysicalMonitors", "UInt", count, "Ptr", mons)
    ShowLevel(level = "" ? "Brightness not supported on this display" : "Brightness", level)
}

ShowLevel(label, level := "") {
    ToolTip level = "" ? label : label ": " level "%"
    SetTimer () => ToolTip(), -1000
}
