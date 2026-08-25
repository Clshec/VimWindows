# 📖 Complete Shortcuts Reference Guide - VimWindows

Welcome to the comprehensive shortcuts reference and user guide for **VimWindows**. This tool brings full modal keyboard navigation, smooth micro-scrolling, UI hint tagging, and mouse emulation to the entire Windows operating system.

---

## 🎯 Modes Architecture

```text
               ┌───────────────────────────────┐
               │          INSERT MODE          │
               │   (Normal Windows Typing)     │
               └──────────────┬────────────────┘
                              │ Press Home or Ctrl+Win
                              ▼
               ┌───────────────────────────────┐
               │          NORMAL MODE          │
               │  (Vim Navigation & Shortcuts) │
               └───────┬──────────────┬────────┘
                       │              │
        Press m        │              │ Press f
        ▼              │              ▼
┌──────────────────┐   │      ┌──────────────────┐
│   MOUSE MODE     │   │      │    HINT MODE     │
│ (Smooth Pointer) │   │      │ (Yellow Badges)  │
└──────────────────┘   │      └──────────────────┘
                       │ Press g
                       ▼
               ┌──────────────────┐
               │  3x3 GRID JUMP   │
               │(Instant Teleport)│
               └──────────────────┘
```

---

## 🔘 1. Mode Switching

| Shortcut | Function | Description |
| :--- | :--- | :--- |
| **`Home`** | 🟢 **Toggle NORMAL MODE** | Single-press to toggle navigation mode on/off. |
| **`Ctrl + Win`** | 🟢 **Alternative Toggle** | Standard keyboard toggle for NORMAL MODE. |
| **`Esc`** or **`i`** | ⚫ **Exit to INSERT MODE** | Instantly return to standard Windows text input. |

---

## 🖱️ 2. Accelerated Mouse Mode (`m`)

When in `NORMAL MODE`, press **`m`** to enter continuous mouse control:

| Key | Action | Description |
| :--- | :--- | :--- |
| **`h`** / **`Left`** | ⬅️ **Move Left** | Smooth accelerated movement to the left. |
| **`j`** / **`Down`** | ⬇️ **Move Down** | Smooth accelerated movement downward. |
| **`k`** / **`Up`** | ⬆️ **Move Up** | Smooth accelerated movement upward. |
| **`l`** / **`Right`** | ➡️ **Move Right** | Smooth accelerated movement to the right. |
| **`Shift` (Held)** | 🐌 **Precision / Slow** | Slows down pointer for single-pixel precision. |
| **`Ctrl` (Held)** | ⚡ **Turbo Speed** | Doubles pointer speed for multi-monitor jumps. |
| **`Space`** or **`Enter`** | 👈 **Left Click** | Standard left mouse click at current cursor position. |
| **`Shift + Space`** / **`Shift + Enter`** | 👉 **Right Click** | Context menu click. |
| **`Ctrl + Space`** or **`,`** | 🔘 **Middle Click** | Open link in new tab or middle-click action. |
| **`d`** or **`v`** | ✊ **Drag & Drop Mode** | Holds left mouse button down for text selection / window dragging; press again to release. |
| **`Esc`** or **`q`** or **`m`** | ↩️ **Exit Mouse Mode** | Returns back to `NORMAL MODE`. |

---

## 🎯 3. UI Hint Mode (`f` & `F`)

Discovers visible interactive controls (buttons, menus, links, inputs) and places yellow tags:

| Key | Action | Description |
| :--- | :--- | :--- |
| **`f`** | 🎯 **Hints + Left Click** | Displays letter badges over UI elements; type the letter to click immediately. |
| **`F`** (`Shift + f`) | 🖱️ **Hints + Right Click** | Displays letter badges and performs a right-click on match. |
| **`Esc`** or **`Space`** | ❌ **Dismiss Hints** | Clears overlay badges and returns to NORMAL MODE. |

---

## 🔢 4. 3x3 Grid Jump (`g`)

Splits the screen into 9 regions for instant cursor positioning:

```text
┌───────────┬───────────┬───────────┐
│     1     │     2     │     3     │
│ Top-Left  │Top-Center │ Top-Right │
├───────────┼───────────┼───────────┤
│     4     │     5     │     6     │
│ Mid-Left  │  Center   │ Mid-Right │
├───────────┼───────────┼───────────┤
│     7     │     8     │     9     │
│Bottom-Left│Bot-Center │Bot-Right  │
└───────────┴───────────┴───────────┘
```

