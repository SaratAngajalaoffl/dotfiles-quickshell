// Clickable surface with a themed hover/press background.
// Used for every icon button in the bar and popups.
import QtQuick
import "../theme"

Rectangle {
    id: root

    property bool   hovered: hover.hovered
    property bool   active: false
    property color  activeColor: Theme.accent
    property int    radius_: height / 2
    property alias  cursorShape: tap.cursorShape

    signal clicked()

    radius: radius_
    color: hovered ? Theme.hover
         : active  ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.18)
         : "transparent"

    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tap
        onTapped: root.clicked()
    }
}
