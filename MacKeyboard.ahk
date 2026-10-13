; Mac Keyboard for Windows
; Makes an Apple Magic Keyboard behave like it does on a Mac.
; Requires AutoHotkey v2: https://www.autohotkey.com
;
;   Command (⌘)  -> Ctrl, done by Windows itself (so ⌘C, ⌘V, ⌘L, ... just work)
;   Option  (⌥)  -> word-by-word text navigation
;   Control (⌃)  -> unchanged
;
; How: a Windows "Scancode Map" turns both ⌘ keys into the RIGHT Ctrl key (needs one restart).
; The Magic Keyboard has no right Ctrl, so in this script >^ (right Ctrl) always means ⌘,
; and the real Control key stays separate (⌃Tab still switches browser tabs, like on a Mac).

#Requires AutoHotkey v2.0
#SingleInstance Force

; Run as administrator: needed to set up ⌘ and to start with Windows,
; and lets shortcuts work in admin apps too.
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
        WinWaitClose hwnd, , 2
    }
DetectHiddenWindows false

InstallKeybdHook
VERSION := "9"
SETTINGS_KEY := "HKCU\Software\MacKeyboardForWindows"

; ===== Settings =====
; true = top-row keys act like on a Mac: F1/F2 brightness, F7-F9 media, F10-F12 volume
; (can also be toggled from the tray icon; turn off when you need real F-keys)
global MAC_MEDIA_KEYS := true

; ===== ⌘ -> Ctrl (Scancode Map) =====
KEYMAP_KEY := "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout"
; header, 2 mappings + terminator, LWin(E05B)->RCtrl(E01D), RWin(E05C)->RCtrl(E01D), end
CMD_MAP := "0000000000000000030000001DE05BE01DE05CE000000000"

CmdMapInstalled() {
    try return RegRead(KEYMAP_KEY, "Scancode Map") = CMD_MAP
    return false
}

SetCmdMap(on) {
    try {
        if on
            RegWrite CMD_MAP, "REG_BINARY", KEYMAP_KEY, "Scancode Map"
        else
            RegDelete KEYMAP_KEY, "Scancode Map"
        RegWrite on, "REG_DWORD", SETTINGS_KEY, "CmdAsCtrl"
        return true
    }
    return false
}

; Clean up the old Win+L workaround from earlier versions
try RegDelete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System", "DisableLockWorkstation"

if RegRead(SETTINGS_KEY, "CmdAsCtrl", 1) && !CmdMapInstalled() {
    if SetCmdMap(true)
        MsgBox "Almost done! Restart your PC once so ⌘ starts working like on a Mac.", "Mac Keyboard"
    else
        MsgBox "Couldn't set up ⌘. Start the script again and choose Yes on the admin prompt.", "Mac Keyboard"
}

; ===== App groups =====
for exe in ["chrome.exe", "msedge.exe", "firefox.exe", "brave.exe", "opera.exe", "vivaldi.exe", "arc.exe"]
    GroupAdd "Browsers", "ahk_exe " exe
GroupAdd "Explorer", "ahk_class CabinetWClass"
GroupAdd "Explorer", "ahk_class ExploreWClass"

; ===== Tray =====
A_IconTip := "Mac Keyboard v" VERSION (A_IsAdmin ? " (admin)" : " (not admin)")
TrayTip "Running" (A_IsAdmin ? " as admin" : ""), "Mac Keyboard v" VERSION
A_TrayMenu.Add()
A_TrayMenu.Add("Mac top-row keys (brightness, media, volume)", ToggleMedia)
if MAC_MEDIA_KEYS
    A_TrayMenu.Check("Mac top-row keys (brightness, media, volume)")
A_TrayMenu.Add("⌘ works as Ctrl (restart after changing)", ToggleCmdMap)
if CmdMapInstalled()
    A_TrayMenu.Check("⌘ works as Ctrl (restart after changing)")

ToggleMedia(name, *) {
    global MAC_MEDIA_KEYS := !MAC_MEDIA_KEYS
    A_TrayMenu.ToggleCheck(name)
}

ToggleCmdMap(name, *) {
    on := !CmdMapInstalled()
    if !SetCmdMap(on)
        return MsgBox("Start the script again and choose Yes on the admin prompt to change this.", "Mac Keyboard")
    A_TrayMenu.ToggleCheck(name)
    MsgBox "Restart your PC for this to take effect." (on ? "" : "`n`n⌘ will be the Windows key again."), "Mac Keyboard"
}

