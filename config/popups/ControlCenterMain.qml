// Control center main page: quick tiles, sliders, notifications, footer.
//
// Tiles either toggle their thing (the round glyph) or open the matching page
// (the rest of the tile). Pages are opened through ShellState, so the morph to
// the new page size is driven by the same state the IPC/keybinds use.
import QtQuick
import Quickshell.Io
import "../theme"
import "../state"
import "../services"
import "../components"

Item {
    id: root

    // The control center gives this page a fixed height; the notifications
    // card takes whatever the other rows leave, and its list scrolls.
    implicitWidth: Theme.ccWidth
    implicitHeight: Theme.ccHeight

    readonly property color cardColor: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.045)
    readonly property color cardBorder: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)

    Column {
        id: column
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Theme.ccPadding
        }
        spacing: 10

        // ── Quick tiles ─────────────────────────────────────────────────────
        Grid {
            id: tiles
            width: parent.width
            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            readonly property real cellWidth: (width - columnSpacing) / 2

            QuickTile {
                width: parent.cellWidth
                glyph: NetworkService.glyph
                title: NetworkService.kind === "ethernet" ? "Ethernet" : "Wi-Fi"
                subtitle: {
                    if (NetworkService.kind === "ethernet")
                        return NetworkService.ip !== "" ? NetworkService.ip : "Connected"
                    if (!NetworkService.wifiEnabled) return "Off"
                    return NetworkService.connected ? NetworkService.ssid : "Not connected"
                }
                active: NetworkService.connected
                onToggled: NetworkService.toggleWifi()
                onOpened: ShellState.showPage("network")
            }

            QuickTile {
                width: parent.cellWidth
                glyph: BluetoothService.glyph
                title: "Bluetooth"
                subtitle: {
                    if (!BluetoothService.powered) return "Off"
                    var c = BluetoothService.connected
                    if (c.length === 0) return "On"
                    return c[0].name + (c.length > 1 ? " +" + (c.length - 1) : "")
                }
                active: BluetoothService.powered
                onToggled: BluetoothService.togglePower()
                onOpened: ShellState.showPage("bluetooth")
            }

            QuickTile {
                width: parent.cellWidth
                glyph: "\uf0ea"
                title: "Clipboard"
                subtitle: {
                    var n = ClipboardService.entries.length
                    if (!ClipboardService.available) return "cliphist not running"
                    return n === 0 ? "Empty" : n + (n === 1 ? " item" : " items")
                }
                toggleable: false
                onOpened: ShellState.showPage("clipboard")
            }

            QuickTile {
                width: parent.cellWidth
                glyph: "\uf118"
                title: "Emoji"
                subtitle: "Search & copy"
                toggleable: false
                onOpened: ShellState.showPage("emoji")
            }
        }

        // ── Display ─────────────────────────────────────────────────────────
        // Hidden on machines with no backlight (this desktop).
        SliderCard {
            id: display
            visible: BrightnessService.available
            title: "Display"

            PillSlider {
                width: parent.width
                glyph: BrightnessService.glyph
                value: BrightnessService.percent / 100
                onMoved: function (v) { BrightnessService.set(Math.max(1, v * 100)) }
            }
        }

        // ── Sound ───────────────────────────────────────────────────────────
        SliderCard {
            id: sound
            title: "Sound"
            detail: AudioService.muted ? "Muted" : AudioService.volumePercent + "%"
            hasPage: true
            onOpened: ShellState.showPage("audio")

            PillSlider {
                width: parent.width
                glyph: AudioService.glyph
                value: AudioService.volume
                fillColor: AudioService.muted ? Theme.overlay1 : Theme.accent
                onMoved: function (v) { AudioService.setVolume(v) }
                onGlyphClicked: AudioService.toggleMute()
            }
        }

        // ── Notifications ───────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            // Column skips hidden children for spacing, so Display only
            // counts when it is shown.
            height: root.height - Theme.ccPadding * 2
                    - tiles.height - sound.height - footer.height - column.spacing * 3
                    - (display.visible ? display.height + column.spacing : 0)
            radius: Theme.ccCardRadius
            color: root.cardColor
            border.width: 1
            border.color: root.cardBorder

            Column {
                id: notifColumn
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 12
                    leftMargin: 14
                    rightMargin: 14
                }
                spacing: 6

                Item {
                    width: parent.width
                    height: 24

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            text: "Notifications"
                            color: Theme.subtext0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Text {
                            visible: NotificationService.unreadCount > 0
                            text: NotificationService.unreadCount + " new"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }

                    Row {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 2

                        TextAction {
                            visible: NotificationService.unreadCount > 0
                            label: "Read all"
                            onActivated: NotificationService.markAllRead()
                        }

                        TextAction {
                            visible: NotificationService.active.length > 0
                            label: "Clear"
                            danger: true
                            onActivated: NotificationService.clearAll()
                        }
                    }
                }

                Text {
                    visible: NotificationService.active.length === 0
                    height: 40
                    verticalAlignment: Text.AlignVCenter
                    text: "No notifications"
                    color: Theme.subtext1
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLarge
                }

                Item {
                    width: parent.width
                    // Card height minus its margins, the header row and spacing.
                    height: NotificationService.active.length === 0
                            ? 0 : Math.max(0, notifColumn.parent.height - 24 - 24 - notifColumn.spacing)
                    visible: height > 0

                    ListView {
                        id: list
                        anchors.fill: parent
                        clip: true
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
            }
        }

        // ── Footer: session actions ─────────────────────────────────────
        Row {
            id: footer
            width: parent.width
            height: 40
            spacing: 8

            readonly property real buttonWidth: (width - spacing * 2) / 3

            SessionButton {
                glyph: "\uf023"
                label: "Lock"
                command: "hyprlock"
            }
            SessionButton {
                glyph: "\uf021"
                label: "Restart"
                command: "systemctl reboot"
                confirm: true
            }
            SessionButton {
                glyph: "\uf011"
                label: "Shut down"
                command: "systemctl poweroff"
                confirm: true
                danger: true
            }
        }
    }

    // ── Pieces ──────────────────────────────────────────────────────────────

    property Process _session: Process {}

    // Session action button. `confirm` ones need a second click within a few
    // seconds, so a stray click in the panel can't reboot the machine.
    component SessionButton: Rectangle {
        id: btn

        property string glyph
        property string label
        property string command
        property bool   confirm: false
        property bool   danger: false
        property bool   armed: false

        readonly property color tint: danger ? Theme.urgent : Theme.accent

        width: footer.buttonWidth
        height: footer.height
        radius: height / 2
        color: btn.armed ? Qt.rgba(tint.r, tint.g, tint.b, 0.22)
             : btnHover.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.09)
             : root.cardColor
        border.width: 1
        border.color: btn.armed ? Qt.rgba(tint.r, tint.g, tint.b, 0.6) : root.cardBorder

        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Row {
            anchors.centerIn: parent
            spacing: 8

            CenteredIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.glyph
                size: 14
                color: btn.danger || btn.armed ? btn.tint : Theme.text
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.armed ? "Confirm?" : btn.label
                color: btn.armed ? btn.tint : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }

        Timer {
            id: disarm
            interval: 3000
            onTriggered: btn.armed = false
        }

        HoverHandler { id: btnHover; cursorShape: Qt.PointingHandCursor }
        TapHandler {
            onTapped: {
                if (btn.confirm && !btn.armed) {
                    btn.armed = true
                    disarm.restart()
                    return
                }
                btn.armed = false
                ShellState.closeAll()
                root._session.command = ["bash", "-c", btn.command]
                root._session.running = true
            }
        }
    }

    // Card with a title row (+ optional chevron to a detail page) over a slider.
    component SliderCard: Rectangle {
        id: card

        property string title
        property string detail: ""
        property bool   hasPage: false     // shows the chevron to a detail page
        default property alias content: body.data

        signal opened()

        width: parent ? parent.width : 0
        height: header.height + body.implicitHeight + 30
        radius: Theme.ccCardRadius
        color: root.cardColor
        border.width: 1
        border.color: root.cardBorder

        Item {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 10; leftMargin: 14; rightMargin: 10 }
            height: 26

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: card.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }

            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: card.detail !== ""
                    text: card.detail
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }

                IconButton {
                    visible: card.hasPage
                    size: 24
                    glyph: "\uf054"
                    glyphSize: 10
                    glyphColor: Theme.subtext0
                    color: hovered ? Theme.hover : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                    onActivated: card.opened()
                }
            }
        }

        Item {
            id: body
            anchors { top: header.bottom; left: parent.left; right: parent.right; topMargin: 8; leftMargin: 10; rightMargin: 10 }
            implicitHeight: childrenRect.height
        }
    }

    component TextAction: Rectangle {
        id: act

        property string label
        property bool   danger: false
        signal activated()

        width: actText.width + 16
        height: 22
        radius: height / 2
        color: actHover.hovered
               ? (act.danger ? Qt.rgba(Theme.urgent.r, Theme.urgent.g, Theme.urgent.b, 0.2) : Theme.hover)
               : "transparent"

        Text {
            id: actText
            anchors.centerIn: parent
            text: act.label
            color: act.danger && actHover.hovered ? Theme.urgent : Theme.subtext0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }

        HoverHandler { id: actHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: act.activated() }
    }
}
