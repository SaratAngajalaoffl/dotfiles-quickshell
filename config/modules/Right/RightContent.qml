// Right notch: the status pill the control center grows out of.
//
// Three readouts: the active link (ethernet or wifi), volume with its
// percentage, and notifications with an unread count, then the user's
// ~/.face avatar at the far right. Everything else lives in
// the control center, which opens when this corner is hovered. The control
// center draws a copy of this pill over the notch and fades it out as it
// morphs, so keep it free of per-instance state.
import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../theme"
import "../../state"
import "../../services"
import "../../components"

Item {
    id: root

    readonly property bool active: ShellState.controlCenterOpen

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
             : hover.hovered ? Theme.hover
             : "transparent"

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 14

        // ── Network: ethernet or wifi glyph, dimmed when offline ────────────
        Glyph {
            text: NetworkService.glyph
            color_: NetworkService.color
        }

        // ── Volume + percentage ─────────────────────────────────────────────
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Glyph {
                text: AudioService.glyph
                color_: AudioService.muted ? Theme.inactive : Theme.text
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: AudioService.volumePercent + "%"
                color: AudioService.muted ? Theme.inactive : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }

        // ── Notifications, with unread count badge ──────────────────────────
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: bell.implicitWidth + (badge.visible ? badge.width - 6 : 0)
            height: bell.implicitHeight

            Glyph {
                id: bell
                anchors.left: parent.left
                text: NotificationService.dnd ? "" : ""
                color_: NotificationService.dnd ? Theme.inactive : Theme.text
            }

            Rectangle {
                id: badge
                readonly property int unread: NotificationService.unreadCount

                visible: unread > 0
                anchors { left: bell.right; leftMargin: -6; top: parent.top; topMargin: -4 }
                width: Math.max(height, badgeText.implicitWidth + 8)
                height: 14
                radius: height / 2
                color: Theme.urgent

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: badge.unread > 99 ? "99+" : String(badge.unread)
                    color: Theme.crust
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                }
            }
        }

        // ── Avatar (~/.face), hidden if the file is missing ─────────────────
        ClippingRectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: face.status === Image.Ready
            width: 22
            height: 22
            radius: width / 2
            color: Theme.surface1
            border.width: 1
            border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)

            Image {
                id: face
                anchors.fill: parent
                source: "file://" + Quickshell.env("HOME") + "/.face"
                sourceSize.width: 44          // 2x for crispness
                sourceSize.height: 44
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                // Uncached, so a changed ~/.face shows up on the next reload.
                cache: false
            }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: ShellState.toggle("controlCenter")
    }

    // Scroll anywhere on the pill for volume.
    WheelHandler {
        onWheel: function (e) { AudioService.adjustVolume(e.angleDelta.y > 0 ? 0.05 : -0.05) }
    }

    component Glyph: Icon {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        font.pixelSize: Theme.fontSizeLarge
    }
}
