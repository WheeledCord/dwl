# scheme api

all the functions you can use in config.scm

## colors

```scheme
(set-bg-color "#RRGGBB")          ; background/repl
(set-bg-text-color "#RRGGBB")     ; repl text
(set-bar-color "#RRGGBB")         ; status bar bg
(set-bar-text-color "#RRGGBB")    ; status bar text
(set-border-color "#RRGGBB")      ; window frame bg
(set-border-line-color "#RRGGBB") ; box drawing chars
(set-menu-color "#RRGGBB")        ; app menu bg
(set-menu-text-color "#RRGGBB")   ; app menu text
```

## font

```scheme
(set-font "/path/to/font.ttf" 16)
```

## status bar

```scheme
(set-tag-count 9)           ; 1-9 tags
(set-show-date #t)          ; show/hide date
(set-show-time #t)          ; show/hide time
(set-status-text "text")    ; custom status (replaces date/time)
(set-title-scroll-mode 1)   ; 0=truncate, 1=scroll
(set-title-scroll-speed 30) ; pixels/sec
```

## keybindings

```scheme
(bind-key "M-Return" (lambda () (spawn "foot")))
(unbind-all)  ; clear all bindings
```

modifiers: M=super S=shift C=ctrl A=alt

## mouse

```scheme
(bind-mouse "M-button1" (lambda () (move-window)))
(bind-mouse "M-button3" (lambda () (resize-window)))
(clear-mouse-bindings)
```

## spawning

```scheme
(spawn "command")
(on-startup "cmd1" "cmd2" "cmd3")  ; run on start
```

## window control

```scheme
(kill-client)        ; close focused
(toggle-floating)    ; float/unfloat
(toggle-fullscreen)  ; fullscreen toggle
(move-window)        ; start mouse move
(resize-window)      ; start mouse resize
```

## focus

```scheme
(focus-dir DIR-LEFT)   ; also DIR-RIGHT, DIR-UP, DIR-DOWN
(focus-stack 1)        ; next in stack (-1 for prev)
```

## swap

```scheme
(swap-dir DIR-LEFT)    ; swap with neighbor
(zoom)                 ; swap with master
```

## tags

```scheme
(view-tag 1)           ; go to tag (1-9)
(tag-window 1)         ; move window to tag
(toggle-tag 1)         ; toggle tag visibility
(toggle-window-tag 1)  ; toggle window on tag
(view-all)             ; view all tags
(tag-all)              ; window on all tags
```

## layout

```scheme
(set-layout "tile")    ; tile/monocle/float
(cycle-layout)
(inc-mfact 0.05)       ; grow master area
(inc-mfact -0.05)      ; shrink it
(inc-nmaster 1)        ; more masters
(inc-nmaster -1)       ; fewer
```

## monitors

```scheme
(focus-monitor MON-RIGHT)  ; also MON-LEFT
(tag-monitor MON-RIGHT)    ; send window
```

## window rules

```scheme
;; (add-rule "app-id" "title" tags floating monitor)
(add-rule "firefox" "" 2 0 -1)
(add-rule "mpv" "" 0 1 -1)
(clear-rules)
```

## queries

```scheme
(focused-app-id)   ; => "firefox"
(focused-title)    ; => "page title"
(current-tag)      ; => 1
(window-count)     ; => 3
```

## system

```scheme
(toggle-launcher)
(toggle-repl)
(toggle-appmenu)            ; toggle app menu
(set-menu-button "X")       ; set menu button label (default "X")
(reload-config)
(quit)
(chvt 2)           ; switch to tty2
(log "message")
(help)
(eval-string "(+ 1 2)")
```

## input

```scheme
(set-sloppy-focus #t)       ; focus follows mouse
(set-repeat-rate 25 600)    ; rate, delay
(set-tap-to-click #t)
(set-natural-scrolling #f)
(set-accel-speed 0.0)       ; -1.0 to 1.0
(set-repl-log-level 1)      ; 0=debug 1=info 2=warn 3=error
```

## constants

```
DIR-LEFT DIR-RIGHT DIR-UP DIR-DOWN
MON-LEFT MON-RIGHT
```
