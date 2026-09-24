// Network popup: wifi toggle, current connection, and a scan list.
//
// network list is populated on demand — scanNetworks() kicks off nmcli and the
// model fills on the next poll, so the popup asks for a scan each time it opens.
import QtQuick
import "../theme"
import "../state"
import "../services"
import "../components"

Item {
    id: root

    implicitWidth: Theme.popupWidth
    implicitHeight: panel.implicitHeight

    Connections {
        target: ShellState
        function onNetworkOpenChanged() {
            if (ShellState.networkOpen)
                NetworkService.scanNetworks()
        }
    }

    PopupPanel {
        id: panel
        width: parent.width

        customHeader: Item {
            width: parent.width

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Network"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }

            IconButton {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                glyph: NetworkService.wifiEnabled ? "\uf1eb" : "\uf05e"
                size: 28
                active: !NetworkService.wifiEnabled
                onActivated: NetworkService.toggleWifi()
            }
        }

        Column {
            width: parent.width
            spacing: 8

            // ── Connected state ─────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: connCol.implicitHeight + 20
                radius: Theme.cornerRadiusSmall
                color: Theme.hover
                visible: NetworkService.connected

                Column {
                    id: connCol
                    anchors {
                        left: parent.left;  leftMargin: 12
                        right: parent.right; rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 2

                    Text {
                        width: parent.width
                        text: NetworkService.ssid
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: (NetworkService.ip !== "" ? NetworkService.ip + "  ·  " : "")
                              + NetworkService.kind
                              + "  ·  " + NetworkService.strength + "%"
                        color: Theme.subtext0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        elide: Text.ElideRight
                    }
                }

                Row {
                    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    spacing: 4

                    SmallAction {
                        label: "Disconnect"
                        onActivated: NetworkService.disconnect()
                    }
                }
            }

            // ── Scan list ───────────────────────────────────────────────────
            SectionLabel {
                text: !NetworkService.wifiEnabled ? "Wi-Fi is off"
                    : NetworkService.networks.length === 0 ? "Scanning…"
                    : "Available networks"
            }

            Column {
                width: parent.width
                spacing: 2

                Repeater {
                    model: NetworkService.wifiEnabled ? NetworkService.networks : []

                    delegate: ListRow {
                        required property var modelData
                        title: modelData.ssid || "Hidden"
                        subtitle: modelData.security || "Open"
                        selected: modelData.ssid === NetworkService.ssid
                        trailing: modelData.strength + "%"
                        glyph: modelData.strength > 75 ? "\uf1eb"
                             : modelData.strength > 40 ? "\uf1eb" : "\uf1eb"
                        onActivated: NetworkService.connect(modelData.ssid, "")
                    }
                }
            }

            Item {
                width: parent.width
                height: 60
                visible: NetworkService.wifiEnabled && NetworkService.networks.length === 0

                Text {
                    anchors.centerIn: parent
                    text: "Scanning for networks…"
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }

    component SmallAction: Rectangle {
        id: act
        property string label
        signal activated()
        width: labelText.width + 18
        height: 24
        radius: height / 2
        color: actHover.hovered ? Theme.hover : "transparent"
        Text {
            id: labelText
            anchors.centerIn: parent
            text: act.label
            color: Theme.subtext0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }
        HoverHandler { id: actHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: act.activated() }
    }

    component SectionLabel: Text {
        color: Theme.subtext0
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
    }
}
