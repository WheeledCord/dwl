# tbwm docs

documentation for turbowm

## files

- [scheme-api.md](scheme-api.md) - all the scheme functions
- [configuration.md](configuration.md) - how to configure stuff
- [keybindings.md](keybindings.md) - default keys

## quick start

config lives at ~/.config/tbwm/config.scm

its just scheme code that runs on startup. press super+shift+c to reload it without restarting

open the repl with super+; to mess around

## the basics

colors are #RRGGBB format:
```scheme
(set-bg-color "#000000")
(set-border-color "#0000aa")
```

keybindings use lambdas:
```scheme
(bind-key "M-Return" (lambda () (spawn "foot")))
```

M = super, S = shift, C = ctrl, A = alt

## architecture

built on wlroots with s7 scheme embedded for config. based on dwl
