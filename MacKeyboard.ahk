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
VERSION := "13"
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

; ===== Touch ID key: tap = lock, hold = sleep =====
; Windows has no Touch ID driver, so the script "learns" what the key sends
; (tray menu -> Set up Touch ID key...) and listens for it.
TOUCH_HOLD_MS := 1000
global TouchLearning := false, TouchSig := "", TouchRelease := true, TouchHotkey := ""
global TouchDown := false, TouchHeldFired := false, LearnSig := "", LearnGui := 0, LearnIH := 0
A_TrayMenu.Add("Set up Touch ID key...", LearnTouchKey)
RegisterRawInput()
OnMessage 0x00FF, OnRawInput  ; WM_INPUT
LoadTouchKey()

RegisterRawInput() {
    ; consumer keys, system keys, and Apple's own key pages
    size := 8 + A_PtrSize
    for p in [[0x0C, 0x01], [0x01, 0x80], [0xFF00, 0x01], [0x00FF, 0x01], [0x00FF, 0x03]] {
        rid := Buffer(size, 0)
        NumPut "UShort", p[1], "UShort", p[2], "UInt", 0x100, "Ptr", A_ScriptHwnd, rid  ; 0x100 = also in background
        DllCall "RegisterRawInputDevices", "Ptr", rid, "UInt", 1, "UInt", size
    }
}

LoadTouchKey() {
    global TouchSig, TouchRelease, TouchHotkey
    if TouchHotkey != "" {
        try Hotkey TouchHotkey, "Off"
        TouchHotkey := ""
    }
    kind := RegRead(SETTINGS_KEY, "TouchKeyType", "")
    value := RegRead(SETTINGS_KEY, "TouchKeyValue", "")
    TouchRelease := RegRead(SETTINGS_KEY, "TouchKeyRelease", 1)
    TouchSig := kind = "hid" ? value : ""
    if kind = "key" {
        TouchHotkey := "*" value
        try Hotkey TouchHotkey, TouchKeyPressed, "On"
    }
}

TouchKeyPressed(thisHotkey) {
    key := SubStr(thisHotkey, 2)
    if KeyWait(key, "T" TOUCH_HOLD_MS / 1000)
        DllCall "LockWorkStation"
    else {
        SleepPC()
        KeyWait key
    }
}

SleepPC() {
    DllCall "PowrProf\SetSuspendState", "Int", 0, "Int", 0, "Int", 0
}

TouchHeld() {
    global TouchHeldFired := true
    SleepPC()
}

OnRawInput(wParam, lParam, *) {
    global TouchDown, TouchHeldFired, LearnSig
    hdr := 8 + 2 * A_PtrSize  ; RAWINPUTHEADER
    size := 0
    DllCall "GetRawInputData", "Ptr", lParam, "UInt", 0x10000003, "Ptr", 0, "UInt*", &size, "UInt", hdr
    if size <= hdr + 8
        return
    buf := Buffer(size)
    DllCall "GetRawInputData", "Ptr", lParam, "UInt", 0x10000003, "Ptr", buf, "UInt*", &size, "UInt", hdr
    if NumGet(buf, 0, "UInt") != 2  ; RIM_TYPEHID
        return
    n := NumGet(buf, hdr, "UInt")
    hex := "", pressed := false
    loop n {
        b := NumGet(buf, hdr + 8 + A_Index - 1, "UChar")
        hex .= Format("{:02X}", b)
        if b && (A_Index > 1 || n = 1)  ; first byte is usually the report ID
            pressed := true
    }

    if TouchLearning {
        if LearnSig = "" {
            if pressed {
                LearnSig := hex
                SetTimer LearnHidFinish, -3000  ; wait to see if the key also reports being let go
            }
        } else if hex != LearnSig
            LearnDone("hid", LearnSig, true)
        return
    }

    if TouchSig = ""
        return
    if hex = TouchSig {
        if !TouchRelease
            return DllCall("LockWorkStation")  ; key only reports presses: tap = lock
        if !TouchDown {
            TouchDown := true, TouchHeldFired := false
            SetTimer TouchHeld, -TOUCH_HOLD_MS
        }
    } else if TouchDown {
        TouchDown := false
        SetTimer TouchHeld, 0
        if !TouchHeldFired
            DllCall "LockWorkStation"
    }
}

