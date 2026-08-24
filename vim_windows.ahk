#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(true)
InstallKeybdHook()

; =============================================================================
;  VimWindows - System-wide Vimium & Mouse Control Architecture
;  Orchestrator: AutoHotkey v2 | Mouse Backend: Mousemaster
;  Ctrl+Win or Home = NORMAL MODE | i / Esc = INSERT MODE
; =============================================================================

global VimMode         := false
global gLastPress      := 0
global yLastPress      := 0
global AutoScrollState := 0     ; 0 = متوقف, 1 = لأسفل, -1 = لأعلى
global ScrollSpeed     := 5     ; السرعة من 1 إلى 10 (الافتراضي 5)
global ScrollAccum     := 0.0   ; مجمع الإزاحة الكسرية للسرعات البطيئة جداً
global IsDragging      := false

; محرك تحريك الماوس المتسارع الاحتياطي (Native Fallback Mouse Engine)
global MoveX           := 0
global MoveY           := 0
global CurrentMouseSpeed := 4.0
global BaseMouseSpeed    := 4.0
global MaxMouseSpeed     := 38.0
global MouseAccelFactor  := 1.08
global MouseMoving       := false

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

; =============================================================================
;  إدارة وتشغيل محرك الماوس المساعد (Mousemaster Backend)
; =============================================================================

EnsureMousemasterRunning() {
    mmExe := A_ScriptDir . "\mousemaster\mousemaster.exe"
    mmDir := A_ScriptDir . "\mousemaster"
    if FileExist(mmExe) {
        if (!ProcessExist("mousemaster.exe")) {
            try Run('"' . mmExe . '"', mmDir, "Hide")
        }
    }
}

EnsureMousemasterRunning()

ActivateMousemaster() {
    StopAutoScroll()
    ClearHints()
    ClearGrid()
    EnsureMousemasterRunning()
    ; إرسال نبضة F13 لتبديل وضع Mousemaster إلى وضع الماوس
    DllCall("keybd_event", "UChar", 0x7C, "UChar", 0, "UInt", 0, "UPtr", 0)
    DllCall("keybd_event", "UChar", 0x7C, "UChar", 0, "UInt", 2, "UPtr", 0)
    ToolTip("🖱️ MOUSE MODE | [Esc / q] رجوع | [Space] نقر | [h/j/k/l] تحريك | [d] سحب | [g] شبكة", 15, 10)
}

ToggleVimMode() {
    global VimMode, IsDragging
    VimMode := !VimMode
    if (!VimMode) {
        StopAutoScroll()
        ClearHints()
        ClearGrid()
        if (IsDragging) {
            IsDragging := false
            Click("Up")
        }
    }
    ShowMode()
}

^LWin::
^RWin::
Home:: ToggleVimMode()

; مؤشر الحالة الدائم في أعلى الشاشة طالما NORMAL MODE نشط
ShowMode() {
    global VimMode, AutoScrollState, ScrollSpeed
    if (VimMode) {
        ToolTip("🟢 NORMAL MODE | [Home/Esc] خروج | [m] ماوس | [f] تلميحات | [g] شبكة | [PgDn/v] سكرول", 15, 10)
    } else {
        ToolTip("⚫ INSERT MODE", 15, 10)
        SetTimer(() => ToolTip(), -1200)
    }
}

exitVim() {
    global VimMode, IsDragging
    StopAutoScroll()
    ClearHints()
    ClearGrid()
    if (IsDragging) {
        IsDragging := false
        Click("Up")
    }
    VimMode := false
    ShowMode()
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
        ToolTip("⚡ سرعة التمرير: [" . bar . "] " . ScrollSpeed . "/10`n[+ / =] تسريع  [- / Numpad-] تبطيء", 15, 10)
        SetTimer(() => ShowMode(), -1500)
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
    
    ToolTip("🟢 " . dirText . "`n⚡ السرعة: [" . bar . "] " . ScrollSpeed . "/10`n[+ / =] تسريع  [-] تبطيء  [Space/Esc] إيقاف", 15, 10)
}

; =============================================================================
;  محرك الماوس الاحتياطي المباشر (Fallback Direct Mouse)
; =============================================================================

StartMouseMove(dx, dy) {
    global MoveX, MoveY, CurrentMouseSpeed, BaseMouseSpeed, MouseMoving
    if (dx != 0) MoveX := dx
    if (dy != 0) MoveY := dy
    
    if (!MouseMoving) {
        MouseMoving := true
        CurrentMouseSpeed := BaseMouseSpeed
        SetTimer(DoMouseMove, 16)
    }
}

StopMouseMove(dx, dy) {
    global MoveX, MoveY, MouseMoving
    if (dx != 0 && MoveX == dx) MoveX := 0
    if (dy != 0 && MoveY == dy) MoveY := 0
    
    if (MoveX == 0 && MoveY == 0) {
        MouseMoving := false
        SetTimer(DoMouseMove, 0)
    }
}

DoMouseMove() {
    global MoveX, MoveY, CurrentMouseSpeed, MaxMouseSpeed, MouseAccelFactor, MouseMoving, VimMode
    if (!VimMode || (MoveX == 0 && MoveY == 0)) {
        MouseMoving := false
        SetTimer(DoMouseMove, 0)
        return
    }
    
    stepX := Integer(MoveX * CurrentMouseSpeed)
    stepY := Integer(MoveY * CurrentMouseSpeed)
    DllCall("mouse_event", "UInt", 0x0001, "Int", stepX, "Int", stepY, "UInt", 0, "UPtr", 0)
    
    if (CurrentMouseSpeed < MaxMouseSpeed)
        CurrentMouseSpeed := Min(MaxMouseSpeed, CurrentMouseSpeed * MouseAccelFactor)
}

