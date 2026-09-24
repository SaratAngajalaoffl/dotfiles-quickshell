// The island's home: a grid of every non-hidden Registry widget. Click, or arrow keys
// + Enter, to open one; Escape from that widget comes back here.
import QtQuick
import "../theme"
import "../state"
import "../components"
import "."

Item {
    id: root

    property bool active: false

    readonly property int columns: 4
    readonly property int cell: 92
    readonly property int pad: 14
    readonly property int rows: Math.ceil(Registry.pickable.length / columns)

    implicitWidth:  columns * cell + pad * 2
    implicitHeight: rows * cell + pad * 2

    onActiveChanged: if (active) { grid.currentIndex = 0; grid.forceActiveFocus() }

    GridView {
        id: grid
        anchors.fill: parent
        anchors.margins: root.pad
        cellWidth: root.cell
        cellHeight: root.cell
        interactive: false
        focus: root.active
        keyNavigationWraps: true
        model: Registry.pickable

        Keys.onReturnPressed: ShellState.openWidget(Registry.pickable[currentIndex].id, true)
        Keys.onEnterPressed:  ShellState.openWidget(Registry.pickable[currentIndex].id, true)

        delegate: Item {
            id: tile

            required property var modelData
            required property int index

            readonly property bool highlighted: tileHover.hovered
                                                || (grid.activeFocus && grid.currentIndex === index)

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: Theme.ccCardRadius
                color: tile.highlighted
                       ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                       : Theme.hover

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.icon
                        color_: tile.highlighted ? Theme.accent : Theme.text
                        font.pixelSize: 22
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.name
                        color: tile.modelData.source !== "" ? Theme.text : Theme.subtext0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }

            HoverHandler {
                id: tileHover
                cursorShape: Qt.PointingHandCursor
                onHoveredChanged: if (hovered) grid.currentIndex = tile.index
            }
            TapHandler { onTapped: ShellState.openWidget(tile.modelData.id, true) }
        }
    }
}
