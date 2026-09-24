// Spotify popup (Chunk 5e): now playing, transport, search, playlists.
//
// Port of the eww spotify-control widget. Playback tallks to `soloist ctl`
// through SpotifyService; search goes to the Web API with keyring credentials.
import QtQuick
import "../theme"
import "../state"
import "../services"
import "../components"

Item {
    id: root

    implicitWidth: Theme.spotifyWidth
    implicitHeight: panel.implicitHeight

    property string query: ""

    // Only search once the user has actually typed something — the API call is
    // network-bound and should not fire on every keystroke.
    property Timer _debounce: Timer {
        interval: 450
        repeat: false
        onTriggered: SpotifyService.search(root.query)
    }

    // Close the popup if the shell reloads underneath it.
    Connections {
        target: ShellState
        function onSpotifyOpenChanged() {
            if (!ShellState.spotifyOpen) {
                root.query = ""
                SpotifyService.clearSearch()
            }
        }
    }

    PopupPanel {
        id: panel
        width: parent.width

        customHeader: Item {
            width: parent.width

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Spotify"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }

            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: SpotifyService.running ? SpotifyService.state : "not running"
                color: SpotifyService.running ? Theme.accent : Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        Column {
            width: parent.width
            spacing: 10

            // ── Now playing ─────────────────────────────────────────────────
            Row {
                width: parent.width
                spacing: 12

                Rectangle {
                    width: 72; height: 72
                    radius: Theme.cornerRadiusSmall
                    color: Theme.surface
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: SpotifyService.artUrl
                        sourceSize.width: 144
                        sourceSize.height: 144
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    Icon {
                        anchors.centerIn: parent
                        visible: SpotifyService.artUrl === ""
                        text: "\uf001"
                        color_: Theme.overlay0
                        font.pixelSize: 28
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 72 - 12
                    spacing: 3

                    Text {
                        width: parent.width
                        text: SpotifyService.title !== "" ? SpotifyService.title : "Nothing playing"
                        color: SpotifyService.title !== "" ? Theme.text : Theme.subtext0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: SpotifyService.artist
                        color: Theme.subtext0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        elide: Text.ElideRight
                    }

                    // Progress: a scrubber, so dragging seeks.
                    Slider {
                        width: parent.width
                        enabled: SpotifyService.running
                        value: SpotifyService.progress
                        onMoved: function (v) {
                            SpotifyService.seekMs(v * SpotifyService.durationMs)
                        }
                    }

                    Text {
                        text: fmt(SpotifyService.positionMs) + " / " + fmt(SpotifyService.durationMs)
                        color: Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }
            }

            // ── Transport ───────────────────────────────────────────────────
            // Three fixed clusters sized off the panel width rather than
            // nested Rows: a Row cannot stretch a spacer reliably, so shuffle
            // sits left, transport centred and repeat right.
            Item {
                width: parent.width
                height: 38

                IconButton {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    glyph: "\uf074"
                    size: 30
                    active: SpotifyService.shuffle
                    onActivated: SpotifyService.setShuffle(!SpotifyService.shuffle)
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    IconButton {
                        glyph: "\uf048"; size: 30
                        onActivated: SpotifyService.previous()
                    }
                    IconButton {
                        glyph: SpotifyService.playing ? "\uf04c" : "\uf04b"
                        size: 36
                        glyphSize: Theme.fontSizeLarge
                        active: SpotifyService.playing
                        onActivated: SpotifyService.toggle()
                    }
                    IconButton {
                        glyph: "\uf051"; size: 30
                        onActivated: SpotifyService.next()
                    }
                }

                IconButton {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    glyph: SpotifyService.repeat === "track" ? "\uf079" : "\uf01e"
                    size: 30
                    active: SpotifyService.repeat !== "off"
                    onActivated: SpotifyService.cycleRepeat()
                }
            }

            Divider { width: parent.width }

            // ── Search ──────────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: 32
                radius: Theme.cornerRadiusSmall
                color: Theme.surface
                border.width: 1
                border.color: searchInput.activeFocus
                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)
                            : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)

                Icon {
                    id: searchGlyph
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    text: SpotifyService.searching ? "\uf021" : "\uf002"
                    color_: Theme.subtext0
                    font.pixelSize: Theme.fontSizeSmall
                }

                TextInput {
                    id: searchInput
                    anchors {
                        left: searchGlyph.right; leftMargin: 8
                        right: parent.right; rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    selectByMouse: true
                    clip: true
                    focus: ShellState.spotifyOpen

                    Text {
                        visible: searchInput.text === ""
                        text: "Search tracks…"
                        color: Theme.overlay0
                        font: searchInput.font
                    }

                    onTextChanged: {
                        root.query = text
                        _debounce.restart()
                    }

                    Keys.onEscapePressed: {
                        text = ""
                        root.query = ""
                        SpotifyService.clearSearch()
                    }
                }
            }

            // Results
            Column {
                width: parent.width
                spacing: 2

                Repeater {
                    model: SpotifyService.results

                    delegate: ListRow {
                        required property var modelData

                        title: modelData.name
                        subtitle: modelData.artist
                        glyph: "\uf001"
                        onActivated: {
                            SpotifyService.playUri(modelData.uri)
                            root.query = ""
                            searchInput.text = ""
                            SpotifyService.clearSearch()
                        }
                    }
                }

                Text {
                    visible: SpotifyService.searchError !== ""
                    width: parent.width
                    text: SpotifyService.searchError
                    color: Theme.urgent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            Divider { width: parent.width }
            SectionLabel { text: "Playlists" }

            Repeater {
                model: SpotifyService.playlists

                delegate: ListRow {
                    required property var modelData

                    title: modelData.name
                    subtitle: modelData.uri.replace("spotify:", "")
                    glyph: "\uf0cb"
                    onActivated: SpotifyService.playUri(modelData.uri)
                }
            }
        }
    }

    function fmt(ms) {
        var total = Math.max(0, Math.floor(ms / 1000))
        var m = Math.floor(total / 60)
        var s = total % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    component SectionLabel: Text {
        color: Theme.subtext0
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
    }
}