ToggleMouseDrag() {
    global IsDragging
    IsDragging := !IsDragging
    if (IsDragging) {
        Click("Down")
        ToolTip("✊ جاري السحب (DRAG MODE) - اضغط v للإفلات", 15, 35)
    } else {
        Click("Up")
        ToolTip()
        ShowMode()
    }
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
    global GridGuis, GridActive, VimMode
    if (!VimMode)
        return
    
    StopAutoScroll()
    ClearHints()
    ClearGrid()
    
    CoordMode("Mouse", "Screen")
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
    
    ToolTip("🔢 اضغط رقماً من [1 إلى 9] للقفز الفوري للمنطقة | [Esc] إلغاء", 15, 10)
    
    ih := InputHook("L1 T4", "{Escape}{Space}")
    ih.OnChar := (hook, char) => (
        ProcessGridChoice(char, hook, gridCenters)
    )
    ih.OnEnd := (hook) => (ClearGrid(), ShowMode())
    ih.Start()
}

ProcessGridChoice(char, hook, gridCenters) {
    if (char >= "1" && char <= "9") {
        choice := Integer(char)
        if (gridCenters.Has(choice)) {
            pt := gridCenters[choice]
            CoordMode("Mouse", "Screen")
            MouseMove(pt.x, pt.y, 0)
        }
    }
    hook.Stop()
    ClearGrid()
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
    global HintGuis, HintMap, VimMode
    if (!VimMode)
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
        ToolTip("⚠️ لم يتم العثور على عناصر تفاعلية في النافذة", 15, 10)
        SetTimer(() => ShowMode(), -1500)
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
    ih.OnEnd := (hook) => (ClearHints(), ShowMode())
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
#HotIf VimMode and !IsExcludedApp()

; ----- إيقاف NORMAL MODE (فقط i و Esc) -----
Escape:: {
    global AutoScrollState, GridActive
    if (AutoScrollState != 0)
        StopAutoScroll()
    else if (GridActive)
        ClearGrid()
    else {
        ClearHints()
        exitVim()
    }
}

i:: {
    StopAutoScroll()
    ClearHints()
    ClearGrid()
    exitVim()
}

; ----- محرك الماوس المتقدم (Mousemaster Backend) -----
m:: ActivateMousemaster()               ; m = تفعيل وضع الماوس المتطور (Mousemaster)

; ----- تحريك الماوس بالأسهم (Direct Arrow Movement) -----
Up::    StartMouseMove(0, -1)
Down::  StartMouseMove(0, 1)
Left::  StartMouseMove(-1, 0)
Right:: StartMouseMove(1, 0)

Up Up::    StopMouseMove(0, -1)
Down Up::  StopMouseMove(0, 1)
Left Up::  StopMouseMove(-1, 0)
Right Up:: StopMouseMove(1, 0)

; ----- النقر وسحب الماوس المباشر -----
Enter::  Click()                       ; Enter = نقر أيسر
+Enter:: Click("Right")                ; Shift+Enter = نقر أيمن
^Enter:: Click("Middle")               ; Ctrl+Enter = نقر أوسط

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
    global AutoScrollState, IsDragging
    if (IsDragging)
        ToggleMouseDrag()
    else if (AutoScrollState != 0)
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
^,::   SendInput("{Media_Prev}")
^.::   SendInput("{Media_Next}")
^Up::  SendInput("{Volume_Up}")
^Down:: SendInput("{Volume_Down}")
!0::   SendInput("{Volume_Mute}")

; ----- مساعدة -----
+/:: {
    help := "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
          . "🟢 VimWindows - الاختصارات الموحدة`n"
          . "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
          . "Ctrl+Win أو Home → تفعيل/إيقاف NORMAL MODE`n"
          . "i / Esc  → INSERT MODE`n`n"
          . "🖱️ محرك الماوس المتقدم (Mouse Backend):`n"
          . "  m       → تفعيل وضع الماوس المستمر (Mousemaster)`n"
          . "            (تحريك بـ HJKL/الأسهم، نقر بـ Space، سحب بـ d)`n"
          . "  الأسهم  → تحريك الماوس المباشر`n"
          . "  Enter   → نقر أيسر (Left Click)`n`n"
          . "🔢 شبكة القفز السريع (Grid Jump):`n"
          . "  g       → إظهار شبكة 3x3 والقفز بالأرقام (1-9)`n"
          . "  gg      → انتقال لبداية الصفحة (Top)`n`n"
          . "🎯 وضع التلميحات (Hint Mode):`n"
          . "  f       → إظهار تلميحات العناصر والنقر عليها`n"
          . "  F       → النقر بزر الماوس الأيمن على العنصر`n`n"
          . "📜 التمرير التلقائي (Auto-Scroll):`n"
          . "  PgDn / Space     → تمرير تلقائي لأسفل ⏬`n"
          . "  PgUp             → تمرير تلقائي لأعلى ⏫`n"
          . "  + / - أو ] / [   → تسريع / تبطيء التمرير`n`n"
          . "📜 التمرير اليدوي (Vimium):`n"
          . "  j/k / d/u / G    → أسفل/أعلى/نصف صفحة/نهاية`n"
          . "  h/l              → يسار/يمين`n`n"
          . "📑 التبويبات والبحث:`n"
          . "  t/x/X / J/K      → تبويب جديد/إغلاق/استعادة/تبديل`n"
          . "  s / S            → بحث ويندوز / بحث التطبيق`n"
          . "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    MsgBox(help, "VimWindows", 0)
}

#HotIf
