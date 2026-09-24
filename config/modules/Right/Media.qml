// Media indicator: glyph + scrolling title. Replaces waybar's custom/playback.
import QtQuick
import "../../theme"
import "../../state"
import "../../services"
import "../../components"

Item {
    id: root

    visible: MediaService.active
    implicitWidth: visible ? content.implicitWidth + 16 : 0
    implicitHeight: 26

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.animFast }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: hover.hovered ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6

        Icon {
            text: MediaService.glyph
            color_: Theme.accent
            font.pixelSize: Theme.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }

        // Fixed width so the bar doesn't jitter as the title scrolls/changes.
        Item {
            width: 150
            height: 16
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: label
                text: MediaService.label
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize

                // Only scroll when the text actually overflows.
                readonly property bool overflow: implicitWidth > parent.width

                NumberAnimation on x {
                    running: label.overflow
                    loops: Animation.Infinite
                    from: label.overflow ? 0 : 0
                    to: label.overflow ? -(label.implicitWidth + 40) : 0
                    duration: Math.max(4000, label.implicitWidth * 22)
                    onRunningChanged: if (!running) label.x = 0
                }
            }
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: MediaService.toggle()
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: ShellState.toggle("spotify")
    }
}
