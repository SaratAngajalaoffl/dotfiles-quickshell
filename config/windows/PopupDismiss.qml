// Dismisses every popup on Escape or on a click outside any popup.
//
// A full-screen transparent layer surface that only exists while something is
// open, so it never eats clicks during normal use.
import Quickshell
import QtQuick
import "../state"

PanelWindow {
    id: root

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // Only present when a popup is open.
    visible: ShellState.anyOpen()

    // Sits below popups but above normal windows for input purposes.
    focusable: true

    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.closeAll()
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: ShellState.closeAll()
    }
}
