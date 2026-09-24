// Right notch: status cluster + popup triggers.
//
// Chunk 1 scope: the triggers and layout. Each indicator is a placeholder
// until its service lands in Chunk 3 — the wiring (which popup, which hover)
// is final so later chunks only fill in the readouts.
import QtQuick
import "../../theme"
import "../../state"
import "../../components"

Row {
    id: root

    spacing: 4

    // ── System tray ─────────────────────────────────────────────────────────
    // Placeholder until Chunk 3 wires Quickshell.Services.SystemTray.
    Item {
        width: 0
        height: 0
    }

    // ── Audio ───────────────────────────────────────────────────────────────
    BarTrigger {
        glyph: "\uf028"
        label: "--%"
        active: ShellState.audioOpen
        onTriggered: ShellState.toggle("audio")
    }

    // ── Network ─────────────────────────────────────────────────────────────
    BarTrigger {
        glyph: "\uf6ff"
        active: ShellState.networkOpen
        onTriggered: ShellState.toggle("network")
    }

    // ── Bluetooth ───────────────────────────────────────────────────────────
    BarTrigger {
        glyph: "\uf293"
        active: ShellState.bluetoothOpen
        onTriggered: ShellState.toggle("bluetooth")
    }

    // ── Clipboard ───────────────────────────────────────────────────────────
    BarTrigger {
        glyph: "\uf0ea"
        active: ShellState.clipboardOpen
        onTriggered: ShellState.toggle("clipboard")
    }

    // ── Emoji picker (replaces rofi-emoji) ──────────────────────────────────
    BarTrigger {
        glyph: "\uf118"
        active: ShellState.emojiOpen
        onTriggered: ShellState.toggle("emoji")
    }

    // ── Notifications, with unread badge ────────────────────────────────────
    Item {
        width: 26
        height: 26

        BarTrigger {
            anchors.fill: parent
            glyph: "\uf0f3"
            active: ShellState.notificationsOpen
            onTriggered: ShellState.toggle("notifications")
        }

        // Badge is wired in Chunk 4; count stays 0 until NotificationService
        // exists, so the layout is already correct.
        property int unread: 0

        Rectangle {
            visible: parent.unread > 0
            anchors.right: parent.right
            anchors.top: parent.top
            width: Math.max(14, badgeText.width + 8)
            height: 14
            radius: height / 2
            color: Theme.urgent

            Text {
                id: badgeText
                anchors.centerIn: parent
                text: parent.parent.unread > 99 ? "99+" : String(parent.parent.unread)
                color: Theme.crust
                font.family: Theme.fontFamily
                font.pixelSize: 9
                font.bold: true
            }
        }
    }

    // ── User / power menu ───────────────────────────────────────────────────
    BarTrigger {
        glyph: "\uf007"
        active: ShellState.userMenuOpen
        onTriggered: ShellState.toggle("userMenu")
    }
}
