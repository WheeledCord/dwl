# AGENTS.md - dwl grid compositor

## Build Commands
```bash
make          # Build
make clean    # Clean build artifacts
```

## Test
```bash
# From TTY:
~/test-dwl.sh

# Nested in Sway (for development):
./dwl -s foot
```

## Architecture

### Grid System
- Cell dimensions derived from `/home/fionn/PxPlus_IBM_VGA_8x16.ttf`
- Default: 8x16 pixels per character cell
- All window geometry snaps to cell boundaries

### Scheme Configuration (s7)
- Config file: `~/.config/dwl/config.scm`
- s7 Scheme interpreter embedded (s7.c, s7.h)
- Keybindings defined via `(bind-key "M-key" callback)`
- Functions exposed: spawn, quit, focus-dir, view-tag, etc.
- Config auto-generated if missing

### Key Modifications from stock dwl
1. **dwl.c**: Added FreeType font loading, grid snapping, s7 Scheme integration
2. **config.h**: Added `grid_font_path` and `grid_font_size` settings
3. **Makefile**: Added `pangocairo freetype2` to PKGS, s7.o to build
4. **s7.c/s7.h**: Embedded Scheme interpreter

### Window Structure
- Title bar: 1 cell tall, rendered with FreeType
- Content area: Offset by title bar height
- Borders: Standard dwl borders (configurable)

### Default Keybindings (from config.scm)
- `Super+Return` - Terminal (foot)
- `Super+d` - Launcher
- `Super+q` - Close window
- `Super+Shift+E` - Quit
- `Super+hjkl` - Focus direction
- `Super+Shift+hjkl` - Swap windows
- `Super+f` - Fullscreen
- `Super+1-9` - Tags
- `Super+Shift+C` - Reload config
