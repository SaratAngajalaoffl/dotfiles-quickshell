// Spotify page of the control center: now playing, transport, search, and the
// pinned playlists.
//
// Playback talks to `soloist ctl` through SpotifyService; search goes to the
// Web API with keyring credentials. It lives in the control center (not a
// popup of its own) because that surface takes keyboard focus — a popup
// attached to the bar never did, so the search box couldn't be typed into.
import QtQuick
import "../theme"
import "../state"
import "../services"
import "../components"

Item {
    id: root

    property bool embedded: false

    implicitWidth: Theme.ccWidth
    implicitHeight: panel.implicitHeight

    property string query: ""
    property string filter: "all"          // all | track | artist | album | playlist

    readonly property var filters: [
        { id: "all",      label: "All" },
        { id: "track",    label: "Songs" },
        { id: "artist",   label: "Artists" },
        { id: "album",    label: "Albums" },
        { id: "playlist", label: "Playlists" }
    ]

    readonly property var kindLabel: ({ track: "Song", artist: "Artist", album: "Album", playlist: "Playlist" })

    // "All" is a digest: the top few of each kind, songs first.
    readonly property var shown: {
        var r = SpotifyService.results
        if (root.filter !== "all")
            return r.filter(function (x) { return x.kind === root.filter })
        var caps = { track: 4, artist: 2, album: 2, playlist: 2 }
        var seen = {}
        return r.filter(function (x) {
            seen[x.kind] = (seen[x.kind] || 0) + 1
            return seen[x.kind] <= (caps[x.kind] || 0)
        })
    }

    // Don't hit the API on every keystroke.
    property Timer _debounce: Timer {
        interval: 300
        onTriggered: SpotifyService.search(root.query)
    }

    function play(uri) {
        SpotifyService.playUri(uri)
        root.reset()
    }

    function reset() {
        searchInput.text = ""
        root.query = ""
        root.filter = "all"
        SpotifyService.clearSearch()
    }

    // Focus the search box when the page opens; start clean when it closes.
    Connections {
        target: ShellState
        function onSpotifyOpenChanged() {
            if (ShellState.spotifyOpen) searchInput.forceActiveFocus()
            else root.reset()
        }
    }

    PopupPanel {
        id: panel
        embedded: root.embedded
        width: parent.width

        customHeader: Item {
            anchors.fill: parent

            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: "Spotify"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }

            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: !SpotifyService.running ? "Not running"
                    : SpotifyService.state.charAt(0).toUpperCase() + SpotifyService.state.slice(1)
                color: SpotifyService.running ? Theme.accent : Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        Column {
            width: parent.width
            spacing: 12

            Item { width: 1; height: 2 }

            // ── Now playing ─────────────────────────────────────────────────
            Row {
                width: parent.width
                spacing: 14

                Cover {
                    width: 88
                    height: 88
                    radius: 12
                    source: SpotifyService.artUrl
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 88 - 14
                    spacing: 4

                    Text {
                        width: parent.width
                        text: SpotifyService.title !== "" ? SpotifyService.title : "Nothing playing"
                        color: SpotifyService.title !== "" ? Theme.text : Theme.subtext0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge + 2
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: SpotifyService.artist
                        color: Theme.subtext0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
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

                    Item {
                        width: parent.width
                        height: 12

                        TimeText { anchors.left: parent.left; text: root.fmt(SpotifyService.positionMs) }
                        TimeText { anchors.right: parent.right; text: root.fmt(SpotifyService.durationMs) }
                    }
                }
            }

            // ── Transport ───────────────────────────────────────────────────
            // Three fixed clusters sized off the panel width rather than
            // nested Rows: a Row cannot stretch a spacer reliably, so shuffle
            // sits left, transport centred and repeat right.
            Item {
                width: parent.width
                height: 44

                IconButton {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    glyph: ""
                    size: 32
                    active: SpotifyService.shuffle
                    onActivated: SpotifyService.setShuffle(!SpotifyService.shuffle)
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: ""; size: 32
                        onActivated: SpotifyService.previous()
                    }

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: playHover.hovered ? Qt.lighter(Theme.accent, 1.1) : Theme.accent

                        CenteredIcon {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: SpotifyService.playing ? 0 : 1.5
                            text: SpotifyService.playing ? "" : ""
                            size: 14
                            color: Theme.crust
                        }

                        HoverHandler { id: playHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: SpotifyService.toggle() }
                    }

                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: ""; size: 32
                        onActivated: SpotifyService.next()
                    }
                }

                IconButton {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    glyph: SpotifyService.repeat === "track" ? "" : ""
                    size: 32
                    active: SpotifyService.repeat !== "off"
                    onActivated: SpotifyService.cycleRepeat()
                }
            }

            // ── Search ──────────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: 38
                radius: height / 2
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                border.width: 1
                border.color: searchInput.activeFocus
                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6)
                            : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)

                CenteredIcon {
                    id: searchGlyph
                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    text: SpotifyService.searching ? "" : ""
                    size: 12
                    color: Theme.subtext0

                    RotationAnimation on rotation {
                        running: SpotifyService.searching
                        from: 0; to: 360
                        duration: 900
                        loops: Animation.Infinite
                        onStopped: searchGlyph.rotation = 0
                    }
                }

                TextInput {
                    id: searchInput
                    anchors {
                        left: searchGlyph.right; leftMargin: 10
                        right: clearBtn.left; rightMargin: 6
                        verticalCenter: parent.verticalCenter
                    }
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    selectByMouse: true
                    clip: true

                    Text {
                        visible: searchInput.text === ""
                        text: "Search songs, artists, albums, playlists"
                        color: Theme.overlay0
                        font: searchInput.font
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    onTextChanged: {
                        root.query = text
                        _debounce.restart()
                    }

                    // Enter plays the top result.
                    Keys.onReturnPressed: if (root.shown.length > 0) root.play(root.shown[0].uri)
                    Keys.onEnterPressed:  if (root.shown.length > 0) root.play(root.shown[0].uri)

                    // Escape clears the search first; with nothing to clear it
                    // falls through to the control center's Escape shortcut
                    // (back / close). Claiming the override is what lets the
                    // key reach this item ahead of that shortcut.
                    Keys.onShortcutOverride: function (e) {
                        e.accepted = e.key === Qt.Key_Escape && text !== ""
                    }
                    Keys.onEscapePressed: root.reset()
                }

                IconButton {
                    id: clearBtn
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    size: 26
                    glyph: ""
                    glyphSize: 10
                    glyphColor: Theme.subtext0
                    visible: searchInput.text !== ""
                    onActivated: { root.reset(); searchInput.forceActiveFocus() }
                }
            }

            // Filters, once there's something to filter.
            Flow {
                width: parent.width
                spacing: 6
                visible: SpotifyService.results.length > 0

                Repeater {
                    model: root.filters

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool on: root.filter === modelData.id

                        width: chipLabel.implicitWidth + 24
                        height: 28
                        radius: 14
                        color: on ? Theme.accent
                             : chipHover.hovered ? Theme.hover
                             : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)

                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            color: parent.on ? Theme.crust : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: parent.on
                        }

                        HoverHandler { id: chipHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: root.filter = modelData.id }
                    }
                }
            }

            // Results
            Column {
                width: parent.width
                spacing: 2
                visible: root.query.trim().length >= 2 || SpotifyService.results.length > 0

                Repeater {
                    model: root.shown

                    delegate: ResultRow {
                        required property var modelData
                        required property int index
                        width: parent.width
                        entry: modelData
                        first: index === 0
                    }
                }

                Text {
                    visible: !SpotifyService.searching && SpotifyService.searchError === ""
                             && root.shown.length === 0
                    width: parent.width
                    topPadding: 6
                    text: "No results"
                    color: Theme.subtext1
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                Text {
                    visible: SpotifyService.searchError !== ""
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: SpotifyService.searchError
                    color: Theme.urgent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            // ── Playlists ───────────────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 10
                visible: SpotifyService.playlists.length > 0

                Divider { width: parent.width }

                SectionLabel { text: "Playlists" }

                Grid {
                    id: grid
                    width: parent.width
                    columns: 3
                    columnSpacing: 12
                    rowSpacing: 12

                    readonly property real cell: (width - columnSpacing * (columns - 1)) / columns

                    Repeater {
                        model: SpotifyService.playlists

                        delegate: Item {
                            id: pl
                            required property var modelData

                            width: grid.cell
                            height: grid.cell + 26

                            Cover {
                                id: plCover
                                width: grid.cell
                                height: grid.cell
                                radius: 12
                                source: pl.modelData.art || ""
                                placeholder: ""
                                scale: plHover.hovered ? 1.03 : 1

                                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                            }

                            // Play badge on hover.
                            Rectangle {
                                anchors { right: plCover.right; bottom: plCover.bottom; margins: 8 }
                                width: 36
                                height: 36
                                radius: 18
                                color: Theme.accent
                                opacity: plHover.hovered ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                                CenteredIcon {
                                    anchors.centerIn: parent
                                    anchors.horizontalCenterOffset: 1
                                    text: ""
                                    size: 12
                                    color: Theme.crust
                                }
                            }

                            Text {
                                anchors { top: plCover.bottom; topMargin: 6; left: parent.left; right: parent.right }
                                text: pl.modelData.name
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                elide: Text.ElideRight
                            }

                            HoverHandler { id: plHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: SpotifyService.playUri(pl.modelData.uri) }
                        }
                    }
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

    component TimeText: Text {
        color: Theme.overlay1
        font.family: Theme.fontFamily
        font.pixelSize: 10
    }

    // One search result: cover, name, "Kind · by line". The first row is
    // marked as what Enter plays.
    component ResultRow: Rectangle {
        id: row

        property var  entry
        property bool first: false

        height: 52
        radius: 10
        color: rowHover.hovered ? Theme.hover
             : row.first ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.10)
             : "transparent"

        Cover {
            id: rowCover
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            width: 40
            height: 40
            radius: 6
            round: row.entry.kind === "artist"
            source: row.entry.art || ""
            placeholder: row.entry.kind === "artist" ? ""
                       : row.entry.kind === "playlist" ? "" : ""
        }

        Column {
            anchors { left: rowCover.right; leftMargin: 10; right: enterHint.left; rightMargin: 8
                      verticalCenter: parent.verticalCenter }
            spacing: 2

            Text {
                width: parent.width
                text: row.entry.name
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: row.entry.kind === "artist" ? "Artist"
                    : (root.kindLabel[row.entry.kind] || "") + " · " + row.entry.artist
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
            }
        }

        Text {
            id: enterHint
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            text: row.first ? "↵" : ""
            color: Theme.subtext0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.play(row.entry.uri) }
    }
}
