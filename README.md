# dotfiles-quickshell

Quickshell desktop shell for Hyprland — bar, popups, notifications, widgets.
Replaces `waybar`, `rofi`, `dunst` and `eww`.

Part of the [dotfiles-arch](https://github.com/SaratAngajalaoffl/dotfiles-arch) multi-repo dotfiles system.

## Layout

- `config` → `~/.config/quickshell` (see `.links`)
- `config/shell.qml` — entrypoint
- `config/theme/` — `Colors`, `Metrics`, `Theme` singletons
- `config/services/` — one singleton per subsystem (notifications, audio, …)
- `config/components/` — reusable QML (popup slide, cards, toggles)
- `config/shapes/` — Canvas shapes (notch bar, screen frame)
- `config/windows/` — `TopBar`, `Frame`, `PopupDismiss`
- `config/modules/` — bar notch content, split `Left`/`Center`/`Right`
- `config/popups/` — one file per popup; only `PopupLayer.qml` instantiates them

## Running

```bash
qs -c quickshell          # named config under ~/.config/quickshell
qs -c quickshell -d       # daemonized
```

Started by Hyprland's autostart. Reload after edits with `qs -c quickshell` or
via IPC once wired up.

## Theming

Colours come from the active theme in `dotfiles-theme`, read at runtime from
`~/.config/theme/current/quickshell-colors.json`. Switching themes with
`theme-set.sh` recolours the shell live — no restart.

The palette uses Catppuccin's 26 key names, which is what every other themed
app in this dotfiles system already speaks.

## Setup

Not used standalone — applied by the parent repo's `install.sh`, which reads
`.links` and symlinks `config` into place.
