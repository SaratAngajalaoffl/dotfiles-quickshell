// The island on hover: now playing on the left, clock and date in the
// middle, RAM usage on the right.
//
// Controls here use MouseArea rather than TapHandler on purpose: a MouseArea
// that takes the press cancels the island's own TapHandler, so clicking
// play/pause doesn't also open the widget grid.
import QtQuick
import Quickshell.Widgets
import "../../theme"
import "../../services"
import "../../components"

Item {
    id: root

    property date now: new Date()

    readonly property int pad: 14

    implicitWidth: Theme.islandPeekWidth
    implicitHeight: Theme.islandPeekHeight

    // ── Now playing ─────────────────────────────────────────────────────────
    Row {
        id: media
        anchors { left: parent.left; leftMargin: root.pad; verticalCenter: parent.verticalCenter }
        width: (root.width - clock.width) / 2 - root.pad - 12
        spacing: 12

        // Album art; click toggles play/pause.
        ClippingRectangle {
            id: art
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 44
            radius: 10
            color: Theme.surface

            Image {
                id: artImage
                anchors.fill: parent
                source: MediaService.artUrl
                sourceSize.width: 88
                sourceSize.height: 88
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            Icon {
                anchors.centerIn: parent
                visible: !artImage.visible
                text: "\uf001"
                color_: Theme.subtext0
                font.pixelSize: 16
            }

            // Play/pause glyph over the art on hover.
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.45)
                opacity: artMouse.containsMouse && MediaService.canToggle ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                Icon {
                    anchors.centerIn: parent
                    text: MediaService.playing ? "\uf04c" : "\uf04b"
                    color_: "white"
                    font.pixelSize: 14
                }
            }

            MouseArea {
                id: artMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: MediaService.canToggle ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: MediaService.toggle()
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: media.width - art.width - media.spacing
            spacing: 3

            Row {
                width: parent.width
                spacing: 7

                EqBars {
                    id: eq
                    anchors.verticalCenter: parent.verticalCenter
                    visible: MediaService.playing
                    playing: visible
                    barHeight: 11
                }

                Text {
                    width: parent.width - (eq.visible ? eq.width + parent.spacing : 0)
                    text: MediaService.active ? MediaService.title : "Nothing playing"
                    color: MediaService.active ? Theme.text : Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: MediaService.active
                    elide: Text.ElideRight
                }
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: MediaService.artist
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
            }
        }
    }

    // ── Clock ───────────────────────────────────────────────────────────────
    Column {
        id: clock
        anchors.centerIn: parent
        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "HH:mm")
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 22
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "ddd, MMM d")
            color: Theme.subtext0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    // ── RAM ─────────────────────────────────────────────────────────────────
    Rectangle {
        anchors { right: parent.right; rightMargin: root.pad; verticalCenter: parent.verticalCenter }
        width: ram.implicitWidth + 24
        height: 34
        radius: height / 2
        color: Theme.hover

        Row {
            id: ram
            anchors.centerIn: parent
            spacing: 8

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf2db"
                color_: MemoryService.fraction > 0.85 ? Theme.urgent : Theme.accent
                font.pixelSize: 14
            }

            // Fill meter, turns urgent past 85%.
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 6
                radius: 3
                color: Theme.surface

                Rectangle {
                    width: parent.width * MemoryService.fraction
                    height: parent.height
                    radius: parent.radius
                    color: MemoryService.fraction > 0.85 ? Theme.urgent : Theme.accent
                    Behavior on width { NumberAnimation { duration: Theme.animDuration } }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: MemoryService.percent + "%"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
