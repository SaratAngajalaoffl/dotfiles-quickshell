// Global UI state: which popup is open, plus transient bar modes.
//
// One place decides "what is open", so opening anything closes everything
// else and there is no way for two popups to end up stacked.
pragma Singleton
import QtQuick

QtObject {
    id: root

    // ── Popups ──────────────────────────────────────────────────────────────
    // Exactly one of these is true at a time (enforced by open()).
    property bool launcherOpen:      false
    property bool notificationsOpen: false
    property bool audioOpen:         false
    property bool bluetoothOpen:     false
    property bool networkOpen:       false
    property bool clipboardOpen:     false
    property bool emojiOpen:         false
    property bool userMenuOpen:      false
    property bool dashboardOpen:     false
    property bool wallpaperOpen:     false
    property bool spotifyOpen:       false
    property bool calendarOpen:      false

    // Toasts are not part of the one-popup-at-a-time set: a toast can be on
    // screen while the notifications panel is open.
    property bool notificationToastOpen: false

    // Which dashboard tab is showing.
    property string dashboardTab: "home"

    // ── Transient state ─────────────────────────────────────────────────────
    // Collapses the bar to an edge strip, for fullscreen-ish focus.
    property bool focusMode: false

    // Hover flags for hover-to-open popups, set by the trigger widgets.
    property bool audioTriggerHovered:       false
    property bool notificationsTriggerHovered: false
    property bool userTriggerHovered:        false

    readonly property var _all: ({
        launcher:      "launcherOpen",
        notifications: "notificationsOpen",
        audio:         "audioOpen",
        bluetooth:     "bluetoothOpen",
        network:       "networkOpen",
        clipboard:     "clipboardOpen",
        emoji:         "emojiOpen",
        userMenu:      "userMenuOpen",
        dashboard:     "dashboardOpen",
        wallpaper:     "wallpaperOpen",
        spotify:       "spotifyOpen",
        calendar:      "calendarOpen"
    })

    function anyOpen() {
        for (var k in root._all)
            if (root[root._all[k]])
                return true
        return false
    }

    // Close everything, optionally leaving one popup open.
    function closeAll(except) {
        for (var k in root._all) {
            if (k === except) continue
            root[root._all[k]] = false
        }
    }

    // Open one popup, closing the rest. Toggling the same one closes it.
    function toggle(name) {
        var prop = root._all[name]
        if (prop === undefined) {
            console.warn("ShellState.toggle: unknown popup", name)
            return
        }
        var next = !root[prop]
        root.closeAll(next ? name : undefined)
        root[prop] = next
    }

    function open(name, tab) {
        var prop = root._all[name]
        if (prop === undefined) return
        root.closeAll(name)
        if (tab !== undefined) root.dashboardTab = tab
        root[prop] = true
    }

    function close(name) {
        var prop = root._all[name]
        if (prop !== undefined) root[prop] = false
    }

    function isOpen(name) {
        var prop = root._all[name]
        return prop !== undefined && root[prop]
    }
}
