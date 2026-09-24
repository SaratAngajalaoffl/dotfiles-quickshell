// Notification panel: header with counts + bulk actions, then the list.
//
// Lives in a PopupWindow, which Hyprland cannot blur (finding F3) — hence the
// solid fill from PopupPanel's default background.
import QtQuick
import "../theme"
import "../state"
import "../services"
import "../components"

Item {
    id: root

    readonly property int maxListHeight: 440

    implicitWidth: Theme.notificationsWidth
    implicitHeight: panel.implicitHeight

    PopupPanel {
        id: panel
        width: parent.width

        Column {
            width: parent.width
            spacing: 0

            // ── Empty state ─────────────────────────────────────────────────
            Item {
                width: parent.width
                height: 96
                visible: NotificationService.active.length === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "\uf0f3"
                        color: Theme.inactive
                        font.family: Theme.fontFamily
                        font.pixelSize: 28
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No notifications"
                        color: Theme.subtext0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }
            }

            // ── Active list ─────────────────────────────────────────────────
            Item {
                width: parent.width
                height: NotificationService.active.length === 0
                        ? 0
                        : Math.min(list.contentHeight, root.maxListHeight)
                visible: height > 0

                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true
                    spacing: 0
                    boundsBehavior: Flickable.StopAtBounds
                    model: NotificationService.active

                    delegate: NotificationCard {
                        required property var modelData

                        width: list.width
                        entry: modelData
                        isLive: NotificationService.isLive(modelData.id)

                        onMarkRead: NotificationService.markRead(modelData.id)
                        onRemove:   NotificationService.dismiss(modelData.id)
                        onAction: function (actionId) {
                            NotificationService.invoke(modelData.id, actionId)
                        }
                    }
                }
            }

            // ── History summary ─────────────────────────────────────────────
            Item {
                width: parent.width
                height: historyRow.visible ? 38 : 0
                visible: height > 0

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: 1
                    color: Theme.divider
                }

                Row {
                    id: historyRow
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    visible: NotificationService.history.length > 0

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: NotificationService.history.length + " in history"
                        color: Theme.subtext0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Item { width: parent.width - 200; height: 1 }

                    HeaderAction {
                        anchors.verticalCenter: parent.verticalCenter
                        label: "Clear history"
                        danger: true
                        onActivated: NotificationService.clearHistory()
                    }
                }
            }
        }

        // ── Custom header: title + count + bulk actions ─────────────────────
        customHeader: Item {
            width: parent.width

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true

                Text {
                    anchors {
                        left: parent.right
                        leftMargin: 10
                        baseline: parent.baseline
                    }
                    visible: NotificationService.unreadCount > 0
                    text: NotificationService.unreadCount + " new"
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: false
                }
            }

            Row {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                spacing: 4

                HeaderAction {
                    label: "Read all"
                    enabled: NotificationService.unreadCount > 0
                    onActivated: NotificationService.markAllRead()
                }

                HeaderAction {
                    label: "Clear all"
                    enabled: NotificationService.active.length > 0
                    danger: true
                    onActivated: NotificationService.clearAll()
                }
            }
        }
    }

    // ── Small header button ─────────────────────────────────────────────────
    component HeaderAction: Rectangle {
        id: act

        property string label
        property bool   enabled: true
        property bool   danger: false

        signal activated()

        width:  labelText.width + 18
        height: 26
        radius: height / 2
        color: actHover.hovered
               ? (act.danger ? Qt.rgba(Theme.urgent.r, Theme.urgent.g, Theme.urgent.b, 0.22)
                             : Theme.hover)
               : "transparent"

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            id: labelText
            anchors.centerIn: parent
            text: act.label
            color: (act.danger && actHover.hovered) ? Theme.urgent
                 : (act.enabled ? Theme.subtext0 : Theme.inactive)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }

        HoverHandler { id: actHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: if (act.enabled) act.activated() }
    }
}