- Press **`g`** to display the 3x3 grid.
- Press **`1` to `9`** to jump cursor to that region's center.
- Double-tap **`gg`** to jump to the top of document/page (`Ctrl + Home`).
- Press **`G`** (`Shift + g`) to jump to the end of document/page (`Ctrl + End`).

---

## 📜 5. Smooth Micro-Scrolling (~60 Hz)

| Key | Action | Description |
| :--- | :--- | :--- |
| **`PgDn`** / **`Space`** / **`Ctrl + j`** | ⏬ **Auto-Scroll Down** | Continuous micro-scroll downward (~60 Hz). |
| **`PgUp`** / **`Ctrl + k`** | ⏫ **Auto-Scroll Up** | Continuous micro-scroll upward. |
| **`+`** / **`=`** / **`Numpad +`** | ⚡ **Increase Speed** | Accelerates auto-scroll (Levels 1 to 10). |
| **`-`** / **`Numpad -`** | 🐌 **Decrease Speed** | Decelerates auto-scroll down to ultra-slow level 1. |
| **`Space`** / **`Esc`** / Any navigation key | ⏹️ **Stop Scroll** | Instantly stops auto-scrolling. |

---

## 🧭 6. Vimium Manual Scrolling

| Key | Action | Description |
| :--- | :--- | :--- |
| **`j`** | ⬇️ Scroll Down | Discrete 2-step downward scroll. |
| **`k`** | ⬆️ Scroll Up | Discrete 2-step upward scroll. |
| **`h`** | ⬅️ Move Left | 2-step left movement. |
| **`l`** | ➡️ Move Right | 2-step right movement safely. |
| **`d`** | ⏬ Half Page Down | Fast half-screen downward jump. |
| **`u`** | ⏫ Half Page Up | Fast half-screen upward jump. |

---

## 📑 7. Tabs, Windows & History

| Key | Action | Description |
| :--- | :--- | :--- |
| **`t`** | 📑 **New Tab** | Opens a new tab (`Ctrl + T`). |
| **`x`** | ❌ **Close Tab** | Closes current tab (`Ctrl + W`). |
| **`X`** (`Shift + x`) | 🔄 **Restore Tab** | Reopens last closed tab (`Ctrl + Shift + T`). |
| **`J`** (`Shift + j`) | ⬅️ **Previous Tab** | Switches to previous tab (`Ctrl + Shift + Tab`). |
| **`K`** (`Shift + k`) | ➡️ **Next Tab** | Switches to next tab (`Ctrl + Tab`). |
| **`W`** (`Shift + w`) | 🪟 **New Window** | Opens a new application window (`Ctrl + N`). |
| **`H`** (`Shift + h`) | ◀️ **History Back** | Navigates back (`Alt + Left`). |
| **`L`** (`Shift + l`) | ▶️ **History Forward** | Navigates forward (`Alt + Right`). |
| **`r`** | 🔄 **Reload** | Refreshes current page/view (`F5`). |
| **`]`** / **`.`** | ⏩ **Next Section** | Cycles to next frame/section in app (`F6`). |
| **`[`** / **`,`** | ⏪ **Previous Section** | Cycles to previous frame/section (`Shift + F6`). |

---

## 🔍 8. System & In-App Search

| Key | Action | Description |
| :--- | :--- | :--- |
| **`s`** | ⚡ **Windows Search** | Opens native Windows Start/Search (`Win + S`). |
| **`S`** (`Shift + s`) | 🔍 **In-App Search** | Opens application's find bar (`Ctrl + F`). |
| **`/`** | 🔎 **Search & Type** | Exits to insert mode and opens find bar (`Ctrl + F`). |
| **`n`** | ⏭️ **Find Next** | Jumps to next search match (`F3`). |
| **`N`** (`Shift + n`) | ⏮️ **Find Previous** | Jumps to previous search match (`Shift + F3`). |
| **`o`** | 🌐 **Focus Address Bar** | Focuses address bar / URL bar (`Ctrl + L`). |

---

## 📋 9. Clipboard & Media Controls

| Key | Action |
| :--- | :--- |
| **`yy`** | 📋 Copy selected text (`Ctrl + C`). |
| **`p`** | 📥 Paste from clipboard (`Ctrl + V`). |
| **`Ctrl + 0`** | 🔍 Reset zoom to default 100%. |
| **`Ctrl + ,`** | ⏮️ Previous media track. |
| **`Ctrl + .`** | ⏭️ Next media track. |
| **`Ctrl + ↑`** | 🔊 Volume Up. |
| **`Ctrl + ↓`** | 🔉 Volume Down. |
| **`Alt + 0`** | 🔇 Mute Audio. |
| **`?`** (`Shift + /`) | ❓ Show Quick Help Dialog. |
