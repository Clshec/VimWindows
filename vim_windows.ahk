#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(true)
InstallKeybdHook()
CoordMode("Mouse", "Screen")

; =============================================================================
;  VimWindows - Universal Orchestrator & Mousemaster Backend Integration
;  Home Key: INSERT MODE (0) -> NORMAL MODE (1) -> MOUSE MODE (2) -> INSERT MODE
; =============================================================================

; 0 = INSERT MODE, 1 = NORMAL MODE, 2 = MOUSE MODE
global CurrentModeState := 0
global VimMode          := false
global InMouseMode      := false

global gLastPress       := 0
global yLastPress       := 0
global AutoScrollState  := 0     ; 0 = متوقف, 1 = لأسفل, -1 = لأعلى
global ScrollSpeed      := 5     ; السرعة من 1 إلى 10 (الافتراضي 5)
global ScrollAccum      := 0.0   ; مجمع الإزاحة الكسرية

; كائن واجهة شارة الوضع المربعة الكبيرة أعلى الشاشة
global ModeGui          := ""

; =============================================================================
;  شارة الوضع المربعة الكبيرة أعلى الشاشة (Top Large Square Badge)
; =============================================================================

ShowMode() {
    global CurrentModeState, ModeGui
    try {
        if (ModeGui) {
            ModeGui.Destroy()
            ModeGui := ""
        }
        
        if (CurrentModeState == 1) {
            ; 🟢 NORMAL MODE
            ModeGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "VimModeBadge")
            ModeGui.BackColor := "1B5E20"  ; أخضر داكن فخم
            ModeGui.SetFont("s16 bold cWhite", "Segoe UI")
            ModeGui.MarginX := 36
            ModeGui.MarginY := 12
            ModeGui.Add("Text", "Center +BackgroundTrans", "🟢 NORMAL MODE")
            ModeGui.Show("xCenter y12 NoActivate AutoSize")
        } else if (CurrentModeState == 2) {
            ; 🔵 MOUSE MODE
            ModeGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "VimModeBadge")
            ModeGui.BackColor := "0D47A1"  ; أزرق ملكي أنيق
            ModeGui.SetFont("s16 bold cWhite", "Segoe UI")
            ModeGui.MarginX := 36
            ModeGui.MarginY := 12
            ModeGui.Add("Text", "Center +BackgroundTrans", "🔵 MOUSE MODE")
            ModeGui.Show("xCenter y12 NoActivate AutoSize")
        } else {
            ; ⚫ INSERT MODE
            ToolTip("⚫ INSERT MODE", 15, 10)
            SetTimer(() => ToolTip(), -1000)
        }
    } catch {
        if (CurrentModeState == 1)
            ToolTip("🟢 NORMAL MODE", 15, 10)
        else if (CurrentModeState == 2)
            ToolTip("🔵 MOUSE MODE", 15, 10)
        else
            ToolTip("⚫ INSERT MODE", 15, 10)
        SetTimer(() => ToolTip(), -1200)
    }
}

; =============================================================================
;  إدارة دورة الأوضاع عبر زر Home (Home Key Mode Cycler)
; =============================================================================

SetModeState(state) {
    global CurrentModeState, VimMode, InMouseMode
    oldState := CurrentModeState
    CurrentModeState := state
    
    ; إذا كنا نخرج من MOUSE MODE، نقوم بإيقاف محرك Mousemaster
    if (oldState == 2 && state != 2) {
        SendInput("{F13}")
    }
    
    if (state == 0) {
        ; INSERT MODE (وضع الكتابة الطبيعي في ويندوز)
        VimMode := false
        InMouseMode := false
        StopAutoScroll()
        ClearHints()
        ClearGrid()
        ShowMode()
    } else if (state == 1) {
        ; NORMAL MODE (وضع ملاحة Vimium والتمرير والتلميحات)
        VimMode := true
        InMouseMode := false
        StopAutoScroll()
        ClearHints()
        ClearGrid()
        ShowMode()
    } else if (state == 2) {
        ; MOUSE MODE (تفعيل محرك Mousemaster فائق النعومة والسرعة)
        VimMode := true
        InMouseMode := true
        StopAutoScroll()
        ClearHints()
        ClearGrid()
        ShowMode()
        ; إرسال إشارة F13 لتفعيل وضع الماوس داخل Mousemaster
        SendInput("{F13}")
    }
}

CycleMode() {
    global CurrentModeState
    nextState := Mod(CurrentModeState + 1, 3)
    SetModeState(nextState)
}

; مفاتيح التبديل الدوري (Home أو NumpadHome أو Ctrl+Win)
Home::
NumpadHome::
^LWin::
^RWin:: CycleMode()

exitVim() {
    SetModeState(0)
}

; =============================================================================
;  دوال التمرير التلقائي الانسيابي (Target ~60 Hz Smooth Micro-Scrolling)
; =============================================================================

