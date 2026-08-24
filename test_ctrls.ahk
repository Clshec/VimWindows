#Requires AutoHotkey v2.0
activeHwnd := WinExist("A")
controls := WinGetControlsHwnd(activeHwnd)
out := "Active Window: " . WinGetTitle(activeHwnd) . "`nFound controls: " . controls.Length . "`n"
Loop Min(10, controls.Length) {
    h := controls[A_Index]
    try {
        ControlGetPos(&X, &Y, &W, &H, h)
        out .= "Ctrl #" . A_Index . ": " . WinGetClass(h) . " @ (" . X . "," . Y . "," . W . "," . H . ")`n"
    }
}
FileAppend(out, "D:\Documents\VimWindows\out_ctrls.txt")
ExitApp(0)
