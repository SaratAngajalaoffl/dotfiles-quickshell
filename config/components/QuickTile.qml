// Pill-shaped quick tile: round glyph + title/subtitle, as in the control
// center. The glyph toggles the thing (`toggled`), the rest of the tile opens
// its detail (`opened`); a tile that isn't toggleable opens from both.
import QtQuick
import "../theme"

Rectangle {
    id: tile

    property string glyph
    property string title
    property string subtitle
    property bool   active: false
    property bool   toggleable: true

    signal toggled()
    signal opened()

    height: 60
    radius: height / 2
    color: tileHover.hovered ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                             : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.045)
    border.width: 1
    border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    HoverHandler { id: tileHover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: tile.opened() }

    Rectangle {
        id: bubble
        anchors { left: parent.left; leftMargin: 9; verticalCenter: parent.verticalCenter }
        width: 42
        height: 42
        radius: 21
        color: tile.active || !tile.toggleable ? Theme.accent : Theme.surface1

        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        CenteredIcon {
            anchors.centerIn: parent
            text: tile.glyph
            color: tile.active || !tile.toggleable ? Theme.crust : Theme.text
            size: 18
        }

        // The bubble is the deeper item, so its handler takes the tap first.
        TapHandler { onTapped: tile.toggleable ? tile.toggled() : tile.opened() }
    }

    Column {
        anchors {
            left: bubble.right
            leftMargin: 10
            right: parent.right
            rightMargin: 14
            verticalCenter: parent.verticalCenter
        }
        spacing: 2

        Text {
            width: parent.width
            text: tile.title
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
            font.bold: true
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: tile.subtitle
            color: Theme.subtext0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideRight
        }
    }
}
