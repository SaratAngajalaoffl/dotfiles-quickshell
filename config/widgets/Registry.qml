// Every widget the island can open. This list is the only place a widget is
// declared: the home grid renders the non-hidden ones, and
// `qs ipc call island open <id>` looks ids up here.
//
// Adding a widget:
//   1. Write widgets/<Name>Widget.qml following the contract in
//      WidgetHost.qml (implicit size, `active`, close via ShellState).
//   2. Set `source` on its entry below. Entries without a source open the
//      placeholder, so a widget can be listed before it is built.
//   3. Optional keybind: `qs ipc call island toggle <id>` in hypr's
//      keybinds.lua.
pragma Singleton
import QtQuick

QtObject {
    id: root

    // id:     stable name used by IPC, keybinds and ShellState.islandWidget
    // name:   label on the home grid
    // icon:   Nerd Font glyph
    // source: QML file in this directory, "" until the widget exists
    // hidden: (optional) left off the home grid — for widgets the shell opens
    //         itself when needed (e.g. the polkit prompt), not ones you pick
    // passive: (optional) shown without taking the keyboard or the rest of
    //          the screen — it doesn't interrupt typing, and clicks outside
    //          go through (e.g. a notification)
    readonly property var widgets: [
        { id: "launcher",   name: "Apps",       icon: "\uf135", source: "LauncherWidget.qml" },
        { id: "theme",      name: "Themes",     icon: "\u{f03d8}", source: "ThemeWidget.qml" },   // wallpapers = themes
        { id: "settings",   name: "Settings",   icon: "\uf013", source: "SettingsWidget.qml" },
        { id: "agents",     name: "Agents",     icon: "\u{f06a9}", source: "AgentsWidget.qml" },
        { id: "clipboard",  name: "Clipboard",  icon: "\uf0ea", source: "ClipboardWidget.qml" },
        { id: "emoji",      name: "Emoji",      icon: "\uf118", source: "EmojiWidget.qml" },
        { id: "pomodoro",   name: "Pomodoro",   icon: "\uf2f2", source: "PomodoroWidget.qml" },
        { id: "stats",      name: "Stats",      icon: "\u{f0128}", source: "StatsWidget.qml" },
        { id: "polkit",     name: "Authenticate", icon: "\uf023", source: "PolkitWidget.qml", hidden: true },
        { id: "pomodoro-alarm", name: "Pomodoro alarm", icon: "\uf0f3", source: "PomodoroAlarmWidget.qml", hidden: true, passive: true },
        { id: "notification", name: "Notification", icon: "\uf0f3", source: "NotificationWidget.qml", hidden: true, passive: true }
    ]

    // What the home grid shows.
    readonly property var pickable: widgets.filter(function (w) { return !w.hidden })

    // The grid of widgets itself; not listed above, so it never tiles itself.
    readonly property var home: ({ id: "home", name: "Widgets", icon: "\uf00a",
                                   source: "WidgetHome.qml" })

    function find(id) {
        if (id === "home") return root.home
        for (var i = 0; i < root.widgets.length; i++)
            if (root.widgets[i].id === id) return root.widgets[i]
        return null
    }
}
