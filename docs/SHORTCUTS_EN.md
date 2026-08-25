# 📖 Complete Shortcuts Reference Guide - VimWindows

Welcome to the comprehensive shortcuts reference and user guide for **VimWindows**. This tool brings full modal keyboard navigation, smooth micro-scrolling, UI hint tagging, and high-speed mouse emulation to the entire Windows operating system.

---

## 🎯 Modes Architecture & Top Badge

When `NORMAL MODE` is active, a prominent, clean, large badge displaying **`NORMAL MODE`** is shown at the top-center of the screen:

```text
               ┌───────────────────────────────┐
               │          INSERT MODE          │
               │   (Normal Windows Typing)     │
               └──────────────┬────────────────┘
                              │ Press Home or Ctrl+Win
                              ▼
               ┌───────────────────────────────┐
               │   🟢 LARGE "NORMAL MODE" BOX  │
               └───────┬──────────────┬────────┘
                       │              │
    Upper Row u/i/o/p  │              │ Press f
    or Press m         │              │
    ▼                  │              ▼
┌──────────────────┐   │      ┌──────────────────┐
│ 🖱️ HIGH-SPEED    │   │      │    HINT MODE     │
│   MOUSE MOVE     │   │      │ (Yellow Badges)  │
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
| **`Esc`** | ⚫ **Exit to INSERT MODE** | Instantly return to standard Windows text input. |

---

## 🖱️ 2. High-Speed Mouse Navigation (Upper Row & Arrows)

Direct high-speed mouse movement without interfering with Vimium's original `h`, `j`, `k`, `l` navigation keys:

| Key | Direction / Action | Description |
| :--- | :--- | :--- |
| **`u`** / **`Left`** | ⬅️ **Move Left** | Instant high-speed mouse movement to the left. |
| **`i`** / **`Up`** | ⬆️ **Move Up** | Instant high-speed mouse movement upward. |
| **`o`** / **`Down`** | ⬇️ **Move Down** | Instant high-speed mouse movement downward. |
| **`p`** / **`Right`** | ➡️ **Move Right** | Instant high-speed mouse movement to the right. |
| **`Shift` (Held)** | 🐌 **Precision Mode** | Slows pointer down to 1px precision for delicate clicks. |
| **`Ctrl` (Held)** | ⚡ **Hyper Turbo** | Multiplies speed (2.5x) for multi-monitor teleporting. |
| **`Enter`** or **`Space`** | 👈 **Left Click** | Standard left mouse click at current cursor position. |
| **`Shift + Enter`** | 👉 **Right Click** | Context menu click. |
| **`m`** | 🖱️ **Dedicated Mouse Mode** | Activates isolated mouse mode (HJKL, Space, d for drag). |

---

## 🧭 3. Original Vimium Navigation (Fully Preserved)

| Key | Action | Description |
| :--- | :--- | :--- |
| **`j`** | ⬇️ Scroll Down | Discrete 2-step downward scroll. |
| **`k`** | ⬆️ Scroll Up | Discrete 2-step upward scroll. |
| **`h`** | ⬅️ Move Left | 2-step left movement safely. |
| **`l`** | ➡️ Move Right | 2-step right movement safely. |
| **`d`** | ⏬ Half Page Down | Fast half-screen downward jump. |
| **`gg`** | 🔝 Top of Page | Instant jump to document/page top (`Ctrl + Home`). |
| **`G`** (`Shift + g`) | 🔚 End of Page | Instant jump to document/page bottom (`Ctrl + End`). |

---

## 🎯 4. UI Hint Mode (`f` & `F`)

Discovers visible interactive controls (buttons, menus, links, inputs) and places yellow tags:

| Key | Action | Description |
| :--- | :--- | :--- |
| **`f`** | 🎯 **Hints + Left Click** | Displays letter badges over UI elements; type the letter to click immediately. |
| **`F`** (`Shift + f`) | 🖱️ **Hints + Right Click** | Displays letter badges and performs a right-click on match. |
| **`Esc`** or **`Space`** | ❌ **Dismiss Hints** | Clears overlay badges and returns to NORMAL MODE. |

---

## 🔢 5. 3x3 Grid Jump (`g`)

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

---

## 📜 6. Smooth Micro-Scrolling (~60 Hz)

| Key | Action | Description |
| :--- | :--- | :--- |
| **`PgDn`** / **`Space`** / **`Ctrl + j`** | ⏬ **Auto-Scroll Down** | Continuous micro-scroll downward (~60 Hz). |
| **`PgUp`** / **`Ctrl + k`** | ⏫ **Auto-Scroll Up** | Continuous micro-scroll upward. |
| **`+`** / **`=`** / **`Numpad +`** | ⚡ **Increase Speed** | Accelerates auto-scroll (Levels 1 to 10). |
| **`-`** / **`Numpad -`** | 🐌 **Decrease Speed** | Decelerates auto-scroll down to ultra-slow level 1. |
| **`Space`** / **`Esc`** / Any navigation key | ⏹️ **Stop Scroll** | Instantly stops auto-scrolling. |

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
| **`[`** | ⏪ **Previous Section** | Cycles to previous frame/section (`Shift + F6`). |

---

## 🔍 8. System & In-App Search

| Key | Action | Description |
| :--- | :--- | :--- |
| **`s`** | ⚡ **Windows Search** | Opens native Windows Start/Search (`Win + S`). |
| **`S`** (`Shift + s`) | 🔍 **In-App Search** | Opens application's find bar (`Ctrl + F`). |
| **`/`** | 🔎 **Search & Type** | Exits to insert mode and opens find bar (`Ctrl + F`). |
| **`n`** | ⏭️ **Find Next** | Jumps to next search match (`F3`). |
| **`N`** (`Shift + n`) | ⏮️ **Find Previous** | Jumps to previous search match (`Shift + F3`). |
| **`+o`** (`Shift + o`) | 🌐 **Focus Address Bar** | Focuses address bar / URL bar (`Ctrl + L`). |

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
