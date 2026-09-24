// Every widget the island can open. This list is the only place a widget is
// declared: the home grid renders it, and `qs ipc call island open <id>`
// looks ids up here.
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
    readonly property var widgets: [
        { id: "launcher",   name: "Apps",       icon: "\uf135", source: "LauncherWidget.qml" },
        { id: "theme",      name: "Themes",     icon: "\u{f03d8}", source: "" },
        { id: "wallpaper",  name: "Wallpapers", icon: "\uf03e", source: "" },
        { id: "settings",   name: "Settings",   icon: "\uf013", source: "" },
        { id: "agents",     name: "Agents",     icon: "\u{f06a9}", source: "" },
        { id: "clipboard",  name: "Clipboard",  icon: "\uf0ea", source: "" },
        { id: "emoji",      name: "Emoji",      icon: "\uf118", source: "" },
        { id: "pomodoro",   name: "Pomodoro",   icon: "\uf2f2", source: "" },
        { id: "calendar",   name: "Calendar",   icon: "\uf073", source: "" },
        { id: "spotify",    name: "Spotify",    icon: "\uf1bc", source: "" }
    ]

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
