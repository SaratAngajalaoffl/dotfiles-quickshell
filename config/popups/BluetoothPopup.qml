// Bluetooth popup: power toggle + paired/known device list.
import QtQuick
import "../theme"
import "../state"
import "../services"
import "../components"

Item {
    id: root

    // Shown as a control-center page rather than a standalone popup.
    property bool embedded: false

    implicitWidth: Theme.popupWidth
    implicitHeight: panel.implicitHeight

    PopupPanel {
        id: panel
        embedded: root.embedded
        width: parent.width

        customHeader: Item {
            width: parent.width

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Bluetooth"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }

            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 4

                SmallAction {
                    label: "Scan"
                    enabled: BluetoothService.powered
                    onActivated: BluetoothService.scan()
                }

                IconButton {
                    glyph: BluetoothService.powered ? "\uf293" : "\uf00d"
                    size: 28
                    active: !BluetoothService.powered
                    onActivated: BluetoothService.togglePower()
                }
            }
        }

        Column {
            width: parent.width
            spacing: 8

            Text {
                width: parent.width
                visible: !BluetoothService.available
                text: "No Bluetooth adapter found"
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            Text {
                width: parent.width
                visible: BluetoothService.available && !BluetoothService.powered
                text: "Bluetooth is off"
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            Column {
                width: parent.width
                spacing: 2
                visible: BluetoothService.powered

                Repeater {
                    model: BluetoothService.devices

                    delegate: ListRow {
                        required property var modelData
                        title: modelData.name || modelData.mac
                        subtitle: modelData.mac
                        selected: modelData.connected
                        trailing: modelData.connected ? "Connected"
                                : modelData.paired ? "Paired" : "Pair"
                        glyph: modelData.connected ? "\uf293" : "\uf294"
                        leadingActive: modelData.connected
                        onActivated: {
                            if (modelData.paired) BluetoothService.toggleDevice(modelData.mac)
                            else BluetoothService.pair(modelData.mac)
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: BluetoothService.powered && BluetoothService.devices.length === 0
                text: "No devices found"
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }
    }

    component SmallAction: Rectangle {
        id: act
        property string label
        property bool enabled: true
        signal activated()
        width: labelText.width + 18
        height: 24
        radius: height / 2
        color: actHover.hovered ? Theme.hover : "transparent"
        Text {
            id: labelText
            anchors.centerIn: parent
            text: act.label
            color: act.enabled ? Theme.subtext0 : Theme.inactive
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }
        HoverHandler { id: actHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: if (act.enabled) act.activated() }
    }
}