LearnTouchKey(*) {
    global TouchLearning, LearnSig, LearnGui, LearnIH
    if TouchLearning
        return
    LearnSig := ""
    LearnGui := Gui("+AlwaysOnTop -MinimizeBox", "Set up Touch ID key")
    LearnGui.SetFont("s11", "Segoe UI")
    LearnGui.Add("Text", "w340", "Press and let go of the Touch ID key (top right of the keyboard).")
    LearnGui.Add("Button", "w90", "Cancel").OnEvent("Click", (*) => LearnDone("", ""))
    LearnGui.OnEvent("Close", (*) => LearnDone("", ""))
    LearnGui.Show()
    TouchLearning := true
    LearnIH := InputHook("T20")
    LearnIH.KeyOpt("{All}", "E")
    LearnIH.OnEnd := LearnKeyEnded
    LearnIH.Start()
}

LearnKeyEnded(ih) {
    if !TouchLearning
        return
    if ih.EndReason = "EndKey" && ih.EndKey != "Escape"
        LearnDone("key", ih.EndKey)
    else if ih.EndReason = "Timeout"
        LearnDone("none", "")
    else
        LearnDone("", "")
}

LearnHidFinish() {
    LearnDone("hid", LearnSig, false)
}

LearnDone(kind, value, release := true) {
    global TouchLearning
    if !TouchLearning
        return
    TouchLearning := false
    SetTimer LearnHidFinish, 0
    try LearnIH.Stop()
    try LearnGui.Destroy()
    if kind = ""
        return
    if kind = "none"
        return MsgBox("Windows didn't get anything from the Touch ID key, so it can't be used on this PC.", "Mac Keyboard")
    RegWrite kind, "REG_SZ", SETTINGS_KEY, "TouchKeyType"
    RegWrite value, "REG_SZ", SETTINGS_KEY, "TouchKeyValue"
    RegWrite release, "REG_DWORD", SETTINGS_KEY, "TouchKeyRelease"
    LoadTouchKey()
    MsgBox "Done! Tap the Touch ID key to lock" (release ? ", hold it for 1 second to sleep." : ".`n(This key doesn't report being held, so hold-to-sleep isn't possible.)"), "Mac Keyboard"
}

; ===== Mac-style app & system shortcuts =====
; (⌘ + letters/numbers need nothing here: Windows already sees them as Ctrl + key)
>^q::Send "!{F4}"                    ; ⌘Q  quit app
>^m::WinMinimize "A"                 ; ⌘M  minimize
>^e::Run "explorer.exe"              ; ⌘E  open File Explorer
>^Space::OpenStart()                 ; ⌘Space  open Start menu
>^\::OpenStart()                     ; ⌘\  open Start menu too
<^>^q::DllCall "LockWorkStation"     ; ⌃⌘Q lock screen
<^>^f::Send "{F11}"                  ; ⌃⌘F full screen
>^+z::Send "^y"                      ; ⌘⇧Z redo
>^+3::Send "{PrintScreen}"           ; ⌘⇧3 screenshot
>^+s::Screenshot("copy")             ; ⌘⇧S snip area -> clipboard only
>^+x::Screenshot("save")             ; ⌘⇧X snip area -> clipboard + file
>^+4::Screenshot("save")             ; ⌘⇧4 snip area -> file (like a Mac)
>^+5::Screenshot("save")

; Desktops, like Spaces on a Mac (the real Control key)
<^Left::Send "^#{Left}"              ; ⌃←  previous desktop
<^Right::Send "^#{Right}"            ; ⌃→  next desktop
<^Up::Send "#{Tab}"                  ; ⌃↑  Task View (like Mission Control)

OpenStart(*) {
    ToolTip "Opening Start..."           ; shows the shortcut was caught
    SetTimer () => ToolTip(), -800
    KeyWait "RCtrl", "T3"                ; wait for ⌘ to be let go
    Send "{LWin}"
}

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

