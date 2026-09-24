// System tray icons. Left-click opens the item's menu, right-click activates.
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../theme"
import "../../services"
import "../../components"

Row {
    id: root

    spacing: 6

    visible: TrayService.hasItems

    Repeater {
        model: TrayService.items

        delegate: Item {
            id: slot
            required property var modelData

            width:  18
            height: 18
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: icon
                anchors.fill: parent
                source: slot.modelData.icon || ""
                sourceSize.width:  18
                sourceSize.height: 18
                smooth: true
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
            }

            // Fallback when the item ships no icon.
            Text {
                anchors.centerIn: parent
                visible: icon.status !== Image.Ready
                text: (slot.modelData.title || "?").charAt(0).toUpperCase()
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }

            QsMenuAnchor {
                id: menuAnchor
                menu: slot.modelData.menu
                anchor.item: slot
                anchor.rect.x: 0
                anchor.rect.y: slot.height
            }

            HoverHandler { cursorShape: Qt.PointingHandCursor }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    if (slot.modelData.hasMenu)
                        menuAnchor.open()
                    else
                        slot.modelData.activate()
                }
            }

            // Middle-click often maps to "secondary activate" in SNI.
            TapHandler {
                acceptedButtons: Qt.MiddleButton
                onTapped: slot.modelData.secondaryActivate()
            }
        }
    }
}
