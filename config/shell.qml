// Quickshell entrypoint.
//
// One bar + one frame + one dismiss layer per monitor. Popups are added in
// Chunk 4 via PopupLayer.qml; until then the bar's triggers toggle state that
// nothing renders yet, which is intentional — the wiring is testable first.
import Quickshell
import QtQuick
import "windows"
import "shapes"

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Scope {
                required property var modelData

                TopBar        { screen: modelData }
                FrameShape    { screen: modelData }
                PopupDismiss  { screen: modelData }
            }
        }
    }
}
