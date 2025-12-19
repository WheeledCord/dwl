# TurboWM Documentation

Welcome to TurboWM, a Wayland compositor with a retro TUI aesthetic and powerful Scheme scripting.

## Getting Started

- [Configuration Guide](configuration.md) - How to configure TurboWM
- [Default Keybindings](keybindings.md) - Quick reference for all keys
- [Scheme API Reference](scheme-api.md) - Complete function documentation

## Overview

TurboWM is a tiling Wayland compositor that:

- Uses box-drawing characters for window borders (╔═╗║╚╝)
- Embeds s7 Scheme for powerful, live-reloadable configuration
- Includes a built-in REPL for interactive scripting
- Features a retro VGA-style aesthetic

## Quick Start

1. **Launch TurboWM** - Start from a TTY or display manager
2. **Open a terminal** - Press `Super + Return`
3. **Open the REPL** - Press `Super + ;` to experiment
4. **Configure** - Edit `~/.config/tbwm/config.scm`
5. **Reload** - Press `Super + Shift + C` to apply changes

## Configuration

All configuration is done through `~/.config/tbwm/config.scm` using Scheme.

```scheme
;; Change colors
(set-background-color "#ff0000aa")  ; Blue background
(set-border-line-color "#ffaaaaaa") ; Grey borders

;; Customize bindings
(bind-key "M-Return" (lambda () (spawn "foot")))
```

See the [Configuration Guide](configuration.md) for details.

## Files

| Path | Description |
|------|-------------|
| `~/.config/tbwm/config.scm` | Your configuration |
| `/tmp/tbwm-debug.log` | Debug log |

## Architecture

TurboWM is built on:

- **wlroots** - Wayland compositor library
- **s7 Scheme** - Embedded scripting language
- **FreeType** - Font rendering for the grid

## Source

TurboWM is based on dwl (dynamic window manager for Wayland).
