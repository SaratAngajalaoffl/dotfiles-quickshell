// App launcher — replaces the rofi drun half.
import QtQuick
import "../theme"
import "../state"
import "../services"
import "../components"
import Quickshell

Item {
    id: root

    property string query: ""

    readonly property var results: {
        var _ = AppService.apps.length
        return AppService.search(root.query)
    }

    readonly property int fieldHeight: 34
    readonly property int listHeight: Theme.launcherMaxHeight - fieldHeight - Theme.popupPadding * 2 - 10

    implicitWidth: Theme.launcherWidth
    implicitHeight: Theme.launcherMaxHeight

    Connections {
        target: ShellState
        function onLauncherOpenChanged() {
            if (ShellState.launcherOpen && !AppService.loaded)
                AppService.load()
        }
    }

    PopupPanel {
        id: panel
        width: parent.width
        height: parent.height

        // ── Search field ────────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 34
            radius: Theme.cornerRadiusSmall
            color: Theme.hover

            TextInput {
                id: input
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 12
                }
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                selectionColor: Theme.accent
                selectedTextColor: Theme.crust
                clip: true
                focus: ShellState.launcherOpen
                onTextChanged: root.query = text
                onAccepted: {
                    var r = root.results
                    if (r.length > 0) AppService.launch(r[0])
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text === ""
                    text: "Search applications…"
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }

        // ── Results ─────────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: root.listHeight

            ListView {
                id: appList
                anchors.fill: parent
                clip: true
                model: root.results
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    required property var modelData

                    width: appList.width
                    height: 42
                    radius: Theme.cornerRadiusSmall
                    color: appHover.hovered
                           ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                           : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Row {
                        anchors {
                            left: parent.left;  leftMargin: 10
                            right: parent.right; rightMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 10

                        // .desktop Icon= is a freedesktop icon *name* (e.g.
                        // "firefox"), not a Nerd Font glyph, so it must go
                        // through the icon image provider.
                        Image {
                            id: appIcon
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            source: modelData.icon !== "" ? "image://icon/" + modelData.icon : ""
                            sourceSize.width: 20
                            sourceSize.height: 20
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: status === Image.Ready
                        }

                        // The icon provider renders a placeholder box for names
                        // it cannot resolve, so fall back to a generic glyph
                        // whenever the image did not actually load.
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: appIcon.status !== Image.Ready
                            text: "\uf2d0"
                            color_: Theme.accent
                            font.pixelSize: 16
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 30
                            spacing: 1

                            Text {
                                width: parent.width
                                text: modelData.name
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: modelData.comment
                                color: Theme.subtext0
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                elide: Text.ElideRight
                            }
                        }
                    }

                    HoverHandler { id: appHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: AppService.launch(modelData) }
                }
            }
        }

        Text {
            width: parent.width
            visible: root.results.length === 0
            text: AppService.loaded ? "No applications found" : "Loading applications…"
            color: Theme.subtext0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }
}
