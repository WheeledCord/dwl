# TurboWM Scheme API Reference

TurboWM uses [s7 Scheme](https://ccrma.stanford.edu/software/snd/snd/s7.html) as its embedded scripting language. All configuration is done through `~/.config/tbwm/config.scm`.

## Table of Contents

- [Quick Start](#quick-start)
- [Appearance](#appearance)
- [Status Bar](#status-bar)
- [Keybindings](#keybindings)
- [Mouse Bindings](#mouse-bindings)
- [Window Management](#window-management)
- [Tags / Virtual Desktops](#tags--virtual-desktops)
- [Queries](#queries)
- [Input Devices](#input-devices)
- [Window Rules](#window-rules)
- [System](#system)
- [Constants](#constants)

---

## Quick Start

Your config lives at `~/.config/tbwm/config.scm`. It's automatically created with defaults on first run.

```scheme
;; Reload config at runtime
(reload-config)

;; Or press Super+Shift+C (default binding)
```

---

## Appearance

### `(set-bg-color color)`

Set the background/REPL color. This is the actual background color of the desktop.

**Parameters:**
- `color` - String in `#RRGGBB` format

**Examples:**
```scheme
(set-bg-color "#000000")  ; Black (default)
(set-bg-color "#2e3440")  ; Nord dark
(set-bg-color "#1d1f21")  ; Dracula-ish
```

---

### `(set-bg-text-color color)`

Set the background/REPL text color.

**Parameters:**
- `color` - String in `#RRGGBB` format

**Examples:**
```scheme
(set-bg-text-color "#888888")  ; Grey (default)
(set-bg-text-color "#d8dee9")  ; Nord light
(set-bg-text-color "#f8f8f2")  ; White
```

---

### `(set-border-color color)`

Set the window highlight/border background color. This is the blue color you see in window frames and the status bar.

**Parameters:**
- `color` - String in `#RRGGBB` format

**Examples:**
```scheme
(set-border-color "#0000aa")  ; Blue (default)
(set-border-color "#5e81ac")  ; Nord blue
(set-border-color "#bd93f9")  ; Dracula purple
```

---

### `(set-border-line-color color)`

Set the color of box-drawing characters (╔═╗║╚╝) and text in window frames.

**Parameters:**
- `color` - String in `#RRGGBB` format

**Examples:**
```scheme
(set-border-line-color "#aaaaaa")  ; Grey (default)
(set-border-line-color "#88c0d0")  ; Nord cyan
(set-border-line-color "#ffffff")  ; White
```

---

### `(set-font path size)`

Set the grid font used for window frames and status bar.

**Parameters:**
- `path` - Absolute path to a TTF font file
- `size` - Font size in pixels

**Examples:**
```scheme
(set-font "/usr/share/fonts/TTF/DejaVuSansMono.ttf" 14)
(set-font "/home/user/.local/share/fonts/PxPlus_IBM_VGA_8x16.ttf" 16)
```

**Note:** The font determines the grid cell size. Monospace bitmap fonts work best.

---

### `(set-title-scroll-mode mode)`

Control how long window titles are displayed.

**Parameters:**
- `mode` - `0` for truncation with `...`, `1` for smooth scrolling

**Examples:**
```scheme
(set-title-scroll-mode 1)  ; Scroll long titles
(set-title-scroll-mode 0)  ; Truncate with ...
```

---

### `(set-title-scroll-speed speed)`

Set the scroll speed for long titles.

**Parameters:**
- `speed` - Pixels per second (default: 30)

**Examples:**
```scheme
(set-title-scroll-speed 30)  ; Default
(set-title-scroll-speed 60)  ; Faster
(set-title-scroll-speed 15)  ; Slower
```

---

## Status Bar

### `(set-tag-count n)`

Set the number of virtual desktops (tags) shown in the status bar.

**Parameters:**
- `n` - Number of tags, 1-9

**Examples:**
```scheme
(set-tag-count 9)  ; Default - tags 1-9
(set-tag-count 4)  ; Minimal - only 4 workspaces
```

---

### `(set-show-time enabled)`

Show or hide the time in the status bar.

**Parameters:**
- `enabled` - `#t` to show, `#f` to hide

**Examples:**
```scheme
(set-show-time #t)  ; Show time
(set-show-time #f)  ; Hide time
```

---

### `(set-show-date enabled)`

Show or hide the date in the status bar.

**Parameters:**
- `enabled` - `#t` to show, `#f` to hide

**Examples:**
```scheme
(set-show-date #t)  ; Show date
(set-show-date #f)  ; Hide date
```

---

### `(set-status-text text)`

Set custom status text. When set, this replaces the date/time display.

**Parameters:**
- `text` - String to display, or `""` to clear

**Examples:**
```scheme
(set-status-text "Battery: 85% | WiFi: Connected")
(set-status-text "")  ; Clear, show date/time again
```

**Pro tip:** Call this from a script that runs periodically to show dynamic info:
```scheme
;; In your config or via the REPL
(set-status-text (string-append "Load: " (system "cat /proc/loadavg | cut -d' ' -f1")))
```

---

## Keybindings

### `(bind-key keyspec callback)`

Bind a key combination to a Scheme function.

**Parameters:**
- `keyspec` - String like `"M-Return"` (see Modifier Keys below)
- `callback` - A lambda or function to call when pressed

**Modifier Keys:**
- `M` - Super/Meta/Windows key
- `S` - Shift
- `C` - Control
- `A` - Alt

**Key Names:** Use X11 keysym names: `Return`, `space`, `Tab`, `Escape`, `Left`, `Right`, `Up`, `Down`, `a`-`z`, `0`-`9`, `F1`-`F12`, etc.

**Examples:**
```scheme
;; Launch terminal
(bind-key "M-Return" (lambda () (spawn "foot")))

;; Close window
(bind-key "M-q" (lambda () (kill-client)))

;; Multiple modifiers
(bind-key "M-S-e" (lambda () (quit)))
(bind-key "C-A-t" (lambda () (spawn "foot")))

;; Arrow keys
(bind-key "M-Left" (lambda () (focus-dir DIR-LEFT)))
(bind-key "M-S-Left" (lambda () (swap-dir DIR-LEFT)))
```

---

### `(unbind-all)`

Remove all keybindings. Useful before defining a fresh set.

**Examples:**
```scheme
(unbind-all)
;; Now define only the bindings you want
(bind-key "M-Return" (lambda () (spawn "foot")))
```

---

## Mouse Bindings

### `(bind-mouse buttonspec callback)`

Bind a mouse button with modifiers to a function.

**Parameters:**
- `buttonspec` - String like `"M-button1"`
- `callback` - Lambda to execute

**Button Names:**
- `button1` - Left click
- `button2` - Middle click
- `button3` - Right click

**Examples:**
```scheme
;; Super + Left click to move windows
(bind-mouse "M-button1" (lambda () (move-window)))

;; Super + Right click to resize windows
(bind-mouse "M-button3" (lambda () (resize-window)))
```

---

### `(clear-mouse-bindings)`

Remove all mouse bindings.

---

## Window Management

### `(spawn command)`

Launch a program.

**Parameters:**
- `command` - Shell command string

**Examples:**
```scheme
(spawn "foot")
(spawn "firefox")
(spawn "foot -e htop")
(spawn "notify-send 'Hello!'")
```

---

### `(kill-client)`

Close the focused window.

---

### `(focus-dir direction)`

Move focus to an adjacent window.

**Parameters:**
- `direction` - One of `DIR-LEFT`, `DIR-RIGHT`, `DIR-UP`, `DIR-DOWN`

**Examples:**
```scheme
(focus-dir DIR-LEFT)
(focus-dir DIR-DOWN)
```

---

### `(swap-dir direction)`

Swap the focused window with an adjacent window.

**Parameters:**
- `direction` - One of `DIR-LEFT`, `DIR-RIGHT`, `DIR-UP`, `DIR-DOWN`

**Examples:**
```scheme
(swap-dir DIR-RIGHT)
(swap-dir DIR-UP)
```

---

### `(toggle-floating)`

Toggle floating mode for the focused window. Floating windows are not tiled.

---

### `(toggle-fullscreen)`

Toggle fullscreen mode for the focused window.

---

### `(move-window)`

Enter window move mode. Use with mouse bindings.

---

### `(resize-window)`

Enter window resize mode. Use with mouse bindings.

---

### `(zoom)`

Swap the focused window with the master window.

---

### `(focus-stack n)`

Cycle focus through the window stack.

**Parameters:**
- `n` - `1` to focus next, `-1` to focus previous

---

### `(refresh)`

Force a refresh/redraw of all windows and frames.

---

## Tags / Virtual Desktops

TurboWM uses a tag system similar to dwm. Each window can have one or more tags, and you view windows by selecting tags.

### `(view-tag n)`

Switch to viewing tag n.

**Parameters:**
- `n` - Tag number (1-9)

**Examples:**
```scheme
(view-tag 1)  ; Switch to tag 1
(view-tag 5)  ; Switch to tag 5
```

---

### `(tag-window n)`

Move the focused window to tag n.

**Parameters:**
- `n` - Tag number (1-9)

**Examples:**
```scheme
(tag-window 2)  ; Send window to tag 2
```

---

### `(toggle-tag n)`

Toggle viewing of tag n (show windows from multiple tags).

**Parameters:**
- `n` - Tag number (1-9)

---

### `(toggle-window-tag n)`

Toggle tag n on the focused window (window visible on multiple tags).

**Parameters:**
- `n` - Tag number (1-9)

---

### `(view-all)`

View all windows regardless of tag.

---

### `(tag-all)`

Apply all tags to the focused window.

---

## Queries

These functions return information about the current state.

### `(focused-app-id)`

Returns the app_id of the focused window, or `#f` if none.

**Examples:**
```scheme
(focused-app-id)  ; => "foot" or "firefox" etc.
```

---

### `(focused-title)`

Returns the title of the focused window, or `#f` if none.

**Examples:**
```scheme
(focused-title)  ; => "vim - config.scm" etc.
```

---

### `(current-tag)`

Returns the currently viewed tag number.

**Examples:**
```scheme
(current-tag)  ; => 1
```

---

### `(window-count)`

Returns the number of visible windows on the current tag.

**Examples:**
```scheme
(window-count)  ; => 3
```

---

## Input Devices

### `(set-sloppy-focus enabled)`

Enable or disable focus-follows-mouse.

**Parameters:**
- `enabled` - `#t` to enable, `#f` to disable

**Examples:**
```scheme
(set-sloppy-focus #t)  ; Focus follows mouse
(set-sloppy-focus #f)  ; Click to focus
```

---

### `(set-repeat-rate rate delay)`

Set keyboard repeat rate.

**Parameters:**
- `rate` - Characters per second
- `delay` - Milliseconds before repeat starts

**Examples:**
```scheme
(set-repeat-rate 25 600)   ; Default
(set-repeat-rate 50 300)   ; Faster
```

---

### `(set-tap-to-click enabled)`

Enable or disable tap-to-click on touchpads.

**Parameters:**
- `enabled` - `#t` or `#f`

---

### `(set-natural-scrolling enabled)`

Enable or disable natural (reverse) scrolling.

**Parameters:**
- `enabled` - `#t` or `#f`

---

### `(set-accel-speed speed)`

Set mouse/touchpad acceleration.

**Parameters:**
- `speed` - Float from -1.0 (slowest) to 1.0 (fastest)

**Examples:**
```scheme
(set-accel-speed 0.0)   ; Default
(set-accel-speed -0.5)  ; Slower
(set-accel-speed 0.5)   ; Faster
```

---

## Window Rules

Apply rules to windows based on their app_id or title.

### `(add-rule app-id title tags floating monitor)`

Add a rule for matching windows.

**Parameters:**
- `app-id` - App ID to match (string, or `""` for any)
- `title` - Title to match (string, or `""` for any)
- `tags` - Tag bitmask (e.g., `1` for tag 1, `2` for tag 2, `4` for tag 3)
- `floating` - `1` for floating, `0` for tiled, `-1` for default
- `monitor` - Monitor index, or `-1` for default

**Examples:**
```scheme
;; Firefox always on tag 2
(add-rule "firefox" "" 2 0 -1)

;; Floating calculator
(add-rule "gnome-calculator" "" 0 1 -1)

;; Any window with "Picture-in-Picture" in title floats
(add-rule "" "Picture-in-Picture" 0 1 -1)
```

---

### `(clear-rules)`

Remove all window rules.

---

## System

### `(on-startup cmd1 cmd2 ...)`

Register commands to run when the compositor starts. These run once after initialization completes.

**Parameters:**
- `cmd1, cmd2, ...` - Command strings to spawn

**Examples:**
```scheme
(on-startup "waybar" "mako" "foot --server")
(on-startup "~/.config/tbwm/autostart.sh")
```

**Note:** Commands are spawned via `/bin/sh -c`, so shell features work.

---

### `(toggle-launcher)`

Open/close the built-in application launcher.

---

### `(toggle-repl)`

Open/close the Scheme REPL overlay. Press `Super+;` by default.

---

### `(reload-config)`

Reload `~/.config/tbwm/config.scm`.

---

### `(quit)`

Exit TurboWM.

---

### `(chvt n)`

Switch to virtual terminal n (Linux console switching).

**Parameters:**
- `n` - VT number (1-12)

**Examples:**
```scheme
(chvt 2)  ; Switch to TTY2
```

---

### `(log message)`

Print a message to the REPL/log.

**Parameters:**
- `message` - String to log

---

### `(help)`

Display available commands in the REPL.

---

### `(eval-string code)`

Evaluate a string as Scheme code.

**Parameters:**
- `code` - Scheme code as a string

**Examples:**
```scheme
(eval-string "(+ 1 2)")  ; => 3
```

---

### `(set-repl-log-level n)`

Set the minimum log level shown in the REPL.

**Parameters:**
- `n` - `0`=DEBUG, `1`=INFO, `2`=WARN, `3`=ERROR

---

## Constants

These constants are predefined for use with direction functions:

| Constant | Value | Description |
|----------|-------|-------------|
| `DIR-LEFT` | 0 | Left direction |
| `DIR-RIGHT` | 1 | Right direction |
| `DIR-UP` | 2 | Up direction |
| `DIR-DOWN` | 3 | Down direction |
| `MON-LEFT` | - | Previous monitor |
| `MON-RIGHT` | - | Next monitor |

---

## Layout Functions

### `(set-layout name)`

Set the current layout.

**Parameters:**
- `name` - Layout name: `"tile"`, `"monocle"`, `"grid"`, `"float"`

---

### `(cycle-layout)`

Cycle to the next layout.

---

### `(inc-mfact delta)`

Adjust the master area size.

**Parameters:**
- `delta` - Float, e.g., `0.05` or `-0.05`

---

### `(inc-nmaster delta)`

Adjust the number of master windows.

**Parameters:**
- `delta` - Integer, e.g., `1` or `-1`

---

## Monitor Functions

### `(focus-monitor direction)`

Focus an adjacent monitor.

**Parameters:**
- `direction` - `MON-LEFT` or `MON-RIGHT`

---

### `(tag-monitor direction)`

Send focused window to adjacent monitor.

**Parameters:**
- `direction` - `MON-LEFT` or `MON-RIGHT`

---

## Example Configurations

### Minimal Config

```scheme
;; Minimal TurboWM config
(set-background-color "#ff000000")
(set-border-line-color "#ff444444")
(set-tag-count 4)
(set-show-date #f)

(bind-key "M-Return" (lambda () (spawn "foot")))
(bind-key "M-q" (lambda () (kill-client)))
(bind-key "M-S-e" (lambda () (quit)))

(bind-key "M-1" (lambda () (view-tag 1)))
(bind-key "M-2" (lambda () (view-tag 2)))
(bind-key "M-3" (lambda () (view-tag 3)))
(bind-key "M-4" (lambda () (view-tag 4)))
```

### Nord Theme

```scheme
;; Nord color scheme
(set-background-color "#ff2e3440")
(set-border-line-color "#ff88c0d0")
```

### Dracula Theme

```scheme
;; Dracula color scheme
(set-background-color "#ff282a36")
(set-border-line-color "#ffbd93f9")
```

### Dynamic Status Script

```scheme
;; Update status every minute from a script
;; Put this in a cron job or systemd timer:
;; tbwm-status.sh:
;;   echo "(set-status-text \"$(date +%H:%M) | $(cat /sys/class/power_supply/BAT0/capacity)%\")" | socat - UNIX-CONNECT:/tmp/tbwm.sock

;; Or call directly in config for static info:
(set-status-text "TurboWM")
```

---

## Debugging

Debug log is written to `/tmp/tbwm-debug.log`. Check it for binding issues or errors.

Open the REPL with `Super+;` to interactively test commands.
