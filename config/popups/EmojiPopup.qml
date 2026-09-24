// Emoji picker — replaces rofi-emoji. Search box + category rail + grid.
import QtQuick
import "../theme"
import "../state"
import "../services"
import "../components"
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property int cellSize: 34
    readonly property int columns: Math.max(1,
        Math.floor((Theme.emojiWidth - Theme.popupPadding * 2) / cellSize))

    property string query: ""
    property string group: ""      // "" = all groups

    implicitWidth: Theme.emojiWidth
    implicitHeight: panel.implicitHeight

    // `search()` is a function, not a property — re-run it whenever the query,
    // group or the loaded database changes.
    readonly property var results: {
        var _ = EmojiService.all.length
        return EmojiService.search(root.query, root.group)
    }

    property Process _copy: Process {}

    function pickEmoji(glyph) {
        _copy.command = ["wl-copy", glyph]
        _copy.running = true
        ShellState.close("emoji")
    }

    PopupPanel {
        id: panel
        width: parent.width

        customHeader: Item {
            width: parent.width

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Emoji"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }

            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: root.results.length + " results"
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        Column {
            width: parent.width
            spacing: 8

            // ── Search ──────────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: 32
                radius: Theme.cornerRadiusSmall
                color: Theme.hover

                TextInput {
                    id: input
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.crust
                    clip: true
                    focus: ShellState.emojiOpen
                    onTextChanged: root.query = text

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === ""
                        text: "Search emoji…"
                        color: Theme.subtext0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }
            }

            // ── Category rail ───────────────────────────────────────────────
            Flow {
                width: parent.width
                spacing: 4

                CategoryChip { label: "All"; group: "" }

                Repeater {
                    model: EmojiService.groups
                    delegate: CategoryChip {
                        required property var modelData
                        label: modelData
                        group: modelData
                    }
                }
            }

            // ── Grid ────────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: Math.min(grid.contentHeight, 300)

                GridView {
                    id: grid
                    anchors.fill: parent
                    clip: true
                    cellWidth: root.cellSize
                    cellHeight: root.cellSize
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.results

                    delegate: Item {
                        required property var modelData
                        width: root.cellSize
                        height: root.cellSize

                        Rectangle {
                            anchors.centerIn: parent
                            width: root.cellSize - 4
                            height: root.cellSize - 4
                            radius: Theme.cornerRadiusSmall
                            color: emojiHover.hovered ? Theme.hover : "transparent"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.glyph
                            font.family: "Noto Color Emoji"
                            font.pixelSize: 20
                        }

                        HoverHandler { id: emojiHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: root.pickEmoji(modelData.glyph) }
                    }
                }
            }

            Text {
                width: parent.width
                visible: root.results.length === 0
                text: EmojiService.loaded ? "No matches" : "Loading emoji…"
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }
    }

    // ── Category chip ───────────────────────────────────────────────────────
    component CategoryChip: Rectangle {
        id: chip
        property string label
        property string group

        readonly property bool on: root.group === chip.group

        width:  Math.min(chipText.implicitWidth + 18, 150)
        height: 24
        radius: height / 2
        color: chip.on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
             : chipHover.hovered ? Theme.hover
             : "transparent"

        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Text {
            id: chipText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, 140)
            text: chip.label
            color: chip.on ? Theme.accent : Theme.subtext0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        HoverHandler { id: chipHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.group = chip.group }
    }
}
