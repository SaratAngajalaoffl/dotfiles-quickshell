// The island at rest: the time, with EQ bars beside it while music plays.
import QtQuick
import "../../theme"
import "../../services"

Row {
    id: root

    property date now: new Date()

    spacing: 8

    EqBars {
        anchors.verticalCenter: parent.verticalCenter
        visible: MediaService.playing
        playing: visible
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.now, "HH:mm")
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeLarge
        font.bold: true
    }
}
