// Clipboard history popup, backed by cliphist.
import QtQuick
import Quickshell.Widgets
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

    Connections {
        target: ShellState
        function onClipboardOpenChanged() {
            if (ShellState.clipboardOpen) {
                ClipboardService.refresh()
                clipList.currentIndex = 0
                clipList.positionViewAtBeginning()
            }
        }
    }

    function copyAt(index) {
        var e = ClipboardService.entries[index]
        if (!e) return
        ClipboardService.copyEntry(e.id)
        ShellState.close("clipboard")
    }

    PopupPanel {
        id: panel
        embedded: root.embedded
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

            // ── Entries: full-width cards, click one to copy it ─────────────
            Item {
                width: parent.width
                height: ClipboardService.entries.length === 0
                        ? 0
                        : Math.min(clipList.contentHeight, 440)
                visible: height > 0

                ListView {
                    id: clipList
                    anchors.fill: parent
                    clip: true
                    model: ClipboardService.entries
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds

                    // ── Keyboard: vim-style ─────────────────────────────────
                    //   j / Down      next        k / Up   previous
                    //   Return / l    copy        h        back to main page
                    focus: ShellState.clipboardOpen
                    currentIndex: 0
                    highlightFollowsCurrentItem: false

                    function move(delta) {
                        if (count === 0) return
                        currentIndex = Math.max(0, Math.min(count - 1, currentIndex + delta))
                        positionViewAtIndex(currentIndex, ListView.Contain)
                    }

                    Keys.onPressed: function (event) {
                        switch (event.key) {
                        case Qt.Key_J: case Qt.Key_Down:  move(1);  break
                        case Qt.Key_K: case Qt.Key_Up:    move(-1); break
                        case Qt.Key_L: case Qt.Key_Return: case Qt.Key_Enter:
                            root.copyAt(currentIndex); break
                        case Qt.Key_H: ShellState.back(); break
                        default: return
                        }
                        event.accepted = true
                    }

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        required property int index

                        // Keyboard selection and hover are one highlight:
                        // hovering a card moves the selection to it.
                        readonly property bool selected: ListView.isCurrentItem

                        readonly property bool hasThumb: modelData.thumb !== ""
                        readonly property bool thumbReady: thumbImage.status === Image.Ready

                        // Images take their aspect ratio at full width, clamped
                        // so a tall screenshot doesn't fill the whole list and
                        // a thin strip is still easy to hit.
                        readonly property real imageHeight: {
                            if (modelData.imgW <= 0 || modelData.imgH <= 0) return 120
                            var h = width * modelData.imgH / modelData.imgW
                            return Math.max(64, Math.min(180, h))
                        }

                        width: clipList.width
                        height: hasThumb ? imageHeight : textBody.implicitHeight + 24
                        radius: Theme.cornerRadiusSmall + 2
                        color: card.selected ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.09)
                                             : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.045)
                        border.width: card.selected ? 2 : 1
                        border.color: card.selected
                                      ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)
                                      : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                        // ── Image ───────────────────────────────────────────
                        ClippingRectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            visible: card.hasThumb
                            radius: card.radius - 1
                            color: "transparent"

                            Image {
                                id: thumbImage
                                anchors.fill: parent
                                anchors.margins: 6
                                // The query changes when a decode pass finishes,
                                // so a file that was still missing gets retried;
                                // it is ignored for local files.
                                source: card.hasThumb && ClipboardService.thumbsReady
                                        ? "file://" + card.modelData.thumb + "?r=" + ClipboardService.thumbsRevision
                                        : ""
                                sourceSize.width: 800
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                cache: false
                                smooth: true
                                mipmap: true
                            }

                            // Placeholder while decoding (or if it failed).
                            Icon {
                                anchors.centerIn: parent
                                visible: !card.thumbReady
                                text: "\uf03e"
                                color_: Theme.inactive
                                font.pixelSize: 22
                            }

                            // Size / format caption, on hover.
                            Rectangle {
                                anchors { left: parent.left; bottom: parent.bottom; margins: 8 }
                                visible: card.selected
                                width: caption.implicitWidth + 12
                                height: 20
                                radius: height / 2
                                color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.85)

                                Text {
                                    id: caption
                                    anchors.centerIn: parent
                                    text: card.modelData.preview
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                }
                            }
                        }

                        // ── Text ────────────────────────────────────────────
                        Text {
                            id: textBody
                            visible: !card.hasThumb
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 14; rightMargin: 14
                            }
                            text: card.modelData.preview
                            color: card.modelData.isImage ? Theme.subtext0 : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            wrapMode: Text.WrapAnywhere
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            lineHeight: 1.15
                        }

                        HoverHandler {
                            id: cardHover
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: if (hovered) clipList.currentIndex = card.index
                        }

                        TapHandler { onTapped: root.copyAt(card.index) }

                        // ── Delete, top-right corner, on hover ──────────────
                        // A child of the card, so its tap is delivered before
                        // the card's own "copy" tap.
                        Rectangle {
                            anchors { top: parent.top; right: parent.right; margins: 6 }
                            visible: cardHover.hovered
                            width: 22
                            height: 22
                            radius: 11
                            color: deleteHover.hovered
                                   ? Qt.rgba(Theme.urgent.r, Theme.urgent.g, Theme.urgent.b, 0.9)
                                   : Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.85)

                            CenteredIcon {
                                anchors.centerIn: parent
                                text: "\uf00d"
                                color: deleteHover.hovered ? Theme.crust : Theme.subtext0
                                size: 9
                            }

                            HoverHandler { id: deleteHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: ClipboardService.deleteEntry(card.modelData.id) }
                        }
                    }
                }
            }
        }
    }
}
