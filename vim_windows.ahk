#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(true)
InstallKeybdHook()

; =============================================================================
;  VimWindows - Vimium for Windows
;  Ctrl+Win or Home = NORMAL MODE | i / Esc = INSERT MODE
; =============================================================================

global VimMode         := false
global gLastPress      := 0
global yLastPress      := 0
global AutoScrollState := 0     ; 0 = متوقف, 1 = لأسفل, -1 = لأعلى
global ScrollSpeed     := 5     ; السرعة من 1 إلى 10 (الافتراضي 5)
global ScrollAccum     := 0.0   ; مجمع الإزاحة الكسرية للسرعات البطيئة جداً

; قائمة المتصفحات المستثناة تلقائياً (حيث تعمل إضافة Vimium الأصلية)
global ExcludedBrowsers := [
    "chrome.exe",
    "msedge.exe",
    "brave.exe",
    "firefox.exe",
    "zen.exe",
    "opera.exe",
    "vivaldi.exe",
    "arc.exe"
]

IsExcludedApp() {
    global ExcludedBrowsers
    try {
        activeProc := WinGetProcessName("A")
        for app in ExcludedBrowsers {
            if (StrLower(activeProc) = StrLower(app))
                return true
        }
    }
    return false
}

ToggleVimMode() {
    global VimMode
    VimMode := !VimMode
    if (!VimMode) {
        StopAutoScroll()
        ClearHints()
    }
    ShowMode()
}

^LWin::
^RWin::
Home:: ToggleVimMode()

ShowMode() {
    global VimMode
    if VimMode
        ToolTip("🟢 NORMAL MODE", 10, 10)
    else
        ToolTip("⚫ INSERT MODE", 10, 10)
    SetTimer(() => ToolTip(), -1500)
}

exitVim() {
    global VimMode
    StopAutoScroll()
    ClearHints()
    VimMode := false
    ShowMode()
}

; =============================================================================
;  دوال التمرير التلقائي الانسيابي (Target ~60 Hz Smooth Micro-Scrolling)
; =============================================================================

GetScrollDelta(spd) {
    spd := Max(1, Min(10, spd))
    ; قيم الإزاحة الميكروية في كل إطار بتردد مستهدف ~60 هرتز
    ; السرعة 1: 0.125 ديلتا (انزلاق فائق البطء والتأني بالملليمتر)
    ; السرعة 5: 1.000 ديلتا (السرعة الافتراضية المتزنة)
    ; السرعة 10: 5.250 ديلتا
    deltas := [0.125, 0.25, 0.375, 0.625, 1.0, 1.375, 2.0, 2.75, 3.875, 5.25]
    return deltas[spd]
}

DoAutoScroll() {
    global AutoScrollState, VimMode, ScrollSpeed, ScrollAccum
    if (!VimMode || AutoScrollState == 0) {
        StopAutoScroll()
        return
    }
    
    stepDelta := GetScrollDelta(ScrollSpeed)
    ScrollAccum += stepDelta
    
    sendDelta := Integer(ScrollAccum)
    if (sendDelta >= 1) {
        ScrollAccum -= sendDelta
        ; MOUSEEVENTF_WHEEL = 0x0800
        wheelDelta := (AutoScrollState == 1) ? -sendDelta : sendDelta
        DllCall("mouse_event", "UInt", 0x0800, "UInt", 0, "UInt", 0, "Int", wheelDelta, "UPtr", 0)
    }
}

StartAutoScroll(dir) {
    global AutoScrollState, ScrollAccum
    if (AutoScrollState == dir) {
        StopAutoScroll()
        return
    }
    
    AutoScrollState := dir
    ScrollAccum := 0.0
    ; تفعيل المؤقت بتردد مستهدف ~60 هرتز (كل 16 مللي ثانية) لانسيابية الحركة
    SetTimer(DoAutoScroll, 0)
    SetTimer(DoAutoScroll, 16)
    ShowScrollStatus()
}

StopAutoScroll() {
    global AutoScrollState, ScrollAccum
    if (AutoScrollState != 0) {
        AutoScrollState := 0
        ScrollAccum := 0.0
        SetTimer(DoAutoScroll, 0)
        ToolTip()
    }
}

