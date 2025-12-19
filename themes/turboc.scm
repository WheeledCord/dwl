;;; TurboWM Theme: TurboC
;;; very blue
;;;
;;; Usage: Copy to ~/.config/tbwm/config.scm or load with:
;;;   (load "/path/to/themes/turboc.scm")

;;;; ==================== APPEARANCE ====================

;; Background/REPL color (background)
(set-bg-color "#0000aa")

;; Background/REPL text color (foreground)
(set-bg-text-color "#ffffff")

;; Status bar background (current line)
(set-bar-color "#aaaaaa")

;; Status bar text color (foreground)
(set-bar-text-color "#0000aa")

;; Window border background/highlight
(set-border-color "#0000aa")

;; Box-drawing border lines
(set-border-line-color "#ffffff")

;; Number of virtual desktops/tags (1-9)
(set-tag-count 9)

;;;; ==================== STARTUP COMMANDS ====================

;; Commands to run when the compositor starts
;; Uncomment and customize as needed:
;; (on-startup "waybar" "mako" "foot --server")

;;;; ==================== STATUS BAR ====================

;; Show date and time in status bar
(set-show-date #t)
(set-show-time #t)

;; Title bar scrolling for long titles
(set-title-scroll-mode 1)   ; 1 = scroll, 0 = truncate with ...
(set-title-scroll-speed 30) ; pixels per second

;;;; ==================== BEHAVIOR ====================

;; Focus follows mouse (sloppy focus)
(set-sloppy-focus #t)

;; Keyboard repeat rate and delay (chars/sec, ms before repeat)
(set-repeat-rate 25 600)

;;;; ==================== INPUT DEVICES ====================

;; Trackpad settings
(set-tap-to-click #t)
(set-natural-scrolling #f)
(set-accel-speed 0.0)  ; -1.0 to 1.0

;;;; ==================== MOUSE BINDINGS ====================

(bind-mouse "M-button1" (lambda () (move-window)))
(bind-mouse "M-button3" (lambda () (resize-window)))

;;;; ==================== KEYBINDINGS ====================

;; Terminal
(bind-key "M-Return" (lambda () (spawn "foot")))

;; Launcher
(bind-key "M-d" (lambda () (toggle-launcher)))

;; Close window
(bind-key "M-q" (lambda () (kill-client)))

;; Quit TurboWM
(bind-key "M-S-e" (lambda () (quit)))

;; Focus direction (vim keys)
(bind-key "M-h" (lambda () (focus-dir DIR-LEFT)))
(bind-key "M-j" (lambda () (focus-dir DIR-DOWN)))
(bind-key "M-k" (lambda () (focus-dir DIR-UP)))
(bind-key "M-l" (lambda () (focus-dir DIR-RIGHT)))

;; Focus direction (arrow keys)
(bind-key "M-Left" (lambda () (focus-dir DIR-LEFT)))
(bind-key "M-Down" (lambda () (focus-dir DIR-DOWN)))
(bind-key "M-Up" (lambda () (focus-dir DIR-UP)))
(bind-key "M-Right" (lambda () (focus-dir DIR-RIGHT)))

;; Swap windows (vim keys)
(bind-key "M-S-h" (lambda () (swap-dir DIR-LEFT)))
(bind-key "M-S-j" (lambda () (swap-dir DIR-DOWN)))
(bind-key "M-S-k" (lambda () (swap-dir DIR-UP)))
(bind-key "M-S-l" (lambda () (swap-dir DIR-RIGHT)))
(bind-key "M-S-Left" (lambda () (swap-dir DIR-LEFT)))
(bind-key "M-S-Down" (lambda () (swap-dir DIR-DOWN)))
(bind-key "M-S-Up" (lambda () (swap-dir DIR-UP)))
(bind-key "M-S-Right" (lambda () (swap-dir DIR-RIGHT)))

;; Fullscreen and floating
(bind-key "M-f" (lambda () (toggle-fullscreen)))
(bind-key "M-S-space" (lambda () (toggle-floating)))

;; Tags 1-9
(bind-key "M-1" (lambda () (view-tag 1)))
(bind-key "M-2" (lambda () (view-tag 2)))
(bind-key "M-3" (lambda () (view-tag 3)))
(bind-key "M-4" (lambda () (view-tag 4)))
(bind-key "M-5" (lambda () (view-tag 5)))
(bind-key "M-6" (lambda () (view-tag 6)))
(bind-key "M-7" (lambda () (view-tag 7)))
(bind-key "M-8" (lambda () (view-tag 8)))
(bind-key "M-9" (lambda () (view-tag 9)))

;; Move window to tag
(bind-key "M-S-exclam" (lambda () (tag-window 1)))
(bind-key "M-S-at" (lambda () (tag-window 2)))
(bind-key "M-S-numbersign" (lambda () (tag-window 3)))
(bind-key "M-S-dollar" (lambda () (tag-window 4)))
(bind-key "M-S-percent" (lambda () (tag-window 5)))
(bind-key "M-S-asciicircum" (lambda () (tag-window 6)))
(bind-key "M-S-ampersand" (lambda () (tag-window 7)))
(bind-key "M-S-asterisk" (lambda () (tag-window 8)))
(bind-key "M-S-parenleft" (lambda () (tag-window 9)))

;; Refresh layout
(bind-key "M-S-r" (lambda () (refresh)))

;; Reload config (hot reload!)
(bind-key "M-S-c" (lambda () (reload-config) (log "Config reloaded!")))

;; REPL - Scheme console on the desktop
(bind-key "M-S-colon" (lambda () (toggle-repl)))

;; TTY switching (Ctrl+Alt+F1-F12)
(bind-key "C-A-F1" (lambda () (chvt 1)))
(bind-key "C-A-F2" (lambda () (chvt 2)))
(bind-key "C-A-F3" (lambda () (chvt 3)))
(bind-key "C-A-F4" (lambda () (chvt 4)))
(bind-key "C-A-F5" (lambda () (chvt 5)))
(bind-key "C-A-F6" (lambda () (chvt 6)))
(bind-key "C-A-F7" (lambda () (chvt 7)))
(bind-key "C-A-F8" (lambda () (chvt 8)))
(bind-key "C-A-F9" (lambda () (chvt 9)))
(bind-key "C-A-F10" (lambda () (chvt 10)))
(bind-key "C-A-F11" (lambda () (chvt 11)))
(bind-key "C-A-F12" (lambda () (chvt 12)))
