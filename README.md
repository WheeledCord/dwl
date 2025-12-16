# tbwm - Hackable Wayland Compositor

A highly customizable dynamic tiling Wayland compositor with full Scheme scripting.

## Features

- **100% Scheme Configuration** - Everything configurable at runtime via `~/.config/tbwm/config.scm`
- **Hot Reload** - Change config without restarting (Super+Shift+C)
- **Grid-based Layout** - Windows snap to character cell boundaries
- **Dwindle Tiling** - Dynamic binary-tree tiling layout
- **Retro Aesthetic** - VGA-style title bars and decorations
- **Built-in Launcher** - Press Super+D for application launcher
- **Desktop REPL** - Interactive Scheme console displayed on the desktop background (Super+;)

## Building

Dependencies:
- wlroots 0.19+
- wayland, wayland-protocols
- libinput, xkbcommon
- freetype2, pangocairo
- libxcb, xcb-icccm (for XWayland)

```bash
make
```

## Running

```bash
./tbwm
```

Or from a TTY:
```bash
./tbwm -s 'foot'
```

## Configuration

All configuration is done via `~/.config/tbwm/config.scm`. A default config is created automatically on first run.

### Appearance

```scheme
;; Window borders
(set-border-width 1)
(set-border-color "#444444")   ; unfocused windows
(set-focus-color "#005577")    ; focused window
(set-urgent-color "#ff0000")   ; urgent windows

;; Frame colors (title bar and decorations)
;; Format: #AARRGGBB (alpha, red, green, blue)
(set-frame-bg-color "#ff0000aa")  ; blue background
(set-frame-fg-color "#ffaaaaaa")  ; gray text/lines

;; Root/desktop background color
(set-root-color "#000000")

;; Font for title bars
(set-font "/path/to/font.ttf" 16)

;; Title bar overflow handling
(set-title-scroll-mode 1)   ; 1 = scroll, 0 = truncate with ...
(set-title-scroll-speed 30) ; pixels per second
```

### Behavior

```scheme
;; Focus follows mouse
(set-sloppy-focus #t)

;; Keyboard repeat (rate chars/sec, delay ms)
(set-repeat-rate 25 600)
```

### Input Devices

```scheme
;; Trackpad
(set-tap-to-click #t)
(set-natural-scrolling #f)
(set-accel-speed 0.0)  ; -1.0 to 1.0
```

### Window Rules

```scheme
;; (add-rule app-id title tags floating monitor)
;; app-id and title can be #f (any), tags is bitmask, monitor is -1 for any

;; Firefox on tag 9
(add-rule "firefox" #f (ash 1 8) #f -1)

;; Pavucontrol always floating
(add-rule "pavucontrol" #f 0 #t -1)

;; Clear all rules
(clear-rules)
```

### Keybindings

```scheme
;; Syntax: (bind-key "MODIFIERS-key" callback)
;; Modifiers: M = Super, S = Shift, C = Control, A = Alt

(bind-key "M-Return" (lambda () (spawn "foot")))
(bind-key "M-d" (lambda () (toggle-launcher)))
(bind-key "M-q" (lambda () (kill-client)))
(bind-key "M-S-e" (lambda () (quit)))

;; Navigation (vim keys)
(bind-key "M-h" (lambda () (focus-dir DIR-LEFT)))
(bind-key "M-j" (lambda () (focus-dir DIR-DOWN)))
(bind-key "M-k" (lambda () (focus-dir DIR-UP)))
(bind-key "M-l" (lambda () (focus-dir DIR-RIGHT)))

;; Swap windows
(bind-key "M-S-h" (lambda () (swap-dir DIR-LEFT)))
(bind-key "M-S-j" (lambda () (swap-dir DIR-DOWN)))
(bind-key "M-S-k" (lambda () (swap-dir DIR-UP)))
(bind-key "M-S-l" (lambda () (swap-dir DIR-RIGHT)))

;; Clear all keybindings
(unbind-all)
```

### Mouse Bindings

```scheme
;; Buttons: button1 (left), button2 (middle), button3 (right)
(bind-mouse "M-button1" (lambda () (log "move")))
(bind-mouse "M-button3" (lambda () (log "resize")))

;; Clear all mouse bindings
(clear-mouse-bindings)
```

### Available Functions

**Window Management:**
- `(spawn cmd)` - launch a program
- `(quit)` - exit tbwm
- `(kill-client)` - close focused window
- `(toggle-floating)` / `(toggle-fullscreen)`
- `(zoom)` - swap with master
- `(refresh)` - refresh layout

**Navigation:**
- `(focus-dir DIR-LEFT/RIGHT/UP/DOWN)` - focus window in direction
- `(swap-dir dir)` - swap window in direction  
- `(focus-stack 1)` / `(focus-stack -1)` - focus next/prev
- `(focus-monitor MON-LEFT/RIGHT)` - focus monitor

**Tags:**
- `(view-tag n)` - switch to tag 1-9
- `(tag-window n)` - move window to tag
- `(toggle-tag n)` - toggle tag visibility
- `(view-all)` - view all tags
- `(tag-all)` - sticky window

**Layouts:**
- `(set-layout "tile"/"dwindle"/"monocle"/"float")`
- `(cycle-layout)` - cycle through layouts
- `(inc-mfact 0.05)` - adjust master size

**Queries:**
- `(focused-app-id)` - get app_id of focused window
- `(focused-title)` - get title of focused window
- `(current-tag)` - get current tag number
- `(window-count)` - get number of visible windows

**REPL:**
- `(toggle-repl)` - open/close the desktop REPL (Super+;)

**Meta:**
- `(reload-config)` - reload config without restart
- `(log msg)` - print to stderr
- `(eval-string code)` - evaluate Scheme code

### Default Keybindings

| Key | Action |
|-----|--------|
| `Super+Return` | Terminal |
| `Super+d` | Launcher |
| `Super+q` | Close window |
| `Super+Shift+e` | Quit |
| `Super+h/j/k/l` | Focus direction |
| `Super+Shift+h/j/k/l` | Swap windows |
| `Super+f` | Fullscreen |
| `Super+Shift+Space` | Toggle floating |
| `Super+1-9` | Switch tag |
| `Super+Shift+1-9` | Move to tag |
| `Super+Shift+c` | Reload config |
| `Super+Shift+r` | Refresh layout |
| `Super+;` | Toggle REPL |

## Architecture

- **s7 Scheme** - Embedded Scheme interpreter for configuration
- **Grid System** - Cell dimensions from loaded TTF font (default 8x16)
- **Dwindle Layout** - Binary tree tiling with recursive splitting
- **Title Bars** - FreeType rendered with double-line box drawing characters

## License

See LICENSE files.
