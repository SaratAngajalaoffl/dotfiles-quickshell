// Right notch: system tray + status indicators + popup triggers.
//
// Every readout is backed by a real service now (Chunk 3), replacing the
// placeholders from Chunk 1.
import QtQuick
import "../../theme"
import "../../state"
import "../../services"
import "../../components"

Row {
    id: root

    spacing: 4

    // ── System tray ─────────────────────────────────────────────────────────
    SysTray {}

    // ── Media ───────────────────────────────────────────────────────────────
    Media {}

    // ── Audio ───────────────────────────────────────────────────────────────
    BarTrigger {
        glyph: AudioService.glyph
        label: AudioService.muted ? "muted" : AudioService.volumePercent + "%"
        active: ShellState.audioOpen || ShellState.audioTriggerHovered
        onTriggered: ShellState.toggle("audio")

        HoverHandler {
            id: audioHover
            onHoveredChanged: ShellState.audioTriggerHovered = hovered
        }
    }

    // ── Network ─────────────────────────────────────────────────────────────
    BarTrigger {
        glyph: NetworkService.glyph
        glyphColor: NetworkService.color
        active: ShellState.networkOpen
        onTriggered: ShellState.toggle("network")
    }

    // ── Bluetooth ───────────────────────────────────────────────────────────
    BarTrigger {
        glyph: BluetoothService.glyph
        glyphColor: BluetoothService.color
        active: ShellState.bluetoothOpen
        onTriggered: ShellState.toggle("bluetooth")
    }

    // ── Brightness ──────────────────────────────────────────────────────────
    // Hidden entirely on machines with no backlight (this desktop).
    BarTrigger {
        visible: BrightnessService.available
        glyph: BrightnessService.glyph
        label: BrightnessService.percent + "%"
        onTriggered: { /* no popup yet — brightness is a scroll/keys target */ }

        WheelHandler {
            onWheel: function (e) { BrightnessService.adjust(e.angleDelta.y > 0 ? 5 : -5) }
        }
    }

    // ── Battery (hidden on desktops) ────────────────────────────────────────
    BarTrigger {
        visible: BatteryService.visible
        glyph: BatteryService.glyph
        glyphColor: BatteryService.color
        label: BatteryService.percent + "%"
        onTriggered: { /* power popup lands with the dashboard */ }
    }

    // ── Theme picker (replaces the rofi theme menu) ─────────────────────────
    BarTrigger {
        glyph: "\uf53f"
        active: ShellState.themeOpen
        onTriggered: ShellState.toggle("theme")
    }

    // ── Dashboard (calendar / pomodoro / customise) ────────────────────────
    BarTrigger {
        glyph: "\uf00a"
        active: ShellState.dashboardOpen
        onTriggered: ShellState.toggle("dashboard")
    }

    // ── Wallpaper ───────────────────────────────────────────────────────────
    BarTrigger {
        glyph: "\uf03e"
        active: ShellState.wallpaperOpen
        onTriggered: ShellState.toggle("wallpaper")
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

        property int unread: NotificationService.unreadCount

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