; ===== Brightness pop-up (bottom of the screen, like the volume one) =====
ShowLevel(label, level := "") {
    global LevelOsd
    static osd := 0
    if !osd {
        osd := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")  ; E0x20 = clicks pass through
        osd.BackColor := "202020"
        osd.MarginX := 0, osd.MarginY := 0
        osd.SetFont("s14 cWhite", "Segoe UI Symbol")
        osd.Add("Text", "x18 y10 w26 h28 vIcon", "☀")
        osd.SetFont("s11 cWhite", "Segoe UI")
        osd.Add("Progress", "x52 y21 w170 h6 Background505050 c4CC2FF vBar Range0-100")
        osd.Add("Text", "x232 y13 w44 h24 vPct")
        osd.Add("Text", "x52 y13 w224 h24 vMsg Hidden")
        try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", osd.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)  ; round corners
        LevelOsd := osd
    }
    hasLevel := level != ""
    osd["Bar"].Visible := osd["Pct"].Visible := hasLevel
    osd["Msg"].Visible := !hasLevel
    if hasLevel {
        osd["Bar"].Value := level
        osd["Pct"].Value := level "%"
    } else
        osd["Msg"].Value := label
    MonitorGetWorkArea(MonitorGetPrimary(), &left, , &right, &bottom)
    w := 290, h := 48
    osd.Show("NoActivate x" ((left + right - w) // 2) " y" (bottom - h - 48) " w" w " h" h)
    SetTimer HideLevel, -1500
}
HideLevel() {
    global LevelOsd
    LevelOsd.Hide()
}

; ===== Screenshots =====
; Uses the Windows snip tool (Win+Shift+S), then:
;   "copy" -> image stays on the clipboard only (removes any file Windows saved)
;   "save" -> also saved as a PNG in Pictures\Screenshots
Screenshot(mode) {
    global ShotMode := mode, ShotStart := A_Now
    ShotCancel()  ; in case an earlier snip was never finished
    Send "#+s"
    OnClipboardChange ShotTaken
    SetTimer ShotCancel, -60000  ; give up if nothing is snipped within a minute
}

ShotTaken(type) {
    if type != 2  ; 2 = image
        return
    ShotCancel()
    SetTimer ShotFinish, -1500  ; give Windows a moment to save its own copy first
}

ShotCancel() {
    OnClipboardChange ShotTaken, 0
    SetTimer ShotCancel, 0
}

ShotFinish() {
    global ShotMode, ShotStart
    folder := ScreenshotFolder()
    saved := ""
    loop files folder "\*.png"
        if A_LoopFileTimeCreated >= ShotStart {
            if ShotMode = "copy"
                try FileDelete A_LoopFileFullPath
            else
                saved := A_LoopFileFullPath
        }
    if ShotMode = "copy"
        return ShowShot("Copied to clipboard")
    if saved = "" {
        DirCreate folder
        saved := folder "\Screenshot " FormatTime(, "yyyy-MM-dd HHmmss") ".png"
        if !SaveClipboardImage(saved)
            return ShowShot("Couldn't save the screenshot")
    }
    ShowShot("Saved to Pictures\Screenshots")
}

ShowShot(msg) {
    TrayTip msg, "Screenshot"
}

ScreenshotFolder() {
    try pics := RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders", "My Pictures")
    catch
        pics := EnvGet("USERPROFILE") "\Pictures"
    return pics "\Screenshots"
}

SaveClipboardImage(path) {
    ok := false
    if !DllCall("OpenClipboard", "Ptr", A_ScriptHwnd)
        return false
    if hBmp := DllCall("GetClipboardData", "UInt", 2, "Ptr") {  ; CF_BITMAP
        DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
        si := Buffer(24, 0), NumPut("UInt", 1, si)
        token := 0, pBmp := 0
        DllCall("gdiplus\GdiplusStartup", "Ptr*", &token, "Ptr", si, "Ptr", 0)
        DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", hBmp, "Ptr", 0, "Ptr*", &pBmp)
        png := Buffer(16)
        DllCall("ole32\CLSIDFromString", "Str", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "Ptr", png)
        if pBmp {
            ok := DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pBmp, "Str", path, "Ptr", png, "Ptr", 0) = 0
            DllCall("gdiplus\GdipDisposeImage", "Ptr", pBmp)
        }
        DllCall("gdiplus\GdiplusShutdown", "Ptr", token)
    }
    DllCall("CloseClipboard")
    return ok
}
