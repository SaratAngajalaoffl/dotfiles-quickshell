// Clipboard history popup, backed by cliphist.
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
        function onClipboardOpenChanged() {
            if (ShellState.clipboardOpen)
                ClipboardService.refresh()
        }
    }

    PopupPanel {
        id: panel
        width: parent.width

        customHeader: Item {
            width: parent.width

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Clipboard"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }

            Item {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: clearBtn.width
                height: clearBtn.height

                Rectangle {
                    id: clearBtn
                    width: clearText.width + 18
                    height: 24
                    radius: height / 2
                    color: clearHover.hovered
                           ? Qt.rgba(Theme.urgent.r, Theme.urgent.g, Theme.urgent.b, 0.22)
                           : "transparent"
                    visible: ClipboardService.entries.length > 0

                    Text {
                        id: clearText
                        anchors.centerIn: parent
                        text: "Clear all"
                        color: clearHover.hovered ? Theme.urgent : Theme.subtext0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: ClipboardService.clearAll() }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 0

            // ── Empty state ─────────────────────────────────────────────────
            Item {
                width: parent.width
                height: 90
                visible: ClipboardService.entries.length === 0

                Text {
                    anchors.centerIn: parent
                    text: ClipboardService.available ? "Clipboard history is empty"
                                                     : "cliphist is not running"
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }

            // ── Entries ─────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: ClipboardService.entries.length === 0
                        ? 0
                        : Math.min(clipList.contentHeight, 420)
                visible: height > 0

                ListView {
                    id: clipList
                    anchors.fill: parent
                    clip: true
                    model: ClipboardService.entries
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        required property var modelData

                        width: clipList.width
                        height: 40

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: Theme.cornerRadiusSmall
                            color: clipHover.hovered ? Theme.hover : "transparent"

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }

                        Row {
                            anchors {
                                left: parent.left;  leftMargin: 10
                                right: parent.right; rightMargin: 6
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 8

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.isImage ? "\uf03e" : "\uf0ea"
                                color_: Theme.subtext0
                                font.pixelSize: Theme.fontSize
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 30 - deleteBtn.width - 16
                                text: modelData.preview
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                elide: Text.ElideRight
                            }

                            Item {
                                id: deleteBtn
                                width: deleteIcon.width + 12
                                height: 24

                                Text {
                                    id: deleteIcon
                                    anchors.centerIn: parent
                                    text: "\uf00d"
                                    color: deleteHover.hovered ? Theme.urgent : Theme.inactive
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                }

                                HoverHandler { id: deleteHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    onTapped: ClipboardService.deleteEntry(modelData.id)
                                }
                            }
                        }

                        HoverHandler { id: clipHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                ClipboardService.copyEntry(modelData.id)
                                ShellState.close("clipboard")
                            }
                        }
                    }
                }
            }
        }
    }
}
