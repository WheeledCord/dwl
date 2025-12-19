# TurboWM Configuration Guide

This guide covers how to configure TurboWM through its Scheme-based configuration system.

## Quick Links

- [Scheme API Reference](scheme-api.md) - Complete function reference
- [Example Configs](examples/) - Ready-to-use configurations

## Configuration File

Your configuration lives at:

```
~/.config/tbwm/config.scm
```

On first run, TurboWM creates this file with sensible defaults.

## How It Works

TurboWM embeds [s7 Scheme](https://ccrma.stanford.edu/software/snd/snd/s7.html), a lightweight, full-featured Scheme implementation. Your config file is simply Scheme code that runs at startup.

### Why Scheme?

1. **Live Reloading** - Press `Super+Shift+C` or call `(reload-config)` to apply changes without restarting
2. **Full Programming Language** - Conditionals, loops, functions, not just key=value
3. **Runtime REPL** - Press `Super+;` to open an interactive Scheme prompt
4. **Scriptable** - Query window state, react to events, create complex behaviors

## The Basics

### Comments

```scheme
; This is a comment
;; So is this
;;; Convention: more semicolons = more important
```

### Booleans

```scheme
#t  ; true
#f  ; false
```

### Colors

Colors use `#RRGGBB` format:

```scheme
"#0000aa"  ; Blue
"#ff0000"  ; Red  
"#ffffff"  ; White
"#2e3440"  ; Nord dark
```

### Lambdas (Anonymous Functions)

Most bindings use lambdas:

```scheme
(bind-key "M-Return" (lambda () (spawn "foot")))
```

The `(lambda () ...)` creates a function that takes no arguments.

## Modular Config

Split your config into multiple files:

```scheme
;; In config.scm
(load "~/.config/tbwm/colors.scm")
(load "~/.config/tbwm/keys.scm")
(load "~/.config/tbwm/rules.scm")
```

## Dynamic Configuration

### Conditional Based on Hostname

```scheme
(define hostname (system "hostname"))

(if (string=? hostname "laptop")
    (begin
      (set-tag-count 4)
      (set-show-date #f))
    (begin
      (set-tag-count 9)
      (set-show-date #t)))
```

### Time-Based Themes

```scheme
(define hour (string->number (system "date +%H")))

(if (or (< hour 7) (> hour 19))
    ;; Night theme
    (begin
      (set-bg-color "#1a1a2e")
      (set-border-color "#2a2a4e")
      (set-border-line-color "#4a4a6a"))
    ;; Day theme
    (begin
      (set-bg-color "#f0f0f0")
      (set-border-color "#4a90d9")
      (set-border-line-color "#333333")))
```

## The REPL

Press `Super+;` to open the built-in REPL (Read-Eval-Print Loop).

### What You Can Do

```scheme
;; Check focused window
(focused-app-id)    ; => "firefox"
(focused-title)     ; => "GitHub - Mozilla Firefox"

;; Change things live
(set-border-color "#00ff00")  ; Instant green borders!

;; Spawn programs
(spawn "foot -e htop")

;; Move windows
(swap-dir DIR-RIGHT)

;; Get help
(help)
```

### REPL Tips

- Use arrow keys for history
- Press Escape to close
- Output appears in the REPL area
- Errors are shown in red

## Keybinding Conventions

### Modifiers

| Key | Meaning |
|-----|---------|
| `M` | Super (Windows key) |
| `S` | Shift |
| `C` | Control |
| `A` | Alt |

### Examples

```scheme
"M-Return"      ; Super + Enter
"M-S-q"         ; Super + Shift + Q
"C-A-Delete"    ; Ctrl + Alt + Delete
"M-1"           ; Super + 1
"M-Left"        ; Super + Left Arrow
```

### Common Key Names

- Letters: `a` through `z`
- Numbers: `0` through `9`
- Function keys: `F1` through `F12`
- Arrows: `Left`, `Right`, `Up`, `Down`
- Special: `Return`, `space`, `Tab`, `Escape`, `BackSpace`, `Delete`
- Others: `Home`, `End`, `Page_Up`, `Page_Down`, `Insert`

## Startup Commands

Run programs when the compositor starts:

```scheme
;; Single command
(on-startup "waybar")

;; Multiple commands
(on-startup "waybar" "mako" "foot --server")

;; Or use a shell script
(on-startup "~/.config/tbwm/autostart.sh")
```

Commands are spawned after the compositor is fully initialized, so they can connect immediately.

## Window Rules

Match windows by app_id (Wayland) or title:

```scheme
;; Firefox always on tag 2
(add-rule "firefox" "" 2 0 -1)

;; Floating video players
(add-rule "mpv" "" 0 1 -1)
(add-rule "" "Picture-in-Picture" 0 1 -1)

;; Games on tag 9, floating
(add-rule "steam_app" "" 256 1 -1)  ; 256 = 2^8 = tag 9
```

### Finding App IDs

Open the REPL and focus the window, then:

```scheme
(focused-app-id)
```

## Complete Example Config

```scheme
;;; TurboWM Configuration
;;; ~/.config/tbwm/config.scm

;;;; ==================== APPEARANCE ====================

(set-bg-color "#000000")
(set-bg-text-color "#888888")
(set-border-color "#0000aa")
(set-border-line-color "#aaaaaa")
(set-tag-count 9)

;;;; ==================== STARTUP ====================

(on-startup "waybar" "mako")

;;;; ==================== STATUS BAR ====================

(set-show-date #t)
(set-show-time #t)
(set-title-scroll-mode 1)
(set-title-scroll-speed 30)

;;;; ==================== BEHAVIOR ====================

(set-sloppy-focus #t)
(set-repeat-rate 25 600)

;;;; ==================== INPUT ====================

(set-tap-to-click #t)
(set-natural-scrolling #f)
(set-accel-speed 0.0)

;;;; ==================== MOUSE ====================

(bind-mouse "M-button1" (lambda () (move-window)))
(bind-mouse "M-button3" (lambda () (resize-window)))

;;;; ==================== KEYBINDINGS ====================

;; Applications
(bind-key "M-Return" (lambda () (spawn "foot")))
(bind-key "M-d" (lambda () (toggle-launcher)))
(bind-key "M-semicolon" (lambda () (toggle-repl)))

;; Window management
(bind-key "M-q" (lambda () (kill-client)))
(bind-key "M-f" (lambda () (toggle-fullscreen)))
(bind-key "M-S-space" (lambda () (toggle-floating)))

;; Focus (vim keys)
(bind-key "M-h" (lambda () (focus-dir DIR-LEFT)))
(bind-key "M-j" (lambda () (focus-dir DIR-DOWN)))
(bind-key "M-k" (lambda () (focus-dir DIR-UP)))
(bind-key "M-l" (lambda () (focus-dir DIR-RIGHT)))

;; Focus (arrows)
(bind-key "M-Left" (lambda () (focus-dir DIR-LEFT)))
(bind-key "M-Down" (lambda () (focus-dir DIR-DOWN)))
(bind-key "M-Up" (lambda () (focus-dir DIR-UP)))
(bind-key "M-Right" (lambda () (focus-dir DIR-RIGHT)))

;; Swap (vim keys)
(bind-key "M-S-h" (lambda () (swap-dir DIR-LEFT)))
(bind-key "M-S-j" (lambda () (swap-dir DIR-DOWN)))
(bind-key "M-S-k" (lambda () (swap-dir DIR-UP)))
(bind-key "M-S-l" (lambda () (swap-dir DIR-RIGHT)))

;; Swap (arrows)
(bind-key "M-S-Left" (lambda () (swap-dir DIR-LEFT)))
(bind-key "M-S-Down" (lambda () (swap-dir DIR-DOWN)))
(bind-key "M-S-Up" (lambda () (swap-dir DIR-UP)))
(bind-key "M-S-Right" (lambda () (swap-dir DIR-RIGHT)))

;; Tags
(bind-key "M-1" (lambda () (view-tag 1)))
(bind-key "M-2" (lambda () (view-tag 2)))
(bind-key "M-3" (lambda () (view-tag 3)))
(bind-key "M-4" (lambda () (view-tag 4)))
(bind-key "M-5" (lambda () (view-tag 5)))
(bind-key "M-6" (lambda () (view-tag 6)))
(bind-key "M-7" (lambda () (view-tag 7)))
(bind-key "M-8" (lambda () (view-tag 8)))
(bind-key "M-9" (lambda () (view-tag 9)))

(bind-key "M-S-1" (lambda () (tag-window 1)))
(bind-key "M-S-2" (lambda () (tag-window 2)))
(bind-key "M-S-3" (lambda () (tag-window 3)))
(bind-key "M-S-4" (lambda () (tag-window 4)))
(bind-key "M-S-5" (lambda () (tag-window 5)))
(bind-key "M-S-6" (lambda () (tag-window 6)))
(bind-key "M-S-7" (lambda () (tag-window 7)))
(bind-key "M-S-8" (lambda () (tag-window 8)))
(bind-key "M-S-9" (lambda () (tag-window 9)))

;; System
(bind-key "M-S-c" (lambda () (reload-config)))
(bind-key "M-S-e" (lambda () (quit)))

;;;; ==================== WINDOW RULES ====================

;; (add-rule "app-id" "title" tags floating monitor)
;; tags: bitmask (1=tag1, 2=tag2, 4=tag3, etc.)
;; floating: 1=yes, 0=no, -1=default
;; monitor: index or -1 for default

(add-rule "firefox" "" 2 0 -1)
(add-rule "mpv" "" 0 1 -1)
```

## Debugging

### Check the Log

```bash
tail -f /tmp/tbwm-debug.log
```

### Test in REPL

Open with `Super+;` and try commands interactively.

### Common Issues

**Bindings not working:**
- Check modifier order: `M-S-x` not `S-M-x`
- Key names are case-sensitive for special keys
- Check the debug log for binding registration

**Colors not changing:**
- Include alpha: `#ff000000` not `#000000`
- Reload config after changes

**Window rules not applying:**
- Check app_id with `(focused-app-id)` in REPL
- Rules are checked in order; first match wins
