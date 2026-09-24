// Theme picker — replaces the rofi-based theme-menu.sh.
import QtQuick
import "../theme"
import "../state"
import "../services"
import "../components"

Item {
    id: root

    implicitWidth: Theme.popupWidth
    implicitHeight: panel.implicitHeight

    property string query: ""

    readonly property var results: {
        var q = root.query.toLowerCase()
        if (q === "")
            return ThemeService.themes
        var out = []
        for (var i = 0; i < ThemeService.themes.length; i++) {
            var t = ThemeService.themes[i]
            if (t.label.toLowerCase().indexOf(q) !== -1
                || t.name.toLowerCase().indexOf(q) !== -1)
                out.push(t)
        }
        return out
    }

    Connections {
        target: ShellState
        function onThemeOpenChanged() {
            if (ShellState.themeOpen)
                ThemeService.refresh()
        }
    }

    PopupPanel {
        id: panel
        width: parent.width

        customHeader: Item {
            width: parent.width

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Theme"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }

            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: ThemeService.themes.length + " themes"
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        Column {
            width: parent.width
            spacing: 8

            Rectangle {
                width: parent.width
                height: 32
                radius: Theme.cornerRadiusSmall
                color: Theme.surface
                border.width: 1
                border.color: searchInput.activeFocus
                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)
                            : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)

                Icon {
                    id: searchGlyph
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    text: "\uf002"
                    color_: Theme.subtext0
                    font.pixelSize: Theme.fontSizeSmall
                }

                TextInput {
                    id: searchInput
                    anchors {
                        left: searchGlyph.right; leftMargin: 8
                        right: parent.right; rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    selectByMouse: true
                    clip: true
                    focus: ShellState.themeOpen

                    Text {
                        visible: searchInput.text === ""
                        text: "Search themes…"
                        color: Theme.overlay0
                        font: searchInput.font
                    }

                    onTextChanged: root.query = text

                    Keys.onEscapePressed: {
                        text = ""
                        root.query = ""
                    }
                }
            }

            // Scrollable list: 23 themes is taller than the panel should be.
            Item {
                width: parent.width
                height: Math.min(listContent.implicitHeight, 380)

                Flickable {
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: listContent.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: listContent
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: root.results

                            delegate: ListRow {
                                required property var modelData

                                title: modelData.label
                                subtitle: modelData.mode === "light" ? "light" : "dark"
                                glyph: modelData.name === ThemeService.current
                                     ? "\uf111" : "\uf10c"
                                leadingActive: modelData.name === ThemeService.current
                                selected: modelData.name === ThemeService.current
                                onActivated: {
                                    ThemeService.apply(modelData.name)
                                    ShellState.close("theme")
                                }
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: "Current: " + (ThemeService.current || "—")
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }
}
