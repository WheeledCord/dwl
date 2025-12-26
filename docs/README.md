# tbwm docs

documentation for turbowm

## files

- [scheme-api.md](scheme-api.md) - all the scheme functions
- [configuration.md](configuration.md) - how to configure stuff
- [keybindings.md](keybindings.md) - default keys
- [design.md](design.md) - design philosophy and aesthetics

## design philosophy

### VGA/TurboC/TempleOS aesthetic

tbwm is styled after the classic DOS/VGA era:
- **TurboC IDE**: blue window frames, grey box-drawing characters
- **TempleOS**: character-cell based UI, 8x16 bitmap fonts
- **VGA text mode**: limited to the characters available in CP437

the entire UI is based on an 8×16 pixel character cell grid. everything snaps to this grid.

### low-end hardware target

designed for 1GB RAM / Intel Atom class machines:
- no compositor effects, shadows, or anti-aliasing
- glyph caching to avoid repeated font rendering
- buffer reuse to minimize allocations
- minimal per-frame work

### font constraints

uses PxPlus_IBM_VGA_8x16.ttf - a fixed-width bitmap VGA font.

available characters:
- box-drawing: ═║╔╗╚╝╠╣╦╩╬
- ASCII printable (0x20-0x7E)
- some extended Latin

**no emoji, CJK, or fancy Unicode** - they won't render correctly.

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

built on wlroots with s7 scheme embedded for config. based on dwl.

everything is configurable via scheme as long as it doesn't:
- increase memory usage significantly
- add per-frame CPU overhead
- break the character-cell grid alignment
- require fonts with characters not in VGA charset
