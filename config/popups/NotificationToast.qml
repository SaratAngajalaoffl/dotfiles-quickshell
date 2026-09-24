// Transient toast for a newly arrived notification.
//
// Slides in from under the right notch and auto-hides after a while — but the
// notification itself is NOT dismissed; it stays in the panel until you act on
// it. The toast is purely a "something arrived" cue.
import QtQuick
import Quickshell
import "../theme"
import "../state"
import "../services"
import "../components"

Item {
    id: root

    property var notification: null

    implicitWidth: Theme.notificationsWidth - 40
    implicitHeight: toast.implicitHeight

    // Re-slide on each new notification.
    onNotificationChanged: if (notification) showTimer.restart()

    Timer {
        id: showTimer
        interval: 5000
        onTriggered: ShellState.notificationToastOpen = false
    }

    PopupPanel {
        id: toast
        width: parent.width
        // Tighter than the general popup padding — toasts are glanceable.
        padding: 12

        Row {
            width: parent.width
            spacing: 10

            Item {
                width: 30
                height: 30

                Image {
                    id: iconImg
                    anchors.fill: parent
                    source: {
                        var ic = root.notification ? (root.notification.appIcon || "") : ""
                        if (ic === "") return ""
                        if (ic.startsWith("/")) return "file://" + ic
                        return "image://icon/" + ic
                    }
                    sourceSize.width: 30
                    sourceSize.height: 30
                    fillMode: Image.PreserveAspectFit
                    visible: status === Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.hover
                    visible: iconImg.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: root.notification
                              ? (root.notification.appName || "?").charAt(0).toUpperCase() : "?"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                    }
                }
            }

            Column {
                width: parent.width - 30 - 10
                spacing: 2

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: root.notification ? (root.notification.appName || "") : ""
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.notification ? (root.notification.summary || "") : ""
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: root.notification ? (root.notification.body || "") : ""
                    color: Theme.subtext1
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                }
            }
        }
    }

    TapHandler {
        onTapped: {
            ShellState.open("notifications")
            ShellState.notificationToastOpen = false
        }
    }
}