; ===== Start with Windows =====
; On by default: a scheduled task starts this script (as admin, with no prompt) when you sign in.
; Untick it in the tray menu to turn off.
TASK_NAME := "MacKeyboard"
try FileDelete A_Startup "\Mac Keyboard.lnk"  ; replaced by the scheduled task
A_TrayMenu.Add("Start with Windows", ToggleStartup)
if RegRead(SETTINGS_KEY, "AutoStart", 1) && A_IsAdmin {
    A_TrayMenu.Check("Start with Windows")
    SetTimer () => SetStartup(true), -3000  ; in the background; also fixes it if the file moved
}

ToggleStartup(name, *) {
    on := !RegRead(SETTINGS_KEY, "AutoStart", 1)
    if !A_IsAdmin || !SetStartup(on, true)
        return MsgBox("Start the script again and choose Yes on the admin prompt to change this.", "Mac Keyboard")
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
; (⌘ + letters/numbers need nothing here: Windows already sees them as Ctrl + key)
>^q::Send "!{F4}"                    ; ⌘Q  quit app
>^m::WinMinimize "A"                 ; ⌘M  minimize
>^e::Run "explorer.exe"              ; ⌘E  open File Explorer
>^Space::Send "{LWin}"               ; ⌘Space  open Start menu
<^>^q::DllCall "LockWorkStation"     ; ⌃⌘Q lock screen
<^>^f::Send "{F11}"                  ; ⌃⌘F full screen
>^+z::Send "^y"                      ; ⌘⇧Z redo
>^+3::Send "{PrintScreen}"           ; ⌘⇧3 screenshot
>^+4::Send "#+s"                     ; ⌘⇧4 snip area
>^+5::Send "#+s"                     ; ⌘⇧5 snip tool

; Desktops, like Spaces on a Mac (the real Control key)
<^Left::Send "^#{Left}"              ; ⌃←  previous desktop
<^Right::Send "^#{Right}"            ; ⌃→  next desktop
<^Up::Send "#{Tab}"                  ; ⌃↑  Task View (like Mission Control)

; ⌘Tab switch apps (hold ⌘, tap Tab; add ⇧ to go back)
global AltTabbing := false
*>^Tab::AltTabStep()
#HotIf AltTabbing
*Tab::AltTabStep()
#HotIf
~*RCtrl Up:: {
    global AltTabbing
    if AltTabbing {
        AltTabbing := false
        Send "{Alt up}"
    }
}
AltTabStep(*) {
    global AltTabbing
    if !AltTabbing {
        AltTabbing := true
        Send "{Blind}{RCtrl up}{Alt down}"  ; drop Ctrl so Windows sees a plain Alt+Tab
    }
    Send "{Blind}{Tab}"
}

; ===== Text navigation =====
>^Left::Send "{Home}"                ; ⌘←  line start
>^Right::Send "{End}"                ; ⌘→  line end
>^Up::Send "^{Home}"                 ; ⌘↑  document start
>^Down::Send "^{End}"                ; ⌘↓  document end
>^+Left::Send "+{Home}"
>^+Right::Send "+{End}"
>^+Up::Send "^+{Home}"
>^+Down::Send "^+{End}"
>^BS::Send "+{Home}{Delete}"         ; ⌘⌫  delete to line start

!Left::Send "^{Left}"                ; ⌥←  previous word
!Right::Send "^{Right}"              ; ⌥→  next word
!+Left::Send "^+{Left}"
!+Right::Send "^+{Right}"
!BS::Send "^{BS}"                    ; ⌥⌫  delete word

; ===== File Explorer (like Finder) =====
#HotIf WinActive("ahk_group Explorer")
>^BS::Send "{Delete}"                ; ⌘⌫  move to Recycle Bin
>^Up::Send "!{Up}"                   ; ⌘↑  parent folder
>^Down::Send "{Enter}"               ; ⌘↓  open

#HotIf WinActive("ahk_group Browsers") || WinActive("ahk_group Explorer")
>^[::Send "!{Left}"                  ; ⌘[  back
>^]::Send "!{Right}"                 ; ⌘]  forward

#HotIf WinActive("ahk_group Browsers")
>^+z::Send "^+z"                     ; ⌘⇧Z redo (Ctrl+Y opens history in browsers)

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
