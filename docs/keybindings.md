# TurboWM Default Keybindings

Quick reference for all default keybindings.

## Applications

| Keys | Action |
|------|--------|
| `Super + Return` | Open terminal (foot) |
| `Super + D` | Open launcher |
| `Super + ;` | Toggle REPL |

## Window Management

| Keys | Action |
|------|--------|
| `Super + Q` | Close focused window |
| `Super + F` | Toggle fullscreen |
| `Super + Shift + Space` | Toggle floating |

## Focus (Vim Keys)

| Keys | Action |
|------|--------|
| `Super + H` | Focus left |
| `Super + J` | Focus down |
| `Super + K` | Focus up |
| `Super + L` | Focus right |

## Focus (Arrow Keys)

| Keys | Action |
|------|--------|
| `Super + ←` | Focus left |
| `Super + ↓` | Focus down |
| `Super + ↑` | Focus up |
| `Super + →` | Focus right |

## Swap Windows (Vim Keys)

| Keys | Action |
|------|--------|
| `Super + Shift + H` | Swap left |
| `Super + Shift + J` | Swap down |
| `Super + Shift + K` | Swap up |
| `Super + Shift + L` | Swap right |

## Swap Windows (Arrow Keys)

| Keys | Action |
|------|--------|
| `Super + Shift + ←` | Swap left |
| `Super + Shift + ↓` | Swap down |
| `Super + Shift + ↑` | Swap up |
| `Super + Shift + →` | Swap right |

## Tags (Virtual Desktops)

| Keys | Action |
|------|--------|
| `Super + 1-9` | View tag 1-9 |
| `Super + Shift + 1-9` | Move window to tag 1-9 |
| `Super + Ctrl + 1-9` | Toggle tag visibility |
| `Super + Ctrl + Shift + 1-9` | Toggle window on tag |
| `Super + 0` | View all tags |
| `Super + Shift + 0` | Window on all tags |

## Monitor Control

| Keys | Action |
|------|--------|
| `Super + Period` | Focus next monitor |
| `Super + Comma` | Focus previous monitor |
| `Super + Shift + Period` | Send window to next monitor |
| `Super + Shift + Comma` | Send window to previous monitor |

## Layout

| Keys | Action |
|------|--------|
| `Super + Space` | Cycle layout |
| `Super + [` | Decrease master width |
| `Super + ]` | Increase master width |
| `Super + I` | Increase master count |
| `Super + O` | Decrease master count |

## System

| Keys | Action |
|------|--------|
| `Super + Shift + C` | Reload config |
| `Super + Shift + E` | Quit TurboWM |
| `Ctrl + Alt + F1-F12` | Switch to TTY |

## Mouse

| Mouse | Action |
|-------|--------|
| `Super + Left Click` | Move window |
| `Super + Right Click` | Resize window |

---

All keybindings can be customized in `~/.config/tbwm/config.scm`.

See [Scheme API Reference](scheme-api.md) for details.