ChangeScrollSpeed(delta) {
    global ScrollSpeed, AutoScrollState
    ScrollSpeed := Max(1, Min(10, ScrollSpeed + delta))
    if (AutoScrollState != 0) {
        ShowScrollStatus()
    } else {
        bar := ""
        Loop 10 {
            if (A_Index <= ScrollSpeed)
                bar .= "█"
            else
                bar .= "░"
        }
        ToolTip("⚡ سرعة التمرير: [" . bar . "] " . ScrollSpeed . "/10`n[+ / =] تسريع  [- / Numpad-] تبطيء", 10, 10)
        SetTimer(() => ToolTip(), -1200)
    }
}

ShowScrollStatus() {
    global AutoScrollState, ScrollSpeed
    if (AutoScrollState == 1)
        dirText := "⏬ تمرير تلقائي لأسفل"
    else if (AutoScrollState == -1)
        dirText := "⏫ تمرير تلقائي لأعلى"
    else
        return
    
    bar := ""
    Loop 10 {
        if (A_Index <= ScrollSpeed)
            bar .= "█"
        else
            bar .= "░"
    }
    
    ToolTip("🟢 " . dirText . "`n⚡ السرعة: [" . bar . "] " . ScrollSpeed . "/10`n[+ / =] تسريع  [- / Numpad-] تبطيء  [Space / Esc] إيقاف", 10, 10)
}

; =============================================================================
;  محرك وضع التلميحات التفاعلي (Vimium Native Hint Mode Engine)
; =============================================================================

global HintGuis := []
global HintMap  := Map()

GenerateHintKeys(count) {
    chars := ["a", "s", "d", "f", "g", "h", "j", "k", "l", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "z", "x", "c", "v", "b", "n", "m"]
    keys := []
    
    if (count <= chars.Length) {
        Loop count
            keys.Push(chars[A_Index])
        return keys
    }
    
    for c1 in chars {
        for c2 in chars {
            keys.Push(c1 . c2)
            if (keys.Length >= count)
                return keys
        }
    }
    return keys
}

ClearHints() {
    global HintGuis, HintMap
    for g in HintGuis {
        try g.Destroy()
    }
    HintGuis := []
    HintMap.Clear()
}

