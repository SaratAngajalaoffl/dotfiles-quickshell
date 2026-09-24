// User / power menu — session actions, plus a DND toggle for notifications.
import QtQuick
import "../theme"
import "../state"
import "../services"
import "../components"
import Quickshell
import Quickshell.Io

Item {
    id: root

    implicitWidth: 260
    implicitHeight: panel.implicitHeight

    property Process _run: Process {}

    function run(cmd) {
        _run.command = ["bash", "-c", cmd]
        _run.running = true
        ShellState.close("userMenu")
    }

    PopupPanel {
        id: panel
        title: "Session"
        width: parent.width

        Column {
            width: parent.width
            spacing: 2

            // DND is a toggle rather than an action, so it sits on top.
            ListRow {
                title: "Do not disturb"
                subtitle: NotificationService.dnd ? "Notifications are silenced"
                                                  : "Toasts are shown"
                trailing: NotificationService.dnd ? "On" : "Off"
                glyph: NotificationService.dnd ? "\uf1f6" : "\uf0f3"
                leadingActive: NotificationService.dnd
                selected: NotificationService.dnd
                onActivated: NotificationService.dnd = !NotificationService.dnd
            }

            Divider { width: parent.width }

            ListRow {
                title: "Lock"
                glyph: "\uf023"
                onActivated: root.run("hyprlock")
            }

            ListRow {
                title: "Log out"
                glyph: "\uf08b"
                onActivated: root.run("hyprctl dispatch exit")
            }

            ListRow {
                title: "Suspend"
                glyph: "\uf186"
                onActivated: root.run("systemctl suspend")
            }

            ListRow {
                title: "Reboot"
                glyph: "\uf021"
                onActivated: root.run("systemctl reboot")
            }

            ListRow {
                title: "Shut down"
                glyph: "\uf011"
                glyphColor: Theme.urgent
                onActivated: root.run("systemctl poweroff")
            }
        }
    }
}
