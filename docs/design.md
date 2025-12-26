# design philosophy

## aesthetics

### VGA/TurboC/TempleOS style

tbwm is a love letter to the DOS era. the visual style draws from:

**TurboC IDE** - borland's classic C IDE with its blue backgrounds and grey box-drawing menus

**TempleOS** - terry davis's OS with its character-cell based graphics and 8x16 fonts

**VGA text mode** - the 80x25 (or 80x50) text modes of DOS with CP437 character set

### character cell grid

everything in tbwm aligns to an 8×16 pixel grid:

```
┌────────────────────────────────────────┐
│ each cell is 8 pixels wide             │
│ and 16 pixels tall                     │
│                                        │
│ window positions snap to cell          │
│ boundaries                             │
│                                        │
│ borders are exactly 1 cell wide        │
│ (8px on sides, 16px on top/bottom)     │
└────────────────────────────────────────┘
```

### visual elements

window frames use Unicode box-drawing characters:
- corners: ╔ ╗ ╚ ╝
- lines: ═ (horizontal) ║ (vertical)
- junctions: ╠ ╣ ╦ ╩ ╬

title bars show:
```
╔═ window title ══════════════════[F]═[X]═╗
```

default colors:
- frame background: #0000aa (blue)
- box-drawing lines: #aaaaaa (grey)
- focused window: title inverted (grey bg, blue text)

## performance

### target hardware

tbwm is designed for low-end systems:
- 1GB RAM
- Intel Atom or similar CPU
- integrated graphics

this means:
- **no compositor effects** - no blur, shadows, animations
- **no anti-aliasing** - bitmap font, pixel-perfect rendering
- **minimal allocations** - reuse buffers, cache everything

### optimization strategies

**glyph caching**: pre-rendered glyphs stored in `glyph_cache[]` array (512 entries). avoid calling FreeType every frame.

**buffer reuse**: `TitleBuffer` structs are cached per-window and only reallocated on resize. same for the status bar.

**frame culling**: skip rendering borders that are shared with neighbors (the neighbor draws the shared edge).

**lazy updates**: only redraw what changed. bar updates on a timer, window frames only on resize/focus change.

### memory budgets

```
MAX_APPS = 512          # app launcher entries
MAX_CATEGORIES = 32     # app menu categories
MAX_RULES = 64          # window rules
MAX_STARTUP_CMDS = 32   # startup commands
GLYPH_CACHE_SIZE = 512  # cached glyphs
```

these are compile-time limits. no unbounded allocations.

## scheme configuration

### principle

**everything should be configurable via scheme**, as long as it doesn't:

1. **increase memory significantly** - no dynamic arrays that grow forever
2. **add per-frame CPU cost** - computed values must be cached
3. **break the grid** - window positions/sizes stay cell-aligned
4. **need non-VGA characters** - font is limited

### safe to customize

- all colors (apply instantly)
- keybindings (hash table lookup)
- mouse bindings (small array)
- window rules (bounded array)
- status bar text (cached on change)
- layout parameters (mfact, nmaster)

### not currently customizable

these would need careful implementation:

- cell dimensions (8x16 is hardcoded, changing would need full re-render)
- number of compositor layers (scene graph structure)
- box-drawing character set (assumes Unicode double-line)

## font

### PxPlus_IBM_VGA_8x16.ttf

this is a bitmap font recreation of the IBM VGA ROM font. it's:
- fixed-width 8x16 pixels
- includes CP437 box-drawing characters
- no hinting needed (pixel-perfect at native size)

### supported characters

- ASCII 0x20-0x7E (standard printable)
- box-drawing: ─│┌┐└┘├┤┬┴┼ and doubled variants
- block elements: ░▒▓█
- some extended Latin

### unsupported

- emoji
- CJK characters
- most Unicode beyond Latin-1

trying to render unsupported characters shows the replacement glyph or blank.
