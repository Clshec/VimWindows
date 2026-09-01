#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off
Persistent(true)
InstallKeybdHook()
CoordMode("Mouse", "Screen")
SetCapsLockState("AlwaysOff")

; =============================================================================
;  VimWindows - Symmetric Dual-Hand (WASD / PL;') Hyper Mouse & Navigation
;  Home / NumpadHome / Ctrl+Win = Toggle NORMAL MODE ↔ INSERT MODE
;  CapsLock = تبديل فوري للغة الإدخال (عربي ↔ إنجليزي) بنمط Mac & Pro
; =============================================================================

global VimMode          := false
global gLastPress       := 0
global yLastPress       := 0
global AutoScrollState  := 0     ; 0 = متوقف, 1 = لأسفل, -1 = لأعلى
global ScrollSpeed      := 5     ; السرعة من 1 إلى 10 (الافتراضي 5)
global ScrollAccum      := 0.0   ; مجمع الإزاحة الكسرية
global IsDragging       := false

; كائن شارة NORMAL MODE في أعلى الشاشة
global ModeGui          := ""

; =============================================================================
;  تبديل لغة الإدخال الفوري بضغطة واحدة على CapsLock (Mac / Pro Style)
; =============================================================================

SwitchLanguage() {
    SendInput("#{Space}")
}

; ضغطة واحدة سريعة على CapsLock تبدل لغة الإدخال فوراً
*CapsLock:: {
    SwitchLanguage()
}

; الضغط على Shift + CapsLock يُفعل / يُعطل وضع الحروف الكبيرة (Caps Lock الأصلي)
+CapsLock:: {
    curState := GetKeyState("CapsLock", "T")
    SetCapsLockState(curState ? "AlwaysOff" : "On")
    ToolTip(curState ? "🔤 CAPS LOCK: OFF" : "🔠 CAPS LOCK: ON", 15, 60)
    SetTimer(() => ToolTip(), -1200)
}

; =============================================================================
;  شارة NORMAL MODE المربعة الكبيرة في أعلى الشاشة
; =============================================================================

ShowMode() {
    global VimMode, ModeGui
    try {
        if (ModeGui) {
            ModeGui.Destroy()
            ModeGui := ""
        }
        
        if (VimMode) {
            ; 🟢 NORMAL MODE
            ModeGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "VimModeBadge")
            ModeGui.BackColor := "1B5E20"  ; أخضر داكن فخم
            ModeGui.SetFont("s16 bold cWhite", "Segoe UI")
            ModeGui.MarginX := 36
            ModeGui.MarginY := 12
            ModeGui.Add("Text", "Center +BackgroundTrans", "🟢 NORMAL MODE")
            ModeGui.Show("xCenter y12 NoActivate AutoSize")
        } else {
            ; ⚫ INSERT MODE
            ToolTip("⚫ INSERT MODE", 15, 10)
            SetTimer(() => ToolTip(), -1000)
        }
    } catch {
        if (VimMode)
            ToolTip("🟢 NORMAL MODE", 15, 10)
        else
            ToolTip("⚫ INSERT MODE", 15, 10)
        SetTimer(() => ToolTip(), -1200)
    }
}

; =============================================================================
;  إدارة تفعيل وإيقاف الوضع بنقرة واحدة (Single-Mode Toggle)
; =============================================================================

SetVimState(state) {
    global VimMode, IsDragging
    VimMode := state
    
    if (VimMode) {
        ; تفعيل وضع الملاحة والماوس
        StopAutoScroll()
        ClearHints()
        ClearGrid()
        ShowMode()
    } else {
        ; إيقاف والعودة لوضع الكتابة العادي
        StopAutoScroll()
        ClearHints()
        ClearGrid()
        if (IsDragging) {
            IsDragging := false
            Click("Up")
        }
        ShowMode()
    }
}

ToggleVimMode() {
    global VimMode
    SetVimState(!VimMode)
}

; مفتاح التبديل الموحد (Home أو NumpadHome أو Ctrl+Win)
Home::
NumpadHome::
^LWin::
^RWin:: ToggleVimMode()

exitVim() {
    SetVimState(false)
}

