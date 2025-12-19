# configuration

how to configure tbwm

## the file

config lives at ~/.config/tbwm/config.scm

its scheme code. gets created with defaults on first run

## reload

super+shift+c to reload without restarting. or:
```scheme
(reload-config)
```

## colors

all #RRGGBB format:
```scheme
(set-bg-color "#000000")        ; background/repl
(set-bg-text-color "#888888")   ; repl text
(set-bar-color "#0000aa")       ; status bar bg
(set-bar-text-color "#aaaaaa")  ; status bar text
(set-border-color "#0000aa")    ; window frame bg
(set-border-line-color "#aaaaaa") ; box drawing chars
```

## keybindings

modifiers: M = super, S = shift, C = ctrl, A = alt

```scheme
(bind-key "M-Return" (lambda () (spawn "foot")))
(bind-key "M-S-q" (lambda () (quit)))
```

key names: a-z, 0-9, F1-F12, Return, space, Tab, Escape, Left/Right/Up/Down, etc

## mouse bindings

```scheme
(bind-mouse "M-button1" (lambda () (move-window)))
(bind-mouse "M-button3" (lambda () (resize-window)))
```

## startup

run stuff when compositor starts:
```scheme
(on-startup "waybar" "mako" "foot --server")
```

## window rules

```scheme
;; (add-rule "app-id" "title" tags floating monitor)
(add-rule "firefox" "" 2 0 -1)   ; firefox on tag 2
(add-rule "mpv" "" 0 1 -1)       ; mpv floating
```

find app-id with (focused-app-id) in the repl

## input

```scheme
(set-repeat-rate 25 600)     ; chars/sec, delay ms
(set-tap-to-click #t)
(set-natural-scrolling #f)
(set-accel-speed 0.0)        ; -1.0 to 1.0
```

## status bar

```scheme
(set-show-date #t)
(set-show-time #t)
(set-status-text "custom text")  ; replaces date/time
(set-tag-count 9)
```

## the repl

super+; opens it. try stuff:
```scheme
(focused-app-id)
(focused-title)
(spawn "foot")
(set-border-color "#ff0000")
(help)
```

## split config

```scheme
(load "~/.config/tbwm/colors.scm")
(load "~/.config/tbwm/keys.scm")
```

## dynamic stuff

```scheme
;; time based theme
(define hour (string->number (system "date +%H")))
(if (> hour 19)
    (set-bg-color "#1a1a2e")
    (set-bg-color "#f0f0f0"))
```

## sync external configs

```scheme
;; write foot config with your colors
(let* ((home (getenv "HOME"))
       (conf (string-append home "/.config/foot/foot.ini")))
  (system (string-append "mkdir -p " home "/.config/foot"))
  (call-with-output-file conf
    (lambda (p)
      (display "[colors]\nbackground=000000\nforeground=aaaaaa\n" p))))
```

## debugging

check the log:
```bash
tail -f /tmp/tbwm-debug.log
```

test in repl with super+;
