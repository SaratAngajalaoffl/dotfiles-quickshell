// A single bar indicator: optional glyph, optional text, hover + click.
// Every right-notch trigger is one of these.
import QtQuick
import "../../theme"
import "../../components"

Item {
    id: root

    property string glyph: ""
    property string label: ""
    property bool   active: false
    property color  glyphColor: Theme.text

    signal triggered()

    implicitWidth:  content.implicitWidth + 16
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
             : hover.hovered ? Theme.hover
             : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6

        Icon {
            visible: root.glyph !== ""
            text: root.glyph
            color_: root.active ? Theme.accent : root.glyphColor
            font.pixelSize: Theme.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.label !== ""
            text: root.label
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.triggered()
    }
}
