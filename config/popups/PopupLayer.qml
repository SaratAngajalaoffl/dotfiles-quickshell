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
// Every popup is anchored under the right notch and sized to its content.
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

    // ── Large panel variant ─────────────────────────────────────────────────
    // Same anchoring, but a PanelWindow so Hyprland can blur it (F3) and so
    // the panel gets its own exclusive-safe surface over fullscreen windows.
    component LargePopup: PanelWindow {
        id: panel

        property bool  open: false
        property int   popupWidth: Theme.popupWidth
        property int   contentHeight: 400
        default property alias content: slide.content

        // PanelWindow has no `anchor` (that is PopupWindow-only); it positions
        // itself with layer-shell anchors + margins instead.
        anchors {
            top: true
            right: true
        }
        margins {
            top: Theme.notchHeight
            right: Theme.borderWidth
        }

        implicitWidth: popupWidth
        implicitHeight: contentHeight

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        // Blur needs a layer surface, and only the focused monitor should draw.
        visible: root.active && slide.windowVisible

        PopupSlide {
            id: slide
            anchors.fill: parent
            edge: "top"
            open: panel.open
        }
    }

    // ── Theme picker ────────────────────────────────────────────────────────
    RightPopup {
        id: themePopup
        open: root.active && ShellState.themeOpen
        contentHeight: themeContent.implicitHeight

        ThemePopup { id: themeContent; width: parent.width }
    }

    // ── Spotify ─────────────────────────────────────────────────────────────
    RightPopup {
        id: spotifyPopup
        open: root.active && ShellState.spotifyOpen
        popupWidth: Theme.spotifyWidth
        contentHeight: spotifyContent.implicitHeight

        SpotifyPopup { id: spotifyContent; width: parent.width }
    }

    // ── Dashboard ───────────────────────────────────────────────────────────
    LargePopup {
        id: dashPopup
        open: ShellState.dashboardOpen
        popupWidth: Theme.dashboardWidth
        contentHeight: Theme.dashboardHeight

        Dashboard { id: dashContent; width: parent.width; height: parent.height }
    }

    // ── Wallpaper ───────────────────────────────────────────────────────────
    LargePopup {
        id: wallpaperPopup
        open: ShellState.wallpaperOpen
        popupWidth: Theme.wallpaperWidth
        contentHeight: wallpaperContent.implicitHeight

        WallpaperPopup { id: wallpaperContent; width: parent.width }
    }

    // ── Notifications ───────────────────────────────────────────────────────
    RightPopup {
        id: notifPopup
        open: root.active && ShellState.notificationsOpen
        popupWidth: Theme.notificationsWidth
        contentHeight: notifContent.implicitHeight

        NotificationsPopup { id: notifContent; width: parent.width }
    }

    // ── Toast ───────────────────────────────────────────────────────────────
    RightPopup {
        id: toastPopup
        open: root.active && ShellState.notificationToastOpen
        popupWidth: Theme.notificationsWidth - 40
        contentHeight: toastContent.implicitHeight

        NotificationToast {
            id: toastContent
            width: parent.width
            notification: NotificationService.latest
        }
    }

    // ── Audio ───────────────────────────────────────────────────────────────
    RightPopup {
        id: audioPopup
        open: root.active && ShellState.audioOpen
        contentHeight: audioContent.implicitHeight

        AudioPopup { id: audioContent; width: parent.width }
    }

    // ── Network ─────────────────────────────────────────────────────────────
    RightPopup {
        id: networkPopup
        open: root.active && ShellState.networkOpen
        popupWidth: Theme.networkPopupWidth
        contentHeight: netContent.implicitHeight

        NetworkPopup { id: netContent; width: parent.width }
    }

    // ── Bluetooth ───────────────────────────────────────────────────────────
    RightPopup {
        id: btPopup
        open: root.active && ShellState.bluetoothOpen
        contentHeight: btContent.implicitHeight

        BluetoothPopup { id: btContent; width: parent.width }
    }

    // ── Clipboard ───────────────────────────────────────────────────────────
    RightPopup {
        id: clipPopup
        open: root.active && ShellState.clipboardOpen
        contentHeight: clipContent.implicitHeight

        ClipboardPopup { id: clipContent; width: parent.width }
    }

    // ── Emoji ───────────────────────────────────────────────────────────────
    RightPopup {
        id: emojiPopup
        open: root.active && ShellState.emojiOpen
        popupWidth: Theme.emojiWidth
        contentHeight: emojiContent.implicitHeight

        EmojiPopup { id: emojiContent; width: parent.width }
    }

    // ── App launcher ────────────────────────────────────────────────────────
    RightPopup {
        id: launcherPopup
        open: root.active && ShellState.launcherOpen
        popupWidth: Theme.launcherWidth
        contentHeight: launcherContent.implicitHeight

        AppLauncherPopup { id: launcherContent; width: parent.width }
    }

    // ── User menu ───────────────────────────────────────────────────────────
    RightPopup {
        id: userPopup
        open: root.active && ShellState.userMenuOpen
        contentHeight: userContent.implicitHeight

        UserMenuPopup { id: userContent; width: parent.width }
    }
}
