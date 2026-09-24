// Wallpaper manager (goal #3). Grid of images from ~/Pictures/Wallpapers and
// the active theme's backgrounds/, plus awww transition controls.
//
// Rendered inside a PanelWindow (see PopupLayer's LargePopup): this is a big
// panel, so it can take the translucent fill and be blurred, unlike the small
// PopupWindow popups (finding F3).
import QtQuick
import "../theme"
import "../state"
import "../services"
import "../components"
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    implicitWidth: Theme.wallpaperWidth
    implicitHeight: panel.implicitHeight

    readonly property int cellSize: 96
    readonly property int columns: Math.max(1,
        Math.floor((Theme.wallpaperWidth - Theme.popupPadding * 2) / (cellSize + 8)))

    readonly property var outputs: Hyprland.monitors.values

    // ── Grid cell ───────────────────────────────────────────────────────────
    component Thumb: Rectangle {
        id: cell

        required property var modelData

        readonly property bool isCurrent: WallpaperService.current === modelData.path

        width: root.cellSize
        height: root.cellSize
        radius: Theme.cornerRadiusSmall
        color: Theme.surface
        border.width: isCurrent ? 2 : 1
        border.color: isCurrent ? Theme.accent
                    : hover.hovered ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)
                    : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
        clip: true

        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

        Image {
            anchors.fill: parent
            anchors.margins: 2
            source: "file://" + cell.modelData.path
            sourceSize.width: root.cellSize * 2
            sourceSize.height: root.cellSize * 2
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            // Animated sources get a badge rather than a frozen first frame.
            cache: !/\.gif$/i.test(cell.modelData.path)
        }

        Rectangle {
            visible: /\.gif$/i.test(cell.modelData.path)
            anchors { right: parent.right; top: parent.top; margins: 4 }
            width: 30; height: 16; radius: 8
            color: Qt.rgba(0, 0, 0, 0.6)
            Text {
                anchors.centerIn: parent
                text: "GIF"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 8
                font.bold: true
            }
        }

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

        TapHandler {
            onTapped: WallpaperService.apply(cell.modelData.path)
        }

        // Name overlay on hover: a PopupWindow cannot host a Quickshell
        // tooltip (that would be a second surface), so it stays in-cell.
        Rectangle {
            visible: hover.hovered
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 20
            color: Qt.rgba(0, 0, 0, 0.72)

            Text {
                anchors {
                    left: parent.left; right: parent.right
                    leftMargin: 4; rightMargin: 4
                    verticalCenter: parent.verticalCenter
                }
                text: cell.modelData.name
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 9
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    PopupPanel {
        id: panel
        width: parent.width
        background: Theme.popupBg

        customHeader: Item {
            width: parent.width

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Wallpaper"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
            }

            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 4

                IconButton {
                    glyph: "\uf021"
                    size: 26
                    onActivated: WallpaperService.refresh()
                }
            }
        }

        Column {
            width: parent.width
            spacing: 10

            // ── Transition controls ─────────────────────────────────────────
            Row {
                width: parent.width
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Transition"
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                }

                Repeater {
                    model: ["grow", "fade", "wipe", "outer", "random"]

                    delegate: Rectangle {
                        required property var modelData

                        anchors.verticalCenter: parent.verticalCenter
                        width: label.implicitWidth + 16
                        height: 24
                        radius: Theme.cornerRadiusSmall
                        color: WallpaperService.transition === modelData
                             ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.20)
                             : hover2.hovered ? Theme.hover : Theme.surface

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: modelData
                            color: WallpaperService.transition === modelData
                                 ? Theme.accent : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        HoverHandler { id: hover2; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                WallpaperService.transition = modelData
                                WallpaperService.save()
                            }
                        }
                    }
                }
            }

            // ── Duration ────────────────────────────────────────────────────
            Row {
                width: parent.width
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Duration"
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    width: 62
                }

                Slider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 62 - 52 - 20
                    value: WallpaperService.transitionDuration / 3000
                    onMoved: function (v) {
                        WallpaperService.transitionDuration = Math.round(v * 3000)
                        WallpaperService.save()
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 52
                    horizontalAlignment: Text.AlignRight
                    text: WallpaperService.transitionDuration + " ms"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            // ── Apply target (one monitor, or all) ──────────────────────────
            Row {
                width: parent.width
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Apply to"
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    width: 62
                }

                Repeater {
                    model: [{ name: "all", label: "All" }].concat(
                        root.outputs.map(function (m) { return { name: m.name, label: m.name } }))

                    delegate: Rectangle {
                        required property var modelData

                        anchors.verticalCenter: parent.verticalCenter
                        width: label2.implicitWidth + 16
                        height: 24
                        radius: Theme.cornerRadiusSmall
                        color: WallpaperService.applyTarget === modelData.name
                             ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.20)
                             : hover3.hovered ? Theme.hover : Theme.surface

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            id: label2
                            anchors.centerIn: parent
                            text: modelData.label
                            color: WallpaperService.applyTarget === modelData.name
                                 ? Theme.accent : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        HoverHandler { id: hover3; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                WallpaperService.applyTarget = modelData.name
                                WallpaperService.save()
                            }
                        }
                    }
                }
            }

            Divider { width: parent.width }

            // ── Grid ────────────────────────────────────────────────────────
            Text {
                visible: WallpaperService.images.length === 0
                text: "No wallpapers found.\nAdd images to ~/Pictures/Wallpapers"
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Grid {
                width: parent.width
                columns: root.columns
                spacing: 8

                Repeater {
                    model: WallpaperService.images
                    delegate: Thumb {}
                }
            }

            Text {
                width: parent.width
                text: WallpaperService.images.length + " image(s)"
                    + (WallpaperService.current !== ""
                       ? "  ·  current: " + WallpaperService.current.substring(
                             WallpaperService.current.lastIndexOf("/") + 1)
                       : "")
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideMiddle
            }
        }
    }
}
