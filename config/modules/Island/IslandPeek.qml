// The island on hover: now playing on the left, clock and date in the
// middle, prev / play-pause / next on the right.
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

    // ── Media controls ──────────────────────────────────────────────────────
    Rectangle {
        anchors { right: parent.right; rightMargin: root.pad; verticalCenter: parent.verticalCenter }
        width: controls.implicitWidth + 8
        height: 34
        radius: height / 2
        color: Theme.hover
        opacity: MediaService.active ? 1 : 0.5

        Row {
            id: controls
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: [
                    { glyph: "\uf048", enabled: MediaService.canPrev,   action: "previous" },
                    { glyph: MediaService.playing ? "\uf04c" : "\uf04b",
                                        enabled: MediaService.canToggle, action: "toggle" },
                    { glyph: "\uf051", enabled: MediaService.canNext,   action: "next" }
                ]

                delegate: Rectangle {
                    id: button
                    required property var modelData
                    width: 30
                    height: 30
                    radius: height / 2
                    color: buttonMouse.containsMouse && modelData.enabled
                           ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                           : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Icon {
                        anchors.centerIn: parent
                        text: button.modelData.glyph
                        color_: !button.modelData.enabled ? Theme.subtext0
                              : buttonMouse.containsMouse ? Theme.accent : Theme.text
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: buttonMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: button.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (button.modelData.enabled) MediaService[button.modelData.action]()
                    }
                }
            }
        }
    }
}
