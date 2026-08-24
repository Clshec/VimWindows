#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(true)
InstallKeybdHook()

; =============================================================================
;  VimWindows - تجربة اختصارات Vimium لنظام ويندوز
;  Ctrl+Win = NORMAL MODE | i أو Esc = INSERT MODE
; =============================================================================

global VimMode         := false
global gLastPress      := 0
global yLastPress      := 0
global AutoScrollState := 0     ; 0 = متوقف, 1 = لأسفل, -1 = لأعلى
global ScrollSpeed     := 5     ; السرعة من 1 إلى 10 (الافتراضي 5)
global ScrollAccum     := 0.0   ; مجمع الإزاحة الكسرية للسرعات البطيئة جداً

^LWin::
^RWin:: {
    global VimMode
    VimMode := !VimMode
    if (!VimMode)
        StopAutoScroll()
    ShowMode()
}

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
    VimMode := false
    ShowMode()
}

; =============================================================================
;  دوال التمرير التلقائي فائق النعومة (60 FPS Smooth Auto-Scroll)
; =============================================================================

GetScrollDelta(spd) {
    spd := Max(1, Min(10, spd))
    ; قيم الإزاحة الميكروية في كل إطار بتردد 60 FPS
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
    ; تفعيل المؤقت بتردد 60 إطار في الثانية (كل 16 مللي ثانية) لانسيابية تامة
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
#HotIf VimMode and !WinActive("ahk_exe chrome.exe")

; ----- إيقاف NORMAL MODE (فقط i و Esc) -----
Escape:: {
    global AutoScrollState
    if (AutoScrollState != 0)
        StopAutoScroll()
    else
        exitVim()
}

i:: {
    StopAutoScroll()
    exitVim()
}

; ----- التمرير التلقائي (Auto-Scroll) -----
v:: StartAutoScroll(1)                 ; v = تمرير تلقائي لأسفل
+v:: StartAutoScroll(-1)               ; V = تمرير تلقائي لأعلى
^j:: StartAutoScroll(1)                ; Ctrl+j = تمرير تلقائي لأسفل
^k:: StartAutoScroll(-1)               ; Ctrl+k = تمرير تلقائي لأعلى

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

; ----- التحديث والبحث -----
r::  SendInput("{F5}")                 ; r = Reload
/:: {
    exitVim()
    SendInput("^f")                    ; / = بحث
}
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

; ----- التفاعل والبحث في الشاشة -----
f::  SendInput("^m")                   ; f = تفاعل الشاشة
+f:: SendInput("^+m")                  ; F = تفاعل الشاشة الموسع
s::  SendInput("{Ctrl down}{Alt down}{Alt up}{Ctrl up}") ; s = البحث العام
+s:: SendInput("{Ctrl down}{Alt down}{Shift down}{Shift up}{Alt up}{Ctrl up}") ; S = البحث داخل النافذة

; ----- Vomnibar (شريط العنوان) -----
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
          . "Ctrl+Win → تفعيل/إيقاف NORMAL MODE`n"
          . "i / Esc  → INSERT MODE`n`n"
          . "📜 التمرير التلقائي (Auto-Scroll):`n"
          . "  v / Ctrl+j / Space → تمرير تلقائي لأسفل ⏬`n"
          . "  V / Ctrl+k         → تمرير تلقائي لأعلى ⏫`n"
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
          . "🔍 البحث والتفاعل:`n"
          . "  s       → البحث العام`n"
          . "  S       → بحث داخل النافذة`n"
          . "  f/F     → تفاعل بالشاشة`n`n"
          . "🎵 الصوت والميديا:`n"
          . "  Ctrl+↑↓ → رفع/خفض الصوت`n"
          . "  Alt+0   → كتم الصوت`n"
          . "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    MsgBox(help, "VimWindows", 0)
}

#HotIf