ToggleMouseDrag() {
    global IsDragging
    IsDragging := !IsDragging
    if (IsDragging) {
        Click("Down")
        ToolTip("✊ DRAG MODE (جاري السحب) - اضغط v أو Space للإفلات", 15, 60)
    } else {
        Click("Up")
        ToolTip()
        ShowMode()
    }
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
    
    wX := 0, wY := 0, wW := 0, wH := 0
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
    global HintGuis, HintMap, VimMode
    if (!VimMode)
        return
    
    StopAutoScroll()
    ClearGrid()
    ClearHints()
    
    activeHwnd := WinExist("A")
    if (!activeHwnd)
        return
    
    winX := 0, winY := 0, winW := 0, winH := 0
    WinGetPos(&winX, &winY, &winW, &winH, activeHwnd)
    ctrlHwnds := WinGetControlsHwnd(activeHwnd)
    
    elements := []
    for h in ctrlHwnds {
        try {
            if (!DllCall("IsWindowVisible", "Ptr", h))
                continue
            cX := 0, cY := 0, cW := 0, cH := 0
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
        
        MouseMove(el.centerX, el.centerY, 0)
        if (clickType == "Right")
            Click("Right")
        else
            Click("Left")
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
;  الطبقة الموحدة: وضع الملاحة والماوس الشامل (🟢 NORMAL MODE)
; =============================================================================
#HotIf VimMode

; خروج فوري إلى وضع الكتابة (INSERT MODE)
Escape:: {
    global AutoScrollState, GridActive
    if (AutoScrollState != 0)
        StopAutoScroll()
    else if (GridActive)
        ClearGrid()
    else {
        ClearHints()
        SetVimState(false)
    }
}
i:: SetVimState(false)

; -----------------------------------------------------------------------------
;  1. تحكم الماوس المتطابق ثنائي اليدين (WASD يسار / PL;' يمين + الأسهم)
; -----------------------------------------------------------------------------

; حركة لليسار (A يسار / L يمين / Left / ش / م)
*a::
*sc01E::
*l::
*sc026::
*Left:: {
    accel := 1.0
    MouseMove(-10, 0, 0, "R")
    while (GetKeyState("sc01E", "P") || GetKeyState("sc026", "P") || GetKeyState("Left", "P") || GetKeyState("a", "P") || GetKeyState("l", "P")) {
        dy := 0
        if (GetKeyState("sc011", "P") || GetKeyState("sc019", "P") || GetKeyState("Up", "P") || GetKeyState("w", "P") || GetKeyState("p", "P"))
            dy -= 1
        if (GetKeyState("sc01F", "P") || GetKeyState("sc027", "P") || GetKeyState("Down", "P") || GetKeyState("s", "P"))
            dy += 1
        
        isDual := (dy != 0)
        baseSpd := isDual ? 50.0 : (11.0 * accel)
        
        if GetKeyState("Shift", "P")
            baseSpd := 1.5
        else if GetKeyState("Ctrl", "P")
            baseSpd := baseSpd * 1.8
        
        moveX := -Integer(baseSpd)
        moveY := Integer(dy * baseSpd)
        MouseMove(moveX, moveY, 0, "R")
        
        if (!isDual && accel < 2.5)
            accel *= 1.04
        Sleep(10)
    }
}

; حركة لليمين (D يسار / ' يمين / Right / ي / ط)
*d::
*sc020::
*sc028::
*Right:: {
    accel := 1.0
    MouseMove(10, 0, 0, "R")
    while (GetKeyState("sc020", "P") || GetKeyState("sc028", "P") || GetKeyState("Right", "P") || GetKeyState("d", "P")) {
        dy := 0
        if (GetKeyState("sc011", "P") || GetKeyState("sc019", "P") || GetKeyState("Up", "P") || GetKeyState("w", "P") || GetKeyState("p", "P"))
            dy -= 1
        if (GetKeyState("sc01F", "P") || GetKeyState("sc027", "P") || GetKeyState("Down", "P") || GetKeyState("s", "P"))
            dy += 1
        
        isDual := (dy != 0)
        baseSpd := isDual ? 50.0 : (11.0 * accel)
        
        if GetKeyState("Shift", "P")
            baseSpd := 1.5
        else if GetKeyState("Ctrl", "P")
            baseSpd := baseSpd * 1.8
        
        moveX := Integer(baseSpd)
        moveY := Integer(dy * baseSpd)
        MouseMove(moveX, moveY, 0, "R")
        
        if (!isDual && accel < 2.5)
            accel *= 1.04
        Sleep(10)
    }
}

; حركة للأعلى (W يسار / P يمين / Up / ص / ح)
*w::
*sc011::
*p::
*sc019::
*Up:: {
    accel := 1.0
    MouseMove(0, -10, 0, "R")
    while (GetKeyState("sc011", "P") || GetKeyState("sc019", "P") || GetKeyState("Up", "P") || GetKeyState("w", "P") || GetKeyState("p", "P")) {
        dx := 0
        if (GetKeyState("sc01E", "P") || GetKeyState("sc026", "P") || GetKeyState("Left", "P") || GetKeyState("a", "P") || GetKeyState("l", "P"))
            dx -= 1
        if (GetKeyState("sc020", "P") || GetKeyState("sc028", "P") || GetKeyState("Right", "P") || GetKeyState("d", "P"))
            dx += 1
        
        isDual := (dx != 0)
        baseSpd := isDual ? 50.0 : (11.0 * accel)
        
        if GetKeyState("Shift", "P")
            baseSpd := 1.5
        else if GetKeyState("Ctrl", "P")
            baseSpd := baseSpd * 1.8
        
        moveX := Integer(dx * baseSpd)
        moveY := -Integer(baseSpd)
        MouseMove(moveX, moveY, 0, "R")
        
        if (!isDual && accel < 2.5)
            accel *= 1.04
        Sleep(10)
    }
}

; حركة للأسفل (S يسار / ; يمين / Down / س / ك)
*s::
*sc01F::
*sc027::
*Down:: {
    accel := 1.0
    MouseMove(0, 10, 0, "R")
    while (GetKeyState("sc01F", "P") || GetKeyState("sc027", "P") || GetKeyState("Down", "P") || GetKeyState("s", "P")) {
        dx := 0
        if (GetKeyState("sc01E", "P") || GetKeyState("sc026", "P") || GetKeyState("Left", "P") || GetKeyState("a", "P") || GetKeyState("l", "P"))
            dx -= 1
        if (GetKeyState("sc020", "P") || GetKeyState("sc028", "P") || GetKeyState("Right", "P") || GetKeyState("d", "P"))
            dx += 1
        
        isDual := (dx != 0)
        baseSpd := isDual ? 50.0 : (11.0 * accel)
        
        if GetKeyState("Shift", "P")
            baseSpd := 1.5
        else if GetKeyState("Ctrl", "P")
            baseSpd := baseSpd * 1.8
        
        moveX := Integer(dx * baseSpd)
        moveY := Integer(baseSpd)
        MouseMove(moveX, moveY, 0, "R")
        
        if (!isDual && accel < 2.5)
            accel *= 1.04
        Sleep(10)
    }
}

; -----------------------------------------------------------------------------
;  نقرات الماوس المتطابقة (اليد اليسرى ZXC / اليد اليمنى ,./ + Space & Enter)
; -----------------------------------------------------------------------------

; نقر أيسر (Z في اليسار / , في اليمين بجوار Enter / Space / Enter)
*z::
*sc02C::
*,::
*sc033::
*Space::
*Enter:: Click("Left")

; نقر أوسط / بكرة (X في اليسار / . في اليمين / e)
*x::
*sc02D::
*.::
*sc034::
*e::
*^Space:: Click("Middle")

; نقر أيمن (C في اليسار / / في اليمين / r)
*c::
*sc02E::
*sc035::
*r::
*+Space:: Click("Right")

; وضع السحب والإفلات (Drag Mode)
*v:: ToggleMouseDrag()

; -----------------------------------------------------------------------------
;  2. اختصارات التمرير والملاحة بنمط Vimium الأصلي (HJK)
; -----------------------------------------------------------------------------
j::
sc024:: {
    StopAutoScroll()
    SendInput("{WheelDown 2}")         ; j = تمرير لأسفل
}
k::
sc025:: {
    StopAutoScroll()
    SendInput("{WheelUp 2}")           ; k = تمرير لأعلى
}
h::
sc023:: {
    StopAutoScroll()
    SendInput("{Left 2}")              ; h = تنقل لليسار
}

u:: {
    StopAutoScroll()
    SendInput("{WheelUp 8}")           ; u = نصف صفحة لأعلى
}
+d:: {
    StopAutoScroll()
    SendInput("{WheelDown 8}")         ; Shift+d = نصف صفحة لأسفل
}

; -----------------------------------------------------------------------------
;  3. شبكة القفز وقمة الصفحة (Grid Jump & Page Navigation)
; -----------------------------------------------------------------------------
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

; -----------------------------------------------------------------------------
;  4. التمرير التلقائي الانسيابي (~60 Hz Auto-Scroll)
; -----------------------------------------------------------------------------
PgDn:: StartAutoScroll(1)              ; PageDown = تمرير تلقائي لأسفل
PgUp:: StartAutoScroll(-1)             ; PageUp = تمرير تلقائي لأعلى
^j:: StartAutoScroll(1)                ; Ctrl+j = تمرير تلقائي لأسفل
^k:: StartAutoScroll(-1)               ; Ctrl+k = تمرير تلقائي لأعلى

; -----------------------------------------------------------------------------
;  5. وضع التلميحات التفاعلي (UI Hint Mode)
; -----------------------------------------------------------------------------
f:: StartHintMode("Left")              ; f = إظهار تلميحات العناصر والنقر عليها
+f:: StartHintMode("Right")            ; F = إظهار التلميحات والنقر بزر الماوس الأيمن

; -----------------------------------------------------------------------------
;  6. إدارة التبويبات والتاريخ والنوافذ
; -----------------------------------------------------------------------------
t::  SendInput("^t")                   ; t = تبويب جديد
+x:: SendInput("^+t")                  ; Shift+x = استعادة تبويب
+j:: SendInput("^+{Tab}")              ; Shift+j = تبويب سابق
+k:: SendInput("^{Tab}")               ; Shift+k = تبويب تالي
+w:: SendInput("^n")                   ; Shift+w = نافذة جديدة
+h:: SendInput("!{Left}")              ; Shift+h = رجوع في التاريخ
+l:: SendInput("!{Right}")             ; Shift+l = تقدم في التاريخ

; -----------------------------------------------------------------------------
;  7. البحث والتحديث
; -----------------------------------------------------------------------------
+r:: SendInput("{F5}")                 ; Shift+r = إعادة تحميل الصفحة (Reload)
/:: {
    SetVimState(false)
    SendInput("^f")                    ; / = بحث في التطبيق
}
+s:: SendInput("^f")                   ; Shift+s = بحث داخل التطبيق (In-App Search)
n::  SendInput("{F3}")                 ; n = نتيجة تالية
+n:: SendInput("+{F3}")                ; N = نتيجة سابقة

; -----------------------------------------------------------------------------
;  8. نسخ ولصق
; -----------------------------------------------------------------------------
y:: {
    global yLastPress
    now := A_TickCount
    if (now - yLastPress < 500)
        SendInput("^c")                ; yy = نسخ
    yLastPress := now
}
+p:: SendInput("^v")                   ; Shift+p = لصق

; -----------------------------------------------------------------------------
;  9. شريط العنوان والتنقل بين الأقسام
; -----------------------------------------------------------------------------
+o:: {
    SetVimState(false)
    SendInput("^l")
}

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

; -----------------------------------------------------------------------------
;  10. التحكم بالسرعة والصوت
; -----------------------------------------------------------------------------
=::
+=::
NumpadAdd:: ChangeScrollSpeed(1)       ; + أو = = تسريع السكرول

-::
+-::
NumpadSub:: ChangeScrollSpeed(-1)      ; - = تبطيء السكرول

^0:: SendInput("^0")                   ; Ctrl+0 = إعادة ضبط التكبير

^Up::   SendInput("{Volume_Up}")
^Down:: SendInput("{Volume_Down}")
!0::    SendInput("{Volume_Mute}")

; -----------------------------------------------------------------------------
;  منع الحروف غير المخصصة من الكتابة في Normal Mode (Modal Lockout)
; -----------------------------------------------------------------------------
b::
m::
o::
q::
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
sc02B:: ; \
{
    return
}

; مساعدة
+/:: {
    help := "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
          . "🟢 VimWindows - المنظومة الشاملة ثنائية اليدين`n"
          . "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
          . "CapsLock: تبديل فوري للغة الإدخال (عربي ↔ إنجليزي)`n"
          . "Shift+CapsLock: تفعيل / تعطيل الحروف الكبيرة`n`n"
          . "Home Key: تفعيل / إيقاف NORMAL MODE بنقرة واحدة`n"
          . "Esc / i: الخروج الفوري لوضع الكتابة العادي`n`n"
          . "🖐️ تحكم الماوس باليد اليسرى:`n"
          . "  W / A / S / D  → أعلى / يسار / أسفل / يمين`n"
          . "  Z / X / C      → أيسر / بكرة (أوسط) / أيمن`n`n"
          . "🖐️ تحكم الماوس باليد اليمنى (بجوار Enter):`n"
          . "  P / L / ; / '  → أعلى / يسار / أسفل / يمين`n"
          . "  , / . / /      → أيسر / بكرة (أوسط) / أيمن`n"
          . "  زرين معاً      → سرعة توربو فائقة 50px!`n"
          . "  v              → وضع السحب والإفلات`n"
          . "  g              → شبكة القفز 3x3 (أو gg لأعلى الصفحة)`n"
          . "  Shift          → دقة بالبكسل`n"
          . "  Ctrl           → توربو إضافي`n`n"
          . "📜 التمرير والملاحة بنمط Vimium (HJK):`n"
          . "  j / k          → تمرير لأسفل / لأعلى`n"
          . "  h              → تنقل لليسار`n"
          . "  Shift+d / u    → نصف صفحة لأسفل / لأعلى`n"
          . "  gg / G         → أعلى / أسفل الصفحة`n"
          . "  f / F          → تلميحات العناصر (Hint Mode)`n"
          . "  PgDn / PgUp    → تمرير تلقائي مستمر`n`n"
          . "📑 التبويبات والبحث والحافظة:`n"
          . "  t / Shift+x    → تبويب جديد / استعادة تبويب`n"
          . "  Shift+j / Shift+k → التبويب السابق / التالي`n"
          . "  yy / Shift+p   → نسخ / لصق`n"
          . "  / / Shift+s    → بحث داخل التطبيق`n"
          . "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    MsgBox(help, "VimWindows", 0)
}

#HotIf
