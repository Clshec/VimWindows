# 📖 Complete Shortcuts Reference Guide - VimWindows

Welcome to the comprehensive shortcuts reference and user guide for **VimWindows**. This tool brings full modal keyboard navigation, instant mouse physics emulation, UI hint tagging, smooth micro-scrolling, and single-tap **`CapsLock`** language switching to Windows.

---

## 🌐 Instant Language Switcher (CapsLock)

| Shortcut | Function | Description |
| :--- | :--- | :--- |
| **`CapsLock`** | 🌐 **Toggle Language (Instant)** | Single-tap on CapsLock switches keyboard language instantly (Mac & Pro style). |
| **`Shift + CapsLock`** | 🔠 **Toggle Caps Lock** | Enables / disables native Caps Lock uppercase state. |

---

## 🎯 3-State Mode Cycler (via Home Key)

The **`Home`** key (or `NumpadHome` or `Ctrl + Win`) is the single master toggle for cycling through the three operating modes:

```text
               ┌─────────────────────────────────────────┐
               │          ⚫ 0. INSERT MODE              │
               │       (Normal Windows Typing)           │
               └────────────────────┬────────────────────┘
                                    │ Press Home (1st click)
                                    ▼
               ┌─────────────────────────────────────────┐
               │          🟢 1. NORMAL MODE              │
               │   (Vim Navigation, Scroll & Hints)      │
               └────────────────────┬────────────────────┘
                                    │ Press Home (2nd click)
                                    ▼
               ┌─────────────────────────────────────────┐
               │          🔵 2. MOUSE MODE               │
               │      (Direct Instant Mouse Engine)      │
               └────────────────────┬────────────────────┘
                                    │ Press Home (3rd click) or Esc
                                    ▼
               ┌─────────────────────────────────────────┐
               │          ⚫ 0. INSERT MODE              │
               └─────────────────────────────────────────┘
```

- **Click 1**: `🟢 NORMAL MODE` (Large green badge `NORMAL MODE` at top center).
- **Click 2**: `🔵 MOUSE MODE` (Large blue badge `MOUSE MODE` with instant mouse speed).
- **Click 3**: `⚫ INSERT MODE` (Back to standard Windows text input).
- **`Esc` Key**: Directly exits to `INSERT MODE` from any active mode.

---

## 🖱️ 1. Instant Mouse Mode (State 2 🔵)

When in `MOUSE MODE`, the pointer is driven by a zero-latency continuous physics loop:

| Key | Action | Description |
| :--- | :--- | :--- |
| **`h / j / k / l`** or **Arrows** or **`WASD`** or **`UIOP`** | 🖱️ **Instant Mouse Move** | Ultra-responsive continuous physics movement with zero latency. |
| **`Shift` (Held)** | 🐌 **Pixel Precision** | Slows pointer down to 1px precision for delicate clicks. |
| **`Ctrl` (Held)** | ⚡ **Hyper Turbo** | Multiplies speed (2.5x) for multi-monitor jumps. |
| **`Space`** or **`Enter`** or **`m`** | 👈 **Left Click** | Standard left click at cursor position. |
| **`Shift + Space`** or **`Shift + Enter`** or **`r`** | 👉 **Right Click** | Context menu right click. |
| **`Ctrl + Space`** | 🔘 **Middle Click** | Open link in new tab. |
| **`v`** | ✊ **Drag & Drop Mode** | Toggles left mouse button hold for selection / dragging. |
| **`g`** | 🔢 **3x3 Grid Jump** | Displays 3x3 quadrant grid for instant teleporting. |
| **`Esc`** | ❌ **Exit Mode** | Instantly exits to `INSERT MODE`. |

---

## 🧭 2. Vimium Navigation (NORMAL MODE - State 1 🟢)

### 📜 Scroll & Navigation:
| Key | Action | Description |
| :--- | :--- | :--- |
| **`j`** | ⬇️ Scroll Down | Discrete 2-step downward scroll. |
| **`k`** | ⬆️ Scroll Up | Discrete 2-step upward scroll. |
| **`h`** | ⬅️ Move Left | 2-step left movement safely. |
| **`l`** | ➡️ Move Right | 2-step right movement safely. |
| **`d`** | ⏬ Half Page Down | Fast half-screen downward jump. |
| **`u`** | ⏫ Half Page Up | Fast half-screen upward jump. |
| **`gg`** | 🔝 Top of Page | Instant jump to document top (`Ctrl + Home`). |
| **`G`** (`Shift + g`) | 🔚 End of Page | Instant jump to document bottom (`Ctrl + End`). |

### 🎯 Hints & Grid:
| Key | Action | Description |
| :--- | :--- | :--- |
| **`f`** | 🎯 **Hints + Left Click** | Type yellow letter badge to click control. |
| **`F`** (`Shift + f`) | 🖱️ **Hints + Right Click** | Right-click target control. |
| **`g`** | 🔢 **3x3 Grid Jump** | 9-quadrant instant teleport. |

### 🌊 Smooth Micro-Scroll (~60 Hz):
| Key | Action | Description |
| :--- | :--- | :--- |
| **`PgDn`** / **`Space`** / **`Ctrl + j`** | ⏬ **Auto-Scroll Down** | Continuous micro-scroll downward (~60 Hz). |
| **`PgUp`** / **`Ctrl + k`** | ⏫ **Auto-Scroll Up** | Continuous micro-scroll upward. |
| **`+`** / **`=`** / **`Numpad +`** | ⚡ **Increase Speed** | Accelerates auto-scroll (Levels 1 to 10). |
| **`-`** / **`Numpad -`** | 🐌 **Decrease Speed** | Decelerates auto-scroll. |

---

## 📑 3. Tabs, Search & Clipboard

| Key | Action | Description |
| :--- | :--- | :--- |
| **`t`** | 📑 **New Tab** | Opens a new tab (`Ctrl + T`). |
| **`x`** | ❌ **Close Tab** | Closes current tab (`Ctrl + W`). |
| **`X`** (`Shift + x`) | 🔄 **Restore Tab** | Reopens last closed tab (`Ctrl + Shift + T`). |
| **`J`** (`Shift + j`) | ⬅️ **Previous Tab** | Switches to previous tab (`Ctrl + Shift + Tab`). |
| **`K`** (`Shift + k`) | ➡️ **Next Tab** | Switches to next tab (`Ctrl + Tab`). |
| **`W`** (`Shift + w`) | 🪟 **New Window** | Opens a new application window (`Ctrl + N`). |
| **`s`** | ⚡ **Windows Search** | Opens native Windows Start/Search (`Win + S`). |
| **`S`** (`Shift + s`) | 🔍 **In-App Search** | Opens application's find bar (`Ctrl + F`). |
| **`yy`** | 📋 **Copy** | Copy selected text (`Ctrl + C`). |
| **`p`** | 📥 **Paste** | Paste from clipboard (`Ctrl + V`). |
