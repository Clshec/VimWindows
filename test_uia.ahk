#Requires AutoHotkey v2.0
DllCall("ole32\CoInitialize", "Ptr", 0)

CLSID := Buffer(16)
IID_IUnk := Buffer(16)
IID_UIA := Buffer(16)
DllCall("ole32\CLSIDFromString", "WStr", "{ff48dba4-60ef-4201-aa87-54103eef594e}", "Ptr", CLSID)
DllCall("ole32\CLSIDFromString", "WStr", "{00000000-0000-0000-C000-000000000046}", "Ptr", IID_IUnk)
DllCall("ole32\CLSIDFromString", "WStr", "{30cbe57d-d9d0-452a-ab13-7ac0e10243e9}", "Ptr", IID_UIA)

pUnk := 0
hr1 := DllCall("ole32\CoCreateInstance", "Ptr", CLSID, "Ptr", 0, "UInt", 1, "Ptr", IID_IUnk, "Ptr*", &pUnk)

pUIA := 0
hr2 := ComCall(0, pUnk, "Ptr", IID_UIA, "Ptr*", &pUIA)

FileAppend("hr1: " . Format("0x{:X}", hr1 & 0xFFFFFFFF) . ", pUnk: " . pUnk . "`nhr2: " . Format("0x{:X}", hr2 & 0xFFFFFFFF) . ", pUIA: " . pUIA, "D:\Documents\VimWindows\out.txt")
