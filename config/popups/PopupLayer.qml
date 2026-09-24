// Instantiates every popup window. This is the ONLY file that creates them.
//
// Window-type rule (Chunk 0 finding F3): Hyprland blurs PanelWindow layer
// surfaces but NOT PopupWindow subsurfaces. So small anchored popups are
// PopupWindow with a near-opaque fill, and large panels are PanelWindow.
//
// Animation: a PopupWindow must stay `visible` while it slides out, so
// `visible` is bound to PopupSlide.windowVisible (which flips false only after
// the slide-out completes) rather than directly to the ShellState bool.
//
// Every popup is anchored under the right notch and sized to its content,
// except the control center, which grows out of the notch itself.
import QtQuick
import Quickshell
import "../theme"
import "../state"
import "../services"
import "../components"
import "../shapes"

Item {
    id: root

    // Bar window to anchor against, supplied by shell.qml.
    property var barWindow: null

    // This layer's monitor. Popups must only appear on the focused display;
    // without the guard each popup would render on every monitor at once.
    property var screen: null

    readonly property bool active: HyprlandService.isFocused(root.screen)

    readonly property int barRight: barWindow ? barWindow.width : 0

    // ── Generic right-anchored popup ────────────────────────────────────────
    // One window per popup; `source` is its content component.
    component RightPopup: PopupWindow {
        id: popup

        property bool  open: false
        property int   popupWidth: Theme.popupWidth
        property int   contentHeight: 300
        default property alias content: slide.content

        anchor.window: root.barWindow
        anchor.rect.x: root.barRight - implicitWidth - Theme.borderWidth
        anchor.rect.y: Theme.notchHeight

        implicitWidth: popupWidth
        implicitHeight: contentHeight

        color: "transparent"
        visible: slide.windowVisible

        PopupSlide {
            id: slide
            anchors.fill: parent
            edge: "top"
            open: popup.open
        }
    }

    // ── Spotify ─────────────────────────────────────────────────────────────
    RightPopup {
        id: spotifyPopup
        open: root.active && ShellState.spotifyOpen
        popupWidth: Theme.spotifyWidth
        contentHeight: spotifyContent.implicitHeight

        SpotifyPopup { id: spotifyContent; width: parent.width }
    }

    // ── Control center ──────────────────────────────────────────────────────
    // Hosts network, bluetooth, clipboard, emoji, audio and notifications as
    // pages; those names route here through ShellState._ccPages.
    ControlCenter {
        screen: root.screen
        barWindow: root.barWindow
        active: root.active
    }
}