GetScrollDelta(spd) {
    spd := Max(1, Min(10, spd))
    deltas := [0.125, 0.25, 0.375, 0.625, 1.0, 1.375, 2.0, 2.75, 3.875, 5.25]
    return deltas[spd]
}

DoAutoScroll() {
    global AutoScrollState, CurrentModeState, ScrollSpeed, ScrollAccum
    if (CurrentModeState != 1 || AutoScrollState == 0) {
        StopAutoScroll()
        return
    }
    
    stepDelta := GetScrollDelta(ScrollSpeed)
    ScrollAccum += stepDelta
    
    sendDelta := Integer(ScrollAccum)
    if (sendDelta >= 1) {
        ScrollAccum -= sendDelta
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
        ShowMode()
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
        ToolTip("⚡ سرعة التمرير: [" . bar . "] " . ScrollSpeed . "/10`n[+ / =] تسريع  [-] تبطيء", 15, 60)
        SetTimer(() => ToolTip(), -1500)
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
    
    ToolTip("🟢 " . dirText . "`n⚡ السرعة: [" . bar . "] " . ScrollSpeed . "/10`n[+ / =] تسريع  [-] تبطيء  [Space/Esc] إيقاف", 15, 60)
}

; =============================================================================
;  محرك شبكة القفز السريع 3x3 (Grid Jump Engine)
; =============================================================================

global GridGuis := []
global GridActive := false

ClearGrid() {
    global GridGuis, GridActive
    for g in GridGuis {
        try g.Destroy()
    }
    GridGuis := []
    GridActive := false
}

StartGridMode() {
    global GridGuis, GridActive, CurrentModeState
    if (CurrentModeState == 0)
        return
    
    StopAutoScroll()
    ClearHints()
    ClearGrid()
    
    activeHwnd := WinExist("A")
    if (!activeHwnd)
        activeHwnd := WinGetID("Program Manager")
    
    WinGetPos(&wX, &wY, &wW, &wH, activeHwnd)
    if (wW < 100 || wH < 100) {
        wX := 0, wY := 0, wW := A_ScreenWidth, wH := A_ScreenHeight
    }
    
    GridActive := true
    colW := wW // 3
    rowH := wH // 3
    
    gridCenters := Map()
    num := 1
    Loop 3 {
        r := A_Index - 1
        Loop 3 {
            c := A_Index - 1
            cX := wX + (c * colW) + (colW // 2)
            cY := wY + (r * rowH) + (rowH // 2)
            gridCenters[num] := {x: cX, y: cY}
            
            gBox := Gui("+AlwaysOnTop -Caption +ToolWindow +Border +E0x20", "VimGrid")
            gBox.BackColor := "1E88E5"
            gBox.SetFont("s14 bold cWhite", "Arial")
            gBox.Add("Text", "Center w30 h30", num)
            
            showX := cX - 15
            showY := cY - 15
            gBox.Show("x" . showX . " y" . showY . " NoActivate AutoSize")
            GridGuis.Push(gBox)
            num++
        }
    }
    
    ToolTip("🔢 اضغط رقماً من [1 إلى 9] للقفز الفوري للمنطقة | [Esc] إلغاء", 15, 60)
    
    ih := InputHook("L1 T4", "{Escape}{Space}")
    ih.OnChar := (hook, char) => (
        ProcessGridChoice(char, hook, gridCenters)
    )
    ih.OnEnd := (hook) => (ClearGrid(), ToolTip(), ShowMode())
    ih.Start()
}

ProcessGridChoice(char, hook, gridCenters) {
    if (char >= "1" && char <= "9") {
        choice := Integer(char)
        if (gridCenters.Has(choice)) {
            pt := gridCenters[choice]
            MouseMove(pt.x, pt.y, 0)
        }
    }
    hook.Stop()
    ClearGrid()
    ToolTip()
    ShowMode()
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
    global HintGuis, HintMap, CurrentModeState
    if (CurrentModeState == 0)
        return
    
    StopAutoScroll()
    ClearGrid()
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
        ToolTip("⚠️ لم يتم العثور على عناصر تفاعلية في النافذة", 15, 60)
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
        hintGui.BackColor := "FFEB3B"
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
    ih.OnEnd := (hook) => (ClearHints(), ShowMode())
    ih.Start()
}

CheckHintMatch(typed, hook, clickType) {
    global HintMap
    if (HintMap.Has(typed)) {
        el := HintMap[typed]
        hook.Stop()
        ClearHints()
        
        if (clickType == "Right")
            Click(el.centerX, el.centerY, "Right")
        else
            Click(el.centerX, el.centerY, "Left")
        ShowMode()
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
            ShowMode()
        }
    }
}

; =============================================================================
;  الطبقة 1: وضع الماوس المتخصص (State 2: MOUSE MODE 🔵 - عبر Mousemaster Backend)
; =============================================================================
#HotIf CurrentModeState == 2

; زر Esc يخرج من وضع الماوس ويعود لوضع الكتابة
Escape:: SetModeState(0)

; =============================================================================
;  الطبقة 2: وضع الملاحة العام (State 1: NORMAL MODE 🟢) - شامل لكل البرامج
; =============================================================================
#HotIf CurrentModeState == 1

Escape:: {
    global AutoScrollState, GridActive
    if (AutoScrollState != 0)
        StopAutoScroll()
    else if (GridActive)
        ClearGrid()
    else {
        ClearHints()
        SetModeState(0)
    }
}

; ----- اختصارات Vimium الأصلية المحفوظة بالكامل (Navigation Keys) -----
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
    SendInput("{Left 2}")              ; h = تنقل لليسار
}
l:: {
    StopAutoScroll()
    SendInput("{Right 2}")             ; l = تنقل لليمين
}

d:: {
    StopAutoScroll()
    SendInput("{WheelDown 8}")         ; d = نصف صفحة أسفل
}
u:: {
    StopAutoScroll()
    SendInput("{WheelUp 8}")           ; u = نصف صفحة أعلى
}

; ----- شبكة القفز السريع وقمة الصفحة (Grid & Top Page) -----
g:: {
    global gLastPress
    now := A_TickCount
    if (now - gLastPress < 400) {
        ClearGrid()
        SendInput("^{Home}")           ; gg = أعلى الصفحة
    } else {
        StartGridMode()                ; g = فتح شبكة القفز 3x3
    }
    gLastPress := now
}
+g:: {
    StopAutoScroll()
    SendInput("^{End}")                ; G = أسفل الصفحة
}

; ----- التمرير التلقائي (Auto-Scroll) -----
PgDn:: StartAutoScroll(1)              ; PageDown = تمرير تلقائي لأسفل
PgUp:: StartAutoScroll(-1)             ; PageUp = تمرير تلقائي لأعلى
^j:: StartAutoScroll(1)                ; Ctrl+j = تمرير تلقائي لأسفل
^k:: StartAutoScroll(-1)               ; Ctrl+k = تمرير تلقائي لأعلى

Space:: {
    global AutoScrollState
    if (AutoScrollState != 0)
        StopAutoScroll()
    else
        StartAutoScroll(1)             ; Space = تشغيل / إيقاف التمرير لأسفل
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
    SetModeState(0)
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
+o:: {
    SetModeState(0)
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
^,::   SendInput("{Media_Prev}")
^.::   SendInput("{Media_Next}")
^Up::  SendInput("{Volume_Up}")
^Down:: SendInput("{Volume_Down}")
!0::   SendInput("{Volume_Mute}")

; ----- منع الأزرار غير المخصصة من الكتابة في Normal Mode -----
a::
b::
c::
e::
i::
m::
o::
q::
v::
w::
z::
1::
2::
3::
4::
5::
6::
7::
8::
9::
0::
Tab::
Backspace::
Delete::
;::
'::
\:: {
    return
}

; ----- مساعدة -----
+/:: {
    help := "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
          . "🟢 VimWindows - الاختصارات المتكاملة`n"
          . "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
          . "Home Key: التبديل الدوري بين 3 أوضاع:`n"
          . "  ضغطة 1 → 🟢 NORMAL MODE`n"
          . "  ضغطة 2 → 🔵 MOUSE MODE (ماوس فوري خارق)`n"
          . "  ضغطة 3 → ⚫ INSERT MODE (كتابة عادية)`n"
          . "Esc     → الخروج الفوري لوضع الكتابة`n`n"
          . "🖱️ تحكم الماوس في MOUSE MODE:`n"
          . "  HJKL / الأسهم / WASD / UIOP → تحريك فائق السرعة والانسيابية`n"
          . "  Space / Enter / m → نقر أيسر | Shift+Space / r نقر أيمن`n"
          . "  v              → وضع السحب والإفلات`n"
          . "  g              → شبكة القفز 3x3`n"
          . "  Shift (أثناء الحركة) → دقة بالبكسل`n"
          . "  Ctrl (أثناء الحركة)  → توربو فائق`n`n"
          . "📜 التمرير والملاحة في NORMAL MODE:`n"
          . "  j / k          → تمرير لأسفل / لأعلى`n"
          . "  h / l          → تنقل لليسار / لليمين`n"
          . "  d / u          → نصف صفحة لأسفل / لأعلى`n"
          . "  gg / G         → أعلى / أسفل الصفحة`n"
          . "  f / F          → تلميحات العناصر (Hint Mode)`n"
          . "  PgDn / Space   → تمرير تلقائي لأسفل`n`n"
          . "📑 التبويبات والبحث:`n"
          . "  t / x / X      → تبويب جديد / إغلاق / استعادة`n"
          . "  J / K          → التبويب السابق / التالي`n"
          . "  s / S          → بحث ويندوز / بحث التطبيق`n"
          . "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    MsgBox(help, "VimWindows", 0)
}

#HotIf