StartHintMode(clickType := "Left") {
    global HintGuis, HintMap, VimMode
    if (!VimMode)
        return
    
    StopAutoScroll()
    ClearHints()
    
    activeHwnd := WinExist("A")
    if (!activeHwnd)
        return
    
    WinGetPos(&winX, &winY, &winW, &winH, activeHwnd)
    ctrlHwnds := WinGetControlsHwnd(activeHwnd)
    
    elements := []
    for h in ctrlHwnds {
        try {
            if (!DllCall("IsWindowVisible", "Ptr", h))
                continue
            ControlGetPos(&cX, &cY, &cW, &cH, h, activeHwnd)
            if (cW < 8 || cH < 8 || cX < 0 || cY < 0 || cX > winW || cY > winH)
                continue
            
            screenX := winX + cX
            screenY := winY + cY
            
            elements.Push({
                hwnd: h,
                x: screenX,
                y: screenY,
                w: cW,
                h: cH,
                centerX: screenX + (cW // 2),
                centerY: screenY + (cH // 2)
            })
        }
    }
    
    if (elements.Length == 0) {
        ToolTip("⚠️ لم يتم العثور على عناصر تفاعلية في النافذة", 10, 10)
        SetTimer(() => ToolTip(), -1500)
        return
    }
    
    if (elements.Length > 80)
        elements.Length := 80
        
    hintKeys := GenerateHintKeys(elements.Length)
    
    Loop elements.Length {
        el := elements[A_Index]
        key := hintKeys[A_Index]
        HintMap[key] := el
        
        hintGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border +E0x20", "VimHint")
        hintGui.BackColor := "FFEB3B"  ; أصفر تلميحات Vimium
        hintGui.SetFont("s9 bold cBlack", "Consolas")
        hintGui.MarginX := 3
        hintGui.MarginY := 1
        hintGui.Add("Text", "Center", StrUpper(key))
        
        showX := Max(0, el.x)
        showY := Max(0, el.y)
        hintGui.Show("x" . showX . " y" . showY . " NoActivate AutoSize")
        HintGuis.Push(hintGui)
    }
    
    ih := InputHook("T5", "{Escape}{Space}")
    ih.VisibleNonText := false
    
    typed := ""
    ih.OnChar := (hook, char) => (
        typed .= StrLower(char),
        CheckHintMatch(typed, hook, clickType)
    )
    ih.OnEnd := (hook) => ClearHints()
    ih.Start()
}

CheckHintMatch(typed, hook, clickType) {
    global HintMap
    if (HintMap.Has(typed)) {
        el := HintMap[typed]
        hook.Stop()
        ClearHints()
        
        CoordMode("Mouse", "Screen")
        if (clickType == "Right")
            Click(el.centerX, el.centerY, "Right")
        else
            Click(el.centerX, el.centerY, "Left")
    } else {
        hasPrefix := false
        for k in HintMap {
            if (SubStr(k, 1, StrLen(typed)) == typed) {
                hasPrefix := true
                break
            }
        }
        if (!hasPrefix) {
            hook.Stop()
            ClearHints()
        }
    }
}

; =============================================================================
#HotIf VimMode and !IsExcludedApp()

; ----- إيقاف NORMAL MODE (فقط i و Esc) -----
Escape:: {
    global AutoScrollState
    if (AutoScrollState != 0)
        StopAutoScroll()
    else {
        ClearHints()
        exitVim()
    }
}

i:: {
    StopAutoScroll()
    ClearHints()
    exitVim()
}

; ----- التمرير التلقائي (Auto-Scroll) -----
v:: StartAutoScroll(1)                 ; v = تمرير تلقائي لأسفل
+v:: StartAutoScroll(-1)               ; V = تمرير تلقائي لأعلى
^j:: StartAutoScroll(1)                ; Ctrl+j = تمرير تلقائي لأسفل
^k:: StartAutoScroll(-1)               ; Ctrl+k = تمرير تلقائي لأعلى
PgDn:: StartAutoScroll(1)              ; PageDown = تمرير تلقائي لأسفل
PgUp:: StartAutoScroll(-1)             ; PageUp = تمرير تلقائي لأعلى

Space:: {
    global AutoScrollState
    if (AutoScrollState != 0)
        StopAutoScroll()
    else
        StartAutoScroll(1)             ; Space = تشغيل / إيقاف التمرير لأسفل
}

; ----- التمرير اليدوي (مثل Vimium) -----
j:: {
    StopAutoScroll()
    SendInput("{WheelDown 2}")         ; j = تمرير للأسفل
}
k:: {
    StopAutoScroll()
    SendInput("{WheelUp 2}")           ; k = تمرير للأعلى
}
h:: {
    StopAutoScroll()
    SendInput("{WheelLeft 2}")         ; h = تمرير لليسار
}
l:: {
    StopAutoScroll()
    SendInput("{WheelRight 2}")        ; l = تمرير لليمين
}

d:: {
    StopAutoScroll()
    SendInput("{WheelDown 8}")         ; d = نصف صفحة أسفل
}
u:: {
    StopAutoScroll()
    SendInput("{WheelUp 8}")           ; u = نصف صفحة أعلى
}

g:: {
    StopAutoScroll()
    global gLastPress
    now := A_TickCount
    if (now - gLastPress < 500)
        SendInput("^{Home}")           ; gg = أعلى الصفحة
    gLastPress := now
}
+g:: {
    StopAutoScroll()
    SendInput("^{End}")                ; G = أسفل الصفحة
}

; ----- وضع التلميحات التفاعلي (Hint Mode) -----
f:: StartHintMode("Left")              ; f = إظهار تلميحات العناصر والنقر عليها
+f:: StartHintMode("Right")            ; F = إظهار التلميحات والنقر بزر الماوس الأيمن

; ----- التنقل بين أقسام التطبيق والتحكم بالسرعة -----
]::{
    global AutoScrollState
    if (AutoScrollState != 0)
        ChangeScrollSpeed(1)
    else
        SendInput("{F6}")              ; ] = القسم التالي
}
[::{
    global AutoScrollState
    if (AutoScrollState != 0)
        ChangeScrollSpeed(-1)
    else
        SendInput("+{F6}")             ; [ = القسم السابق
}
.::{
    global AutoScrollState
    if (AutoScrollState != 0)
        ChangeScrollSpeed(1)
    else
        SendInput("{F6}")              ; . = القسم التالي
}
,::{
    global AutoScrollState
    if (AutoScrollState != 0)
        ChangeScrollSpeed(-1)
    else
        SendInput("+{F6}")             ; , = القسم السابق
}

; ----- تاريخ التصفح (Vimium: H L) -----
+h:: SendInput("!{Left}")              ; H = رجوع في التاريخ
+l:: SendInput("!{Right}")             ; L = تقدم في التاريخ

; ----- التبويبات (Vimium: t x X J K W) -----
t::  SendInput("^t")                   ; t = تبويب جديد
x::  SendInput("^w")                   ; x = إغلاق تبويب
+x:: SendInput("^+t")                  ; X = استعادة تبويب
+j:: SendInput("^+{Tab}")              ; J = تبويب سابق
+k:: SendInput("^{Tab}")               ; K = تبويب تالي
+w:: SendInput("^n")                   ; W = نافذة جديدة

; ----- التحديث والبحث في النظام والتطبيقات -----
r::  SendInput("{F5}")                 ; r = Reload
/:: {
    exitVim()
    SendInput("^f")                    ; / = بحث في التطبيق
}
s::  SendInput("#s")                   ; s = بحث ويندوز الشامل (Windows Search)
+s:: SendInput("^f")                   ; S = بحث داخل التطبيق (In-App Search)
n::  SendInput("{F3}")                 ; n = نتيجة تالية
+n:: SendInput("+{F3}")                ; N = نتيجة سابقة

; ----- نسخ ولصق -----
y:: {
    global yLastPress
    now := A_TickCount
    if (now - yLastPress < 500)
        SendInput("^c")                ; yy = نسخ
    yLastPress := now
}
p::  SendInput("^v")                   ; p = لصق

; ----- Vomnibar (شريط العنوان والروابط) -----
o:: {
    exitVim()
    SendInput("^l")
}

; ----- التحكم بسرعة التمرير (+ / = / Numpad+ / - / Numpad-) -----
=::
+=::
NumpadAdd:: ChangeScrollSpeed(1)       ; + أو = أو Numpad+ = تسريع السكرول

-::
+-::
NumpadSub:: ChangeScrollSpeed(-1)      ; - أو Numpad- = تبطيء السكرول

^0:: SendInput("^0")                   ; Ctrl+0 = إعادة الضبط

; ----- الصوت والميديا -----
^m::   SendInput("{Media_Play_Pause}")
^,::   SendInput("{Media_Prev}")
^.::   SendInput("{Media_Next}")
^Up::  SendInput("{Volume_Up}")
^Down:: SendInput("{Volume_Down}")
!0::   SendInput("{Volume_Mute}")

; ----- مساعدة -----
+/:: {
    help := "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
          . "🟢 VimWindows - الاختصارات`n"
          . "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
          . "Ctrl+Win أو Home → تفعيل/إيقاف NORMAL MODE`n"
          . "i / Esc  → INSERT MODE`n`n"
          . "🎯 وضع التلميحات (Hint Mode):`n"
          . "  f       → إظهار تلميحات العناصر والنقر عليها`n"
          . "  F       → النقر بزر الماوس الأيمن على العنصر`n`n"
          . "📜 التمرير التلقائي (Auto-Scroll):`n"
          . "  v / PgDn / Space → تمرير تلقائي لأسفل ⏬`n"
          . "  V / PgUp         → تمرير تلقائي لأعلى ⏫`n"
          . "  + / - أو ] / [     → تسريع / تبطيء التمرير`n"
          . "  Space / Esc / أي زر→ إيقاف التمرير التلقائي`n`n"
          . "📜 التمرير اليدوي (Vimium):`n"
          . "  j/k     → أسفل/أعلى`n"
          . "  h/l     → يسار/يمين`n"
          . "  d/u     → نصف صفحة أسفل/أعلى`n"
          . "  gg/G    → أعلى/أسفل الصفحة`n`n"
          . "↔️ التنقل بين أقسام التطبيق:`n"
          . "  ] أو .  → القسم التالي (F6)`n"
          . "  [ أو ,  → القسم السابق (Shift+F6)`n`n"
          . "📑 التبويبات والتاريخ:`n"
          . "  t/x/X   → تبويب جديد/إغلاق/استعادة`n"
          . "  J/K     → التبويب السابق/التالي`n"
          . "  H/L     → التاريخ السابق/التالي`n"
          . "  r       → تحديث الصفحة`n`n"
          . "🔍 البحث:`n"
          . "  s       → بحث ويندوز الشامل (Win+S)`n"
          . "  S أو /  → بحث داخل التطبيق (Ctrl+F)`n`n"
          . "🎵 الصوت والميديا:`n"
          . "  Ctrl+↑↓ → رفع/خفض الصوت`n"
          . "  Alt+0   → كتم الصوت`n"
          . "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    MsgBox(help, "VimWindows", 0)
}

#HotIf
