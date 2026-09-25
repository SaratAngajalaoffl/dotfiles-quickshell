// IPC surface: `qs ipc call theme reload`, etc.
//
// Needed because theme-set.sh replaces the `~/.config/theme/current` symlink
// rather than editing the palette file in place. FileView watches the resolved
// inode, so repointing the symlink fires no change event and the shell would
// never repaint. theme-set.sh calls this after switching, which forces a
// re-read.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../state"
import "../services"
import "../widgets"

QtObject {
    // Force the palette to be re-read from disk.
    function reloadTheme(): string {
        Colors.reloadTheme()
        return "theme reloaded"
    }

    function closeAllPopups(): string {
        ShellState.closeAll()
        return "closed"
    }

    function togglePopup(name: string): string {
        ShellState.toggle(name)
        return name
    }

    // One-stop "the desktop changed underneath you, catch up" call, used by
    // reload_all_services.sh (SUPER+SHIFT+R). Cheap operations only — it
    // re-reads the palette and re-lists the things services cache from disk.
    function reloadAll(): string {
        Colors.reloadTheme()
        WallpaperService.refresh()
        AppService.load()
        return "reloaded"
    }

    // Handlers live as children so they are instantiated with the singleton.
    property IpcHandler _theme: IpcHandler {
        target: "theme"
        function reload(): string { return reloadTheme() }
        function current(): string { return Colors.mode }
    }

    property IpcHandler _reload: IpcHandler {
        target: "reload"
        function all(): string { return reloadAll() }
    }

    property IpcHandler _lights: IpcHandler {
        target: "lights"
        function status(): string {
            return JSON.stringify({ active: RgbService.active, brightness: RgbService.brightness })
        }
        function toggle(): string { RgbService.toggle(); return "toggled" }
        function set(name: string): string { RgbService.setProfile(name); return name }
        function brightness(pct: int): string { RgbService.setBrightness(pct); return String(pct) }
    }

    property IpcHandler _popups: IpcHandler {
        target: "popups"
        function closeAll(): string { return closeAllPopups() }
        function toggle(name: string): string { return togglePopup(name) }
    }

    // The center island: open a widget straight from a keybind, e.g.
    // `qs ipc call island toggle launcher`. Ids come from widgets/Registry.qml;
    // "home" is the grid of all of them.
    property IpcHandler _island: IpcHandler {
        target: "island"
        function open(widget: string): string {
            if (!Registry.find(widget)) return "unknown widget: " + widget
            ShellState.openWidget(widget, false)
            return widget
        }
        function toggle(widget: string): string {
            if (!Registry.find(widget)) return "unknown widget: " + widget
            ShellState.toggleWidget(widget)
            return widget
        }
        function close(): string { ShellState.closeAll(); return "closed" }
        // Open Settings on a tab: hyprland, monitors, kitty.
        function settings(tab: string): string {
            ShellState.settingsTab = tab
            ShellState.openWidget("settings", false)
            return tab
        }
        // Open Agents on a tab: claude, opencode, bifrost.
        function agents(tab: string): string {
            ShellState.agentsTab = tab
            ShellState.openWidget("agents", false)
            return tab
        }
        function list(): string {
            return Registry.widgets.map(function (w) { return w.id }).join("\n")
        }
    }

    property IpcHandler _polkitIpc: IpcHandler {
        target: "polkit"
        function status(): string {
            return JSON.stringify({ registered: PolkitService.registered,
                                    pending: PolkitService.pending })
        }
        function cancel(): string { PolkitService.cancel(); return "cancelled" }
    }

    // Theme list + switching, so scripts stop needing a rofi dmenu.
    property IpcHandler _themes: IpcHandler {
        target: "themes"
        function count(): string { return String(ThemeService.themes.length) }
        function current(): string { return ThemeService.current }
        function list(): string {
            return ThemeService.themes.map(function (t) { return t.name }).join("\n")
        }
        function set(name: string): string { ThemeService.apply(name); return name }
        function refresh(): string { ThemeService.refresh(); return "loading" }
    }

    // Spotify, for scripting and diagnostics.
    property IpcHandler _spotify: IpcHandler {
        target: "spotify"
        function status(): string {
            return JSON.stringify({
                running: SpotifyService.running,
                state: SpotifyService.state,
                title: SpotifyService.title,
                artist: SpotifyService.artist,
                progress: SpotifyService.progress
            })
        }
        function playlists(): string { return String(SpotifyService.playlists.length) }
        function results(): string { return String(SpotifyService.results.length) }
        function search(q: string): string { SpotifyService.search(q); return "searching" }
        function toggle(): string { SpotifyService.toggle(); return "toggled" }
    }

    // Settings + pomodoro, for scripting and diagnostics.
    property IpcHandler _settings: IpcHandler {
        target: "settings"
        function get(): string { return JSON.stringify(SettingsService.snapshot()) }
        function set(key: string, value: string): string {
            var v = value
            if (value === "true") v = true
            else if (value === "false") v = false
            else if (!isNaN(Number(value))) v = Number(value)
            SettingsService[key] = v
            SettingsService.commit()
            return key + "=" + v
        }
        function reset(): string { SettingsService.reset(); return "reset" }
        // "all" or one output name to leave on.
        function monitors(mode: string): string { SettingsService.setMonitorMode(mode); return mode }
        function workspace(ws: string, output: string): string {
            SettingsService.setWorkspaceMonitor(ws, output)
            return ws + " -> " + output
        }
    }

    property IpcHandler _pomodoro: IpcHandler {
        target: "pomodoro"
        function status(): string {
            return JSON.stringify({
                phase: PomodoroService.phase,
                remaining: PomodoroService.remaining,
                running: PomodoroService.running,
                completed: PomodoroService.completed,
                clock: PomodoroService.clock,
                ringing: PomodoroService.ringing
            })
        }
        function start(): string { PomodoroService.start(); return "started" }
        function pause(): string { PomodoroService.pause(); return "paused" }
        function reset(): string { PomodoroService.reset(); return "reset" }
        function skip(): string { PomodoroService.skip(); return "skipped" }
        function setPhase(p: string): string { PomodoroService.setPhase(p); return p }
        function toggle(): string { PomodoroService.toggle(); return PomodoroService.running ? "running" : "paused" }
        // Alarm actions.
        function next(): string { PomodoroService.startNext(); return PomodoroService.phase }
        function snooze(minutes: int): string { PomodoroService.snooze(minutes); return "snoozed" }
        function dismiss(): string { PomodoroService.dismiss(); return "dismissed" }
    }

    property IpcHandler _alarms: IpcHandler {
        target: "alarms"
        function list(): string { return JSON.stringify(AlarmService.alarms) }
        function add(hour: int, minute: int, repeat: bool): string {
            var alarm = AlarmService.add(hour, minute, repeat)
            return alarm ? alarm.id : "failed"
        }
        function remove(id: string): string { AlarmService.remove(id); return "removed" }
        function toggle(id: string): string { AlarmService.toggle(id); return "toggled" }
        function stop(): string { AlarmService.stop(); return "stopped" }
    }

    // Wallpaper control (diagnostics + scripting).
    property IpcHandler _wallpaper: IpcHandler {
        target: "wallpaper"
        function count(): string { return String(WallpaperService.images.length) }
        function current(): string { return WallpaperService.current }
        function set(path: string): string { WallpaperService.apply(path); return path }
        function first(): string {
            return WallpaperService.images.length > 0 ? WallpaperService.images[0].path : "(none)"
        }
        function reload(): string { WallpaperService.refresh(); return "loading" }
        function transition(t: string): string { WallpaperService.transition = t; return t }
    }

    // App index introspection (diagnostics).
    property IpcHandler _apps: IpcHandler {
        target: "apps"
        function count(): string { return String(AppService.apps.length) }
        function loaded(): string { return AppService.loaded ? "yes" : "no" }
        function first(): string {
            return AppService.apps.length > 0 ? AppService.apps[0].name : "(none)"
        }
        function reload(): string { AppService.load(); return "loading" }
    }

    // Notification store control from scripts/scripts/CLI.
    property IpcHandler _notifs: IpcHandler {
        target: "notifications"
        function count(): string { return String(NotificationService.active.length) }
        function unread(): string { return String(NotificationService.unreadCount) }
        function markAllRead(): string {
            NotificationService.markAllRead()
            return "ok"
        }
        function clearAll(): string {
            NotificationService.clearAll()
            return "ok"
        }
        function toggleDnd(): string {
            NotificationService.dnd = !NotificationService.dnd
            return NotificationService.dnd ? "on" : "off"
        }
        function togglePeace(): string {
            NotificationService.peace = !NotificationService.peace
            NotificationService.save()
            return NotificationService.peace ? "on" : "off"
        }
    }

    property IpcHandler _nightLight: IpcHandler {
        target: "nightlight"
        function toggle(): string {
            NightLightService.toggle()
            return NightLightService.on ? "on" : "off"
        }
        function state(): string { return NightLightService.on ? "on" : "off" }
    }
}
