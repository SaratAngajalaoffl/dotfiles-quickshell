// Audio popup: output/input volume + device pickers.
import QtQuick
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

    PopupPanel {
        id: panel
        embedded: root.embedded
        title: "Audio"
        width: parent.width

        Column {
            width: parent.width
            spacing: 10

            // ── Output ──────────────────────────────────────────────────────
            SectionLabel { text: "Output" }

            Row {
                width: parent.width
                spacing: 10

                IconButton {
                    glyph: AudioService.muted ? "\uf026" : AudioService.glyph
                    size: 30
                    glyphSize: Theme.fontSizeLarge
                    active: AudioService.muted
                    onActivated: AudioService.toggleMute()
                }

                Slider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 30 - 44 - 20
                    value: AudioService.volume
                    onMoved: function (v) { AudioService.setVolume(v) }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    horizontalAlignment: Text.AlignRight
                    text: AudioService.volumePercent + "%"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }

            // Output device picker
            Column {
                width: parent.width
                spacing: 2

                Repeater {
                    model: AudioService.sinks

                    delegate: ListRow {
                        required property var modelData
                        title: modelData.description || modelData.name || "Unknown"
                        glyph: "\uf028"
                        leadingActive: modelData === AudioService.sink
                        selected: modelData === AudioService.sink
                        onActivated: AudioService.setDefaultSink(modelData)
                    }
                }
            }

            Divider { width: parent.width }

            // ── Input ───────────────────────────────────────────────────────
            SectionLabel { text: "Input" }

            Row {
                width: parent.width
                spacing: 10

                IconButton {
                    glyph: AudioService.sourceMuted ? "\uf131" : "\uf130"
                    size: 30
                    glyphSize: Theme.fontSizeLarge
                    active: AudioService.sourceMuted
                    onActivated: AudioService.toggleSourceMute()
                }

                Slider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 30 - 44 - 20
                    value: AudioService.sourceVolume
                    onMoved: function (v) { AudioService.setSourceVolume(v) }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    horizontalAlignment: Text.AlignRight
                    text: AudioService.sourcePercent + "%"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }

    component SectionLabel: Text {
        color: Theme.subtext0
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.bold: true
    }
}
