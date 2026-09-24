// Date + time. Click opens the calendar dashboard tab.
import QtQuick
import "../../theme"
import "../../state"

Row {
    id: root

    spacing: 10

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Text {
        text: Qt.formatDateTime(root.now, "ddd, dd MMM")
        color: Theme.subtext0
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: Qt.formatDateTime(root.now, "hh:mm:ss")
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeLarge
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: ShellState.open("dashboard", "calendar")
    }
}
