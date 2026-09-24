// Control center main page: header, quick tiles, volume, Spotify, and the
// notifications list.
//
// Tiles either toggle their thing (the round glyph) or open the matching page
// (the rest of the tile); tiles with no page (Peace, Night Light) toggle from
// anywhere. Pages are opened through ShellState, so the morph to the new page
// size is driven by the same state the IPC/keybinds use.
import QtQuick
import QtQuick.Effects
import "../theme"
import "../state"
import "../services"
import "../components"

Item {
    id: root

    // The control center gives this page a fixed height; the notifications
    // list takes whatever the rows above leave, and scrolls.
    implicitWidth: Theme.ccWidth
    implicitHeight: Theme.ccHeight

    Column {
        id: column
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Theme.ccPadding
        }
        spacing: 10

        // Tile grid: Wi-Fi and Bluetooth share the wider left column; Audio
        // spans the two cells to its right (Peace + Night Light).
        readonly property real sideWidth: Math.round((width - spacing) * 0.38)
        readonly property real cellWidth: (width - sideWidth - spacing * 2) / 2

        // ── Header ──────────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 36

            IconButton {
                id: close
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                size: 34
                glyph: ""
                glyphSize: 14
                color: hovered ? Theme.hover : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                onActivated: ShellState.closeAll()
            }

            Text {
                anchors { left: close.right; leftMargin: 12; right: parent.right
                          verticalCenter: parent.verticalCenter }
                text: "Control Center"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 17
                elide: Text.ElideRight
            }
        }

        // ── Quick tiles ─────────────────────────────────────────────────────
        Row {
            width: parent.width
            spacing: 10

            QuickTile {
                id: wifi
                width: column.sideWidth
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
                width: column.cellWidth * 2 + parent.spacing
                glyph: AudioService.glyph
                title: "Audio"
                subtitle: AudioService.muted ? "Muted" : (AudioService.sinkName || "No output")
                active: !AudioService.muted
                onToggled: AudioService.toggleMute()
                onOpened: ShellState.showPage("audio")
            }
        }

        Row {
            id: row2
            width: parent.width
            spacing: 10

            QuickTile {
                width: column.sideWidth
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

            // Notifications still show, without their sound.
            QuickTile {
                width: column.cellWidth
                glyph: ""
                title: "Peace"
                subtitle: NotificationService.peace ? "On" : "Off"
                active: NotificationService.peace
                onToggled: root.togglePeace()
                onOpened: root.togglePeace()
            }

            QuickTile {
                width: column.cellWidth
                glyph: ""
                title: "Night Light"
                subtitle: !NightLightService.available ? "Unavailable"
                        : NightLightService.on ? "On" : "Off"
                active: NightLightService.on
                onToggled: NightLightService.toggle()
                onOpened: NightLightService.toggle()
            }
        }

        // ── Volume ──────────────────────────────────────────────────────────
        PillSlider {
            width: parent.width
            height: 40
            glyph: AudioService.glyph
            value: AudioService.volume
            fillColor: AudioService.muted ? Theme.overlay1 : Theme.accent
            onMoved: function (v) { AudioService.setVolume(v) }
            onGlyphClicked: AudioService.toggleMute()
        }

        SpotifyCard { width: parent.width }

        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
        }
    }

    // ── Notifications ───────────────────────────────────────────────────────
    Item {
        id: notifHeader
        anchors { top: column.bottom; topMargin: 6; left: column.left; right: column.right }
        height: 26

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
                label: "Clear all"
                accent: true
                onActivated: NotificationService.clearAll()
            }
        }
    }

    // Empty state, centred in the space the list would take.
    Column {
        anchors.centerIn: list
        visible: NotificationService.active.length === 0
        spacing: 10

        CenteredIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\uf1f6"
            size: 32
            color: Theme.overlay1
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Notifications Empty"
            color: Theme.subtext0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
        }
    }

    ListView {
        id: list
        anchors {
            top: notifHeader.bottom
            topMargin: 6
            left: column.left
            right: column.right
            bottom: parent.bottom
            bottomMargin: Theme.ccPadding
        }
        clip: true
        spacing: 8
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

    function togglePeace() {
        NotificationService.peace = !NotificationService.peace
        NotificationService.save()
    }

    // ── Pieces ──────────────────────────────────────────────────────────────

    // Now playing on Spotify, over a blurred copy of the cover art.
    component SpotifyCard: Item {
        id: player

        readonly property bool hasTrack: SpotifyService.running && SpotifyService.title !== ""

        height: 136

        // Background: the cover, blurred and darkened, clipped to the card's
        // rounded shape through a mask.
        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: playerMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
            }

            Image {
                id: art
                anchors.fill: parent
                source: SpotifyService.artUrl
                sourceSize.width: 320
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: art
                visible: art.status === Image.Ready && SpotifyService.artUrl !== ""
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1.0
                blurMax: 40
                saturation: 0.15
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.75) }
                    GradientStop { position: 1.0; color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.35) }
                }
            }
        }

        Rectangle {
            id: playerMask
            anchors.fill: parent
            radius: Theme.ccCardRadius
            visible: false
            layer.enabled: true
        }

        // Output device.
        Row {
            anchors { top: parent.top; topMargin: 12; left: parent.left; leftMargin: 16 }
            spacing: 6

            CenteredIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                size: 10
                color: Theme.subtext0
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: player.width - 60
                text: AudioService.sinkName
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
            }
        }

        // Title + artist; clicking opens the Spotify page (search,
        // playlists).
        Column {
            id: meta
            anchors {
                left: parent.left; leftMargin: 16
                right: playBtn.left; rightMargin: 12
                verticalCenter: playBtn.verticalCenter
            }
            spacing: 2

            Text {
                width: parent.width
                text: player.hasTrack ? SpotifyService.title
                    : SpotifyService.running ? "Nothing playing" : "Spotify isn't running"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: player.hasTrack ? SpotifyService.artist : ""
                color: Theme.subtext1
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: ShellState.showPage("spotify") }
        }

        Rectangle {
            id: playBtn
            anchors { right: parent.right; rightMargin: 16; top: parent.top; topMargin: 38 }
            width: 52
            height: 52
            radius: 26
            color: playHover.hovered ? Qt.lighter(Theme.text, 1.1) : Theme.text
            opacity: SpotifyService.running ? 1 : 0.5

            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            CenteredIcon {
                anchors.centerIn: parent
                // Nudge the play triangle to its optical centre.
                anchors.horizontalCenterOffset: SpotifyService.playing ? 0 : 2
                text: SpotifyService.playing ? "" : ""
                size: 16
                color: Theme.crust
            }

            HoverHandler { id: playHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: SpotifyService.toggle() }
        }

        // Transport: previous, seekable progress, next.
        Item {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom
                      leftMargin: 8; rightMargin: 8; bottomMargin: 8 }
            height: 24

            TransportButton {
                id: prev
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                glyph: ""
                onActivated: SpotifyService.previous()
            }

            TransportButton {
                id: next
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                glyph: ""
                onActivated: SpotifyService.next()
            }

            Item {
                anchors { left: prev.right; right: next.left; leftMargin: 8; rightMargin: 8
                          verticalCenter: parent.verticalCenter }
                height: 16

                Rectangle {
                    id: track
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                    height: 4
                    radius: 2
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25)

                    Rectangle {
                        width: parent.width * SpotifyService.progress
                        height: parent.height
                        radius: parent.radius
                        color: Theme.text

                        Behavior on width { NumberAnimation { duration: 900 } }
                    }
                }

                HoverHandler { cursorShape: SpotifyService.running ? Qt.PointingHandCursor : Qt.ArrowCursor }
                TapHandler {
                    enabled: SpotifyService.running
                    onTapped: function (e) {
                        var f = Math.max(0, Math.min(1, e.position.x / track.width))
                        SpotifyService.seekMs(f * SpotifyService.durationMs)
                    }
                }
            }
        }
    }

    component TransportButton: Rectangle {
        id: tb

        property string glyph
        signal activated()

        width: 24
        height: 24
        radius: 12
        color: tbHover.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : "transparent"

        CenteredIcon {
            anchors.centerIn: parent
            text: tb.glyph
            size: 11
            color: Theme.text
        }

        HoverHandler { id: tbHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: tb.activated() }
    }

    component TextAction: Rectangle {
        id: act

        property string label
        property bool   accent: false
        signal activated()

        width: actText.width + 16
        height: 22
        radius: height / 2
        color: actHover.hovered ? Theme.hover : "transparent"

        Text {
            id: actText
            anchors.centerIn: parent
            text: act.label
            color: act.accent ? Theme.accent : Theme.subtext0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }

        HoverHandler { id: actHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: act.activated() }
    }
}
